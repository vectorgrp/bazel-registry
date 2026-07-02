import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;

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
 * Usage: {@code java -cp <gson.jar> SettingsPatch.java -d <dvjson> -p <patch>}
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
        String dvjsonPath = null;
        String patchPath = null;
        var i = 0;
        while (i < args.length) {
            switch (args[i]) {
                case "-d" -> {
                    if (i + 1 >= args.length) {
                        System.err.println("Missing value for -d");
                        System.exit(1);
                    }
                    dvjsonPath = args[++i];
                }
                case "-p" -> {
                    if (i + 1 >= args.length) {
                        System.err.println("Missing value for -p");
                        System.exit(1);
                    }
                    patchPath = args[++i];
                }
                default -> {
                    System.err.printf("Unknown option: %s%n", args[i]);
                    System.exit(1);
                }
            }
            i++;
        }
        if (dvjsonPath == null || patchPath == null) {
            System.err.println("Usage: java SettingsPatch.java -d <dvjson> -p <patch>");
            System.exit(1);
        }

        final var dvjson = Path.of(dvjsonPath);
        final var dvjsonDir = dvjson.toAbsolutePath().getParent();
        final var dvjsonContent = readJson(dvjson).getAsJsonObject();
        final var patch = readJson(Path.of(patchPath)).getAsJsonObject();

        for (var key : patch.keySet()) {
            ensureRegistered(dvjson, dvjsonContent, key);
            final var pathEntry = dvjsonContent.get(key);
            if (pathEntry == null || pathEntry.isJsonNull()) {
                System.err.printf("No path registered for key: '%s' — skipping%n", key);
                continue;
            }
            // Normalize backslashes from Windows-style dvjson entries to forward slashes for Path.resolve
            final var settingsFile = dvjsonDir.resolve(pathEntry.getAsString().replace("\\", "/"));
            patchSettingsFile(settingsFile, patch.get(key).getAsJsonObject());
        }
    }

    /**
     * Ensures that the given key is registered in the dvjson. If the key is missing, a default settings path ({@code Settings/<Key>.json}) is added and the dvjson is updated on
     * disk.
     *
     * @param dvjson        path to the dvjson file
     * @param dvjsonContent parsed dvjson object (modified in-place if key is missing)
     * @param key           the settings key to check
     */
    private static void ensureRegistered(Path dvjson, JsonObject dvjsonContent, String key) throws IOException {
        if (dvjsonContent.has(key)) {
            return;
        }
        if (key.isEmpty()) {
            throw new IllegalArgumentException("Patch key must not be empty");
        }
        final var rel = "Settings/" + capitalize(key) + ".json";
        dvjsonContent.addProperty(key, rel);
        writeJson(dvjson, dvjsonContent);
        System.out.printf("Registered: '%s' -> '%s'%n", key, rel);
    }

    /**
     * Patches a single settings file. If the file exists, its content is deep-merged with the patch value. If it doesn't exist, it is created with the patch content.
     *
     * @param settingsFile path to the settings file
     * @param patchValue   the JSON object to merge into the settings
     */
    private static void patchSettingsFile(Path settingsFile, JsonObject patchValue) throws IOException {
        if (Files.isRegularFile(settingsFile)) {
            final var merged = deepMerge(readJson(settingsFile).getAsJsonObject(), patchValue);
            writeJson(settingsFile, relativizePaths(merged, settingsFile));
            System.out.printf("Patched: %s%n", settingsFile);
        } else {
            Files.createDirectories(settingsFile.getParent());
            writeJson(settingsFile, relativizePaths(patchValue.deepCopy(), settingsFile));
            System.out.printf("Created: %s%n", settingsFile);
        }
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
     * @return a new merged JSON object
     */
    private static JsonObject deepMerge(JsonObject base, JsonObject override) {
        final var result = base.deepCopy();
        for (var key : override.keySet()) {
            final var overrideVal = override.get(key);
            // Explicit JSON null in the patch means "delete this key".
            if (overrideVal.isJsonNull()) {
                result.remove(key);
                continue;
            }
            final var baseVal = result.get(key);
            switch (overrideVal) {
                case JsonObject o when baseVal instanceof JsonObject b -> result.add(key, deepMerge(b, o));
                case JsonArray o when baseVal instanceof JsonArray b -> {
                    final var identityKey = ARRAY_IDENTITY_KEYS.get(key);
                    result.add(key, identityKey != null ? mergeArraysByKey(b, o, identityKey) : mergeArrays(b, o));
                }
                default -> result.add(key, overrideVal.deepCopy());
            }
        }
        return result;
    }

    /**
     * Merges two JSON arrays by matching elements on an identity key. If a base element has the same identity key value as an override element, it is replaced. If the override
     * element carries a {@code "__delete__": true} marker, the matched base element is removed instead. Unmatched override elements (without delete marker) are appended.
     *
     * @param base        the base array
     * @param override    the override array
     * @param identityKey the JSON field name used to match elements
     * @return a new merged array
     */
    private static JsonArray mergeArraysByKey(JsonArray base, JsonArray override, String identityKey) {
        final var result = base.deepCopy();
        for (var overrideItem : override) {
            if (!(overrideItem instanceof JsonObject overrideObj) || !overrideObj.has(identityKey)) {
                result.add(overrideItem.deepCopy());
                continue;
            }
            final var overrideId = overrideObj.get(identityKey);
            if (overrideId == null || overrideId.isJsonNull()) {
                result.add(overrideItem.deepCopy());
                continue;
            }

            final boolean isDelete = overrideObj.has(DELETE_MARKER)
                    && overrideObj.get(DELETE_MARKER).isJsonPrimitive()
                    && overrideObj.get(DELETE_MARKER).getAsBoolean();

            int matchIndex = -1;
            for (int i = 0; i < result.size(); i++) {
                if (result.get(i) instanceof JsonObject obj
                        && obj.has(identityKey)
                        && obj.get(identityKey).equals(overrideId)) {
                    matchIndex = i;
                    break;
                }
            }

            if (matchIndex >= 0) {
                if (isDelete) {
                    result.remove(matchIndex);
                } else {
                    result.set(matchIndex, overrideItem.deepCopy());
                }
            } else if (!isDelete) {
                result.add(overrideItem.deepCopy());
            }
        }
        return result;
    }

    /**
     * Merges two JSON arrays as a duplicate-free union. Each element from the override array is deep-copied and appended to the result if no deeply-equal element already exists.
     *
     * @param base     the base array
     * @param override the override array
     * @return a new merged array containing all unique elements (deep-copied)
     */
    private static JsonArray mergeArrays(JsonArray base, JsonArray override) {
        final var result = base.deepCopy();
        for (var item : override) {
            if (!result.contains(item)) {
                result.add(item.deepCopy());
            }
        }
        return result;
    }

    /** Reads and parses a JSON file. */
    private static JsonElement readJson(Path path) throws IOException {
        return JsonParser.parseString(Files.readString(path));
    }

    /** Writes a JSON element to a file with pretty-printing. */
    private static void writeJson(Path path, JsonElement content) throws IOException {
        Files.writeString(path, GSON.toJson(content));
    }

    /** Returns the string with its first character uppercased. */
    private static String capitalize(String s) {
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }

    /**
     * Recursively traverses a JSON element and converts all absolute path strings to paths relative to the directory of the given target file.
     *
     * @param element    the JSON element to process
     * @param targetFile the file the JSON will be written to (used as relativization base)
     * @return a new JSON element with absolute paths replaced by relative ones
     */
    private static JsonElement relativizePaths(JsonElement element, Path targetFile) {
        final var baseDir = targetFile.toAbsolutePath().getParent();
        return relativizeElement(element, baseDir);
    }

    private static JsonElement relativizeElement(JsonElement element, Path baseDir) {
        if (element.isJsonObject()) {
            final var result = new JsonObject();
            for (var entry : element.getAsJsonObject().entrySet()) {
                result.add(entry.getKey(), relativizeElement(entry.getValue(), baseDir));
            }
            return result;
        } else if (element.isJsonArray()) {
            final var result = new JsonArray();
            for (var item : element.getAsJsonArray()) {
                result.add(relativizeElement(item, baseDir));
            }
            return result;
        } else if (element.isJsonPrimitive() && element.getAsJsonPrimitive().isString()) {
            try {
                final var value = Path.of(element.getAsString());
                if (Files.isRegularFile(value) && value.isAbsolute()) {
                    final var relativePath = baseDir.relativize(value.normalize());
                    return new JsonPrimitive(relativePath.toString().replace("\\", "/"));
                }
            } catch (Exception ignore) {
                // Path parsing or relativization failed — keep original value
            }
        }
        return element;
    }
}
