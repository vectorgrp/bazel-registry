import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.util.Map;
import java.util.function.Consumer;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;

/**
 * Patches DaVinci project settings files by deep-merging JSON content.
 *
 * <p>
 * The dvjson file maps setting keys to their respective JSON files, e.g.:
 *
 * <pre>{@code
 * {
 *   "general": "Settings/General.json",
 *   "ifp": "Settings/Ifp.json"
 * }
 * }</pre>
 *
 * <p>
 * The patch file contains override objects for those keys, e.g.:
 *
 * <pre>{@code
 * {
 *   "general": {"key": "value"},
 *   "ifp": {"other": true}
 * }
 * }</pre>
 *
 * <p>
 * For each key in the patch file:
 * <ul>
 * <li>If the key exists in the dvjson, the referenced settings file is deep-merged with the patch content.</li>
 * <li>If the key does not exist, it is registered in the dvjson and a new settings file is created.</li>
 * </ul>
 *
 * <p>
 * Deep merge rules:
 * <ul>
 * <li>Objects are merged recursively.</li>
 * <li>Arrays with a known identity key (see {@link #ARRAY_IDENTITY_KEYS}) are merged by matching elements on that key and replacing them.</li>
 * <li>Other arrays are merged as a duplicate-free union (deep equality check).</li>
 * <li>Primitives and null are replaced by the override value.</li>
 * <li>A {@code null} value in the patch removes the corresponding key from the base object.</li>
 * <li>For identity-key arrays, an element with {@code "__delete__": true} removes the matching base element.</li>
 * </ul>
 *
 * <p>
 * Usage: {@code java -cp <gson.jar> SettingsPatch.java <dvjson> <patch>}
 */
public final class SettingsPatcher {

    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    /** Marker property name used in array elements to signal deletion of a matched element. */
    private static final String DELETE_MARKER = "__delete__";

    /**
     * Maps JSON array field names to the property name used to identify and match individual elements during merging.
     *
     * <p>
     * When an array field appears in both the base and the patch, and its name is listed here, elements are matched by the specified identity key instead of being appended
     * blindly. A matching base element is replaced in-place; unmatched override elements are appended.
     */
    private static final Map<String, String> ARRAY_IDENTITY_KEYS = Map.of(
            "moduleDefinitionMappings", "moduleConfigName",
            "comControllerMappings", "clusterPath",
            "useCases", "vector");

    private SettingsPatcher() {
        // utility class
    }

    /**
     * Entry point. Parses command-line arguments and applies the patch.
     *
     * @param args {@code -d <dvjson_path> -p <patch_file_path>}
     */
    public static void main(String[] args) throws IOException {
        if (args.length != 2 || !args[0].endsWith(".dvjson") || !args[1].endsWith(".json")) {
            System.err.println("Usage: java SettingsPatch.java <dvjson> <patch>");
            System.exit(1);
        }

        final var dvjson = Path.of(args[0]);
        final var dvjsonDir = dvjson.toAbsolutePath().getParent();
        final var dvjsonContent = readJson(dvjson);
        var saveDvjson = false;

        for (var entry : readJson(Path.of(args[1])).entrySet()) {
            var pathEntry = dvjsonContent.get(entry.getKey());
            if (pathEntry == null || pathEntry.isJsonNull()) {
                saveDvjson = true;
                pathEntry = new JsonPrimitive("Settings/" + capitalize(entry.getKey()) + ".json");
                dvjsonContent.add(entry.getKey(), pathEntry);
            }
            patchSettingsFile(dvjsonDir.resolve(pathEntry.getAsString().replace("\\", "/")), entry.getValue().getAsJsonObject());
        }

        if (saveDvjson) {
            writeJson(dvjson, dvjsonContent);
        }
    }

    /**
     * Patches a single settings file. If the file exists, its content is deep-merged with the patch value. If it doesn't exist, it is created with the patch content.
     *
     * @param settingsFile path to the settings file
     * @param patchValue   the JSON object to merge into the settings
     */
    private static void patchSettingsFile(Path settingsFile, JsonObject patchValue) throws IOException {
        JsonObject merged;
        try {
            merged = readJson(settingsFile);
            deepMerge(merged, patchValue);
        } catch (NoSuchFileException ignored) {
            merged = patchValue;
        }
        writeJson(settingsFile, merged);
    }

