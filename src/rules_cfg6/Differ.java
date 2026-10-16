import static com.vector.cfg.automation.scripting.api.IScriptTaskTypeApi.DV_PROJECT;

import java.io.BufferedWriter;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collector;
import java.util.stream.Collectors;

import com.vector.cfg.automation.scripting.api.IScriptCreationApi;
import com.vector.cfg.automation.scripting.api.IScriptFactory;
import com.vector.cfg.automation.scripting.api.IScriptTaskUserDefinedArgument;
import com.vector.cfg.automation.scripting.base.IProjectScriptExecutionContext;
import com.vector.cfg.automation.scripting.base.IScriptTaskCode;
import com.vector.cfg.model.access.AsrObjectLink;
import com.vector.cfg.model.asr.ecuc.access.IEcucModelAccess;
import com.vector.cfg.model.mdf.MIObject;
import com.vector.cfg.model.mdf.commoncore.autosar.MIARRef;
import com.vector.cfg.model.mdf.commoncore.autosar.MIReferrable;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MIContainer;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MIHasContainer;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MIInstanceReferenceValue;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MIModuleConfiguration;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MINumericalValue;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MIParameterValue;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MIReferenceValue;
import com.vector.cfg.model.mdf.model.autosar.ecucdescription.MITextualValue;
import com.vector.cfg.project.pai.IProjectHandlingApi;
import com.vector.cfg.util.asr.util.AutosarUtil;

public class Differ implements IScriptFactory, IScriptTaskCode<IProjectScriptExecutionContext> {

    private IScriptTaskUserDefinedArgument<String> theirsDvjson;

    @Override
    public void createScript(IScriptCreationApi creationApi) {
        creationApi.scriptTask("diff", DV_PROJECT, b -> {
            theirsDvjson = b.newUserDefinedArgument("t", String.class, "Project folder relative path to theirs' .dvjson file.");
            b.code(this);
        });
    }