    /**
     * Recursively deep-merges two JSON objects. The override values take precedence:
     * <ul>
     * <li>If the override value is {@code null}, the key is removed from the base.</li>
     * <li>If both values are objects, they are merged recursively.</li>
     * <li>If both values are arrays with a known identity key, elements are matched by that key and replaced; unmatched override elements are appended.</li>
     * <li>If both values are arrays without a known identity key, they are merged as a duplicate-free union (deep equality check).</li>
     * <li>All other types (primitives) are replaced by the override value.</li>
     * </ul>
     *
     * @param base     the base JSON object
     * @param override the override JSON object
     */
    private static void deepMerge(JsonObject base, JsonObject override) {
        for (var entry : override.entrySet()) {
            // Explicit JSON null in the patch means "delete this key".
            if (entry.getValue().isJsonNull()) {
                base.remove(entry.getKey());
            } else {
                switch (entry.getValue()) {
                    case JsonObject o when base.get(entry.getKey()) instanceof JsonObject b -> deepMerge(b, o);
                    case JsonArray o when base.get(entry.getKey()) instanceof JsonArray b -> {
                        final var identityKey = ARRAY_IDENTITY_KEYS.get(entry.getKey());
                        if (identityKey != null) {
                            mergeArraysByKey(b, o, identityKey);
                        } else {
                            mergeArrays(b, o);
                        }
                    }
                    default -> base.add(entry.getKey(), entry.getValue());
                }
            }
        }
    }

    /**
     * Merges two JSON arrays by matching elements on an identity key. If a base element has the same identity key value as an override element, it is replaced. If the override
     * element carries a {@code "__delete__": true} marker, the matched base element is removed instead. Unmatched override elements (without delete marker) are appended.
     *
     * @param base        the base array
     * @param override    the override array
     * @param identityKey the JSON field name used to match elements
     */
    private static void mergeArraysByKey(JsonArray base, JsonArray override, String identityKey) {
        for (var overrideItem : override) {
            if (!(overrideItem instanceof JsonObject overrideObj) || !overrideObj.has(identityKey)) {
                base.add(overrideItem);
                continue;
            }
            final var overrideId = overrideObj.get(identityKey);
            if (overrideId == null || overrideId.isJsonNull()) {
                base.add(overrideItem);
                continue;
            }

            final boolean isDelete = overrideObj.has(DELETE_MARKER)
                    && overrideObj.get(DELETE_MARKER).isJsonPrimitive()
                    && overrideObj.get(DELETE_MARKER).getAsBoolean();

            int matchIndex = -1;
            for (int i = 0; i < base.size(); i++) {
                if (base.get(i) instanceof JsonObject b && overrideId.equals(b.get(identityKey))) {
                    matchIndex = i;
                    break;
                }
            }

            if (matchIndex >= 0) {
                if (isDelete) {
                    base.remove(matchIndex);
                } else {
                    base.set(matchIndex, overrideItem);
                }
            } else if (!isDelete) {
                base.add(overrideItem);
            }
        }
    }

    /**
     * Merges two JSON arrays as a duplicate-free union. Each element from the override array is deep-copied and appended to the result if no deeply-equal element already exists.
     *
     * @param base     the base array
     * @param override the override array
     */
    private static void mergeArrays(JsonArray base, JsonArray override) {
        for (var item : override) {
            if (!base.contains(item)) {
                base.add(item);
            }
        }
    }

    /** Reads and parses a JSON file. */
    private static JsonObject readJson(Path path) throws IOException {
        try (var reader = Files.newBufferedReader(path)) {
            return JsonParser.parseReader(reader).getAsJsonObject();
        }
    }

    /** Writes a JSON element to a file with pretty-printing. */
    private static void writeJson(Path path, JsonElement content) throws IOException {
        final var folder = path.getParent();
        relativizeElement(content, folder, null);
        Files.createDirectories(folder);
        try (var writer = Files.newBufferedWriter(path)) {
            GSON.toJson(content, writer);
        }
        System.err.printf("Patched: %s%n", path);
    }

    /** Returns the string with its first character uppercased. */
    private static String capitalize(String s) {
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }

    private static void relativizeElement(JsonElement element, Path baseDir, Consumer<JsonElement> apply) {
        if (element.isJsonObject()) {
            for (var entry : element.getAsJsonObject().entrySet()) {
                relativizeElement(entry.getValue(), baseDir, entry::setValue);
            }
        } else if (element.isJsonArray()) {
            final var it = element.getAsJsonArray().asList().listIterator();
            while (it.hasNext()) {
                relativizeElement(it.next(), baseDir, it::set);
            }
        } else if (element.isJsonPrimitive() && element.getAsJsonPrimitive().isString()) {
            try {
                final var value = Path.of(element.getAsString());
                if (value.isAbsolute() && Files.exists(value)) {
                    final var relativePath = baseDir.relativize(value.normalize());
                    apply.accept(new JsonPrimitive(relativePath.toString().replace("\\", "/")));
                }
            } catch (Exception ignore) {
                // Path parsing or relativization failed — keep original value
            }
        }
    }
}