    @Override
    public Object execute(IProjectScriptExecutionContext ctx, List<Object> arguments) {
        final var projectFolder = ctx.getPaths().getProjectFolder();
        return ctx.getInstance(IProjectHandlingApi.class)
                .parameterizeProjectLoad(open -> {
                    open.projectFile(projectFolder.resolve(theirsDvjson.getValue()));
                    open.loadGenerators(false);
                    open.enableValidation(false);
                }).openProject(theirs -> {
                    final var theirModules = getModules(theirs.getInstance(IEcucModelAccess.class)).stream().collect(byName());
                    try (var out = Files.newBufferedWriter(projectFolder.resolve("Output/Log/Diff.jsonl"))) {
                        for (var ourModule : getModules(ctx.getInstance(IEcucModelAccess.class))) {
                            compare(ourModule, getTheirElement(ourModule, theirModules, MIModuleConfiguration::getDefinitionRef), out);
                        }
                        for (var theirModule : theirModules.values()) {
                            compare(null, theirModule, out);
                        }
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                    return null;
                });
    }

    private static <T extends MIHasContainer> T getTheirElement(T our, Map<String, T> their, Function<T, ? extends MIARRef> getDefRef) {
        final var result = their.get(our.getName());
        if (result != null && Objects.equals(getDefinitionName(getDefRef.apply(our)), getDefinitionName(getDefRef.apply(result)))) {
            their.remove(our.getName());
            return result;
        }
        return null;
    }

    private static void compare(MIModuleConfiguration ours, MIModuleConfiguration theirs, BufferedWriter out) throws IOException {
        if (ours == null) {
            if (theirs != null) {
                report(theirs, "ONLY_IN_THEIRS", out);
                for (var theirContainer : theirs.getSubContainer()) {
                    compare(null, theirContainer, out);
                }
            }
        } else if (theirs == null) {
            report(ours, "ONLY_IN_OURS", out);
            for (var ourContainer : ours.getSubContainer()) {
                compare(ourContainer, null, out);
            }
        } else {
            final var theirContainers = theirs.getSubContainer().stream().collect(byName());
            for (var ourContainer : ours.getSubContainer()) {
                compare(ourContainer, getTheirElement(ourContainer, theirContainers, MIContainer::getDefinitionRef), out);
            }
            for (var theirContainer : theirContainers.values()) {
                compare(null, theirContainer, out);
            }
        }
    }

    private static void compare(MIContainer ours, MIContainer theirs, BufferedWriter out) throws IOException {
        if (ours == null) {
            if (theirs != null) {
                report(theirs, "ONLY_IN_THEIRS", out);
                for (var theirPrm : theirs.getParameter()) {
                    compare(null, null, theirPrm, getValue(theirPrm), out);
                }
                for (var theirContainer : theirs.getSubContainer()) {
                    compare(null, theirContainer, out);
                }
            }
        } else if (theirs == null) {
            report(ours, "ONLY_IN_OURS", out);
            out.append("{\"id\":\"").append(AsrObjectLink.create(ours).toString()).append("\",\"type\":\"ONLY_IN_OURS\"}\n");
            for (var ourPrm : ours.getParameter()) {
                compare(ourPrm, getValue(ourPrm), null, null, out);
            }
            for (var ourContainer : ours.getSubContainer()) {
                compare(ourContainer, null, out);
            }
        } else {
            final var theirPrms = getPrmsByDef(theirs);
            for (var entry : getPrmsByDef(ours).entrySet()) {
                final var t = theirPrms.remove(entry.getKey());
                if (t == null) {
                    for (var p : entry.getValue()) {
                        compare(p, getValue(p), null, null, out);
                    }
                } else if (entry.getValue().size() == 1 && t.size() == 1) {
                    compare(entry.getValue().getFirst(), getValue(entry.getValue().getFirst()), t.getFirst(), getValue(t.getFirst()), out);
                } else if (compareByIndex(entry.getValue())) {
                    entry.getValue().sort(Differ::compareByIndex);
                    t.sort(Differ::compareByIndex);
                    final var oursIt = entry.getValue().iterator();
                    final var theirsIt = t.iterator();
                    while (oursIt.hasNext() && theirsIt.hasNext()) {
                        final var oursNext = oursIt.next();
                        final var theirsNext = theirsIt.next();
                        compare(oursNext, getValue(oursNext), theirsNext, getValue(theirsNext), out);
                    }
                    while (oursIt.hasNext()) {
                        final var oursNext = oursIt.next();
                        compare(oursNext, getValue(oursNext), null, null, out);
                    }
                    while (theirsIt.hasNext()) {
                        final var theirsNext = theirsIt.next();
                        compare(null, null, theirsNext, getValue(theirsNext), out);
                    }
                } else {
                    final var theirsByValue = getPrmsByValue(t);
                    for (var our : getPrmsByValue(entry.getValue()).entrySet()) {
                        var their = theirsByValue.remove(our.getKey());
                        if (their == null) {
                            their = List.of();
                        }
                        if (our.getValue().size() > their.size()) {
                            for (var i = their.size(); i < our.getValue().size(); ++i) {
                                compare(our.getValue().get(i), our.getKey(), null, null, out);
                            }
                        } else if (their.size() > our.getValue().size()) {
                            for (var i = their.size(); i < our.getValue().size(); ++i) {
                                compare(null, null, their.get(i), our.getKey(), out);
                            }
                        }
                    }
                    for (var their : theirsByValue.entrySet()) {
                        for (var theirPrm : their.getValue()) {
                            compare(null, null, theirPrm, their.getKey(), out);
                        }
                    }
                }
            }
            final var theirContainers = theirs.getSubContainer().stream().collect(byName());
            for (var ourContainer : ours.getSubContainer()) {
                compare(ourContainer, getTheirElement(ourContainer, theirContainers, MIContainer::getDefinitionRef), out);
            }
            for (var theirContainer : theirContainers.values()) {
                compare(null, theirContainer, out);
            }
        }
    }

    private static void report(MIObject o, String type, BufferedWriter out) throws IOException {
        out.append("{\"id\":\"").append(AsrObjectLink.create(o).toString()).append("\",\"type\":\"").append(type).append("\"}\n");
    }

    private static boolean compareByIndex(List<MIParameterValue> prms) {
        final var def = prms.getFirst().getDefinition();
        return def != null && Boolean.TRUE.equals(def.getRequiresIndex());
    }

    private static int compareByIndex(MIParameterValue prm1, MIParameterValue prm2) {
        final var i1 = prm1.getIndex();
        final var i2 = prm2.getIndex();
        if (i1 == null) {
            return i2 == null ? 0 : 1;
        }
        return i2 == null ? -1 : i1.compareTo(i2);
    }

    private static void compare(MIParameterValue ours, String ourValue, MIParameterValue theirs, String theirValue, BufferedWriter out) throws IOException {
        if (ours == null) {
            if (theirs != null) {
                out.append("{\"id\":\"").append(AsrObjectLink.create(theirs).toString()).append("\",\"type\":\"ONLY_IN_THEIRS\",\"value\":").append(theirValue).append("}\n");
            }
        } else if (theirs == null) {
            out.append("{\"id\":\"").append(AsrObjectLink.create(ours).toString()).append("\",\"type\":\"ONLY_IN_OURS\",\"value\":").append(ourValue).append("}\n");
        } else if (!Objects.equals(ourValue, theirValue)) {
            out.append("{\"id\":\"").append(AsrObjectLink.create(ours).toString()).append("\",\"type\":\"CHANGED\",\"value-ours\":").append(ourValue).append(",\"value-theirs\":").append(theirValue).append("}\n");
        }
    }

    private static Collection<MIModuleConfiguration> getModules(IEcucModelAccess p) {
        return p.getModelInfo().getActiveModuleConfigurations();
    }

    private static <T extends MIReferrable> Collector<T, ?, LinkedHashMap<String, T>> byName() {
        return Collectors.toMap(
                MIReferrable::getName,
                Function.identity(),
                (m1, m2) -> {
                    throw new IllegalArgumentException("Cannot diff. Theirs contains two elements with the same name '" + m1.getName() + "'.");
                },
                LinkedHashMap::new
        );
    }

    private static LinkedHashMap<String, List<MIParameterValue>> getPrmsByDef(MIContainer c) {
        final var result = new LinkedHashMap<String, List<MIParameterValue>>();
        c.getParameter().forEach(p -> result.computeIfAbsent(getDefinitionName(p.getDefinitionRef()), (k) -> new ArrayList<>(1)).add(p));
        return result;
    }

    private static LinkedHashMap<String, List<MIParameterValue>> getPrmsByValue(List<MIParameterValue> prms) {
        final var result = new LinkedHashMap<String, List<MIParameterValue>>();
        for (var p : prms) {
            result.computeIfAbsent(getDefinitionName(p.getDefinitionRef()), (k) -> new ArrayList<>(1)).add(p);
        }
        return result;
    }

    private static String getDefinitionName(MIARRef defRef) {
        return defRef == null ? null : AutosarUtil.getLastShortname(defRef.getValue());
    }

    private static String getValue(MIParameterValue p) {
        String result = null;
        if (p instanceof MITextualValue) {
            result = ((MITextualValue) p).getValue();
            if (result != null) {
                result = "\"" + result + "\"";
            }
        } else if (p instanceof MIReferenceValue) {
            result = Optional.ofNullable(((MIReferenceValue) p).getValue()).map(MIARRef::getValue).orElse(null);
            if (result != null) {
                result = "\"" + result + "\"";
            }
        } else if (p instanceof MINumericalValue num) {
            final var ecucAccess = p.getProjectContext().getInstance(IEcucModelAccess.class);
            if (ecucAccess.containsBoolean(num)) {
                result = ecucAccess.getAsBoolean(num).toString();
            } else if (ecucAccess.containsInteger(num)) {
                result = ecucAccess.getAsInteger(num).toString();
            } else if (ecucAccess.containsFloat(num)) {
                result = BigDecimal.valueOf(ecucAccess.getAsFloat(num)).toPlainString();
            }
        } else if (p instanceof MIInstanceReferenceValue) {
            final var val = ((MIInstanceReferenceValue) p).getValue();
            if (val != null) {
                final var it = val.getContext().iterator();
                if (it.hasNext()) {
                    result = it.next().getValue();
                }
                if (result == null || result.isEmpty()) {
                    result = "???";
                }
                while (it.hasNext()) {
                    var next = it.next().getValue();
                    if (next == null || next.isEmpty()) {
                        next = "???";
                    }
                    result += "." + next;
                }
            }
            if (result != null) {
                result = "\"" + result + "\"";
            }
        }
        return result == null ? "null" : result;
    }
}
