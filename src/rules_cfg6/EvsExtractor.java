import java.util.HashSet;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Predicate;
import com.vector.cfg.automation.api.ScriptApi;
import com.vector.cfg.model.asr.access.IAsrReferrableAccess;
import com.vector.cfg.model.access.IModelRootAccess;
import com.vector.cfg.model.mdf.MIObject;
import com.vector.cfg.model.mdf.model.autosar.commonpatterns.varianthandling.MIEvaluatedVariantSet;
import com.vector.cfg.model.mdf.commoncore.autosar.ref.MIGARRef;
import com.vector.cfg.model.mdf.model.autosar.commonpatterns.varianthandling.MIPredefinedVariant;
import com.vector.cfg.model.mdf.model.autosar.commonpatterns.varianthandling.MIPostBuildVariantCriterionValueSet;
import com.vector.cfg.model.mdf.model.autosar.commonpatterns.varianthandling.MIPostBuildVariantCriterionValue;
import com.vector.cfg.model.mdf.model.autosar.commonpatterns.varianthandling.MIPostBuildVariantCriterion;
import com.vector.cfg.model.mdf.ar4x.swcomponenttemplate.datatype.computationmethod.MICompuMethod;
import com.vector.cfg.model.mdf.model.autosar.base.MIARPackage;

public class EvsExtractor {

    private static final HashSet<MIObject> doNotDelete = new HashSet<>();

    public static void run(String shortNamePath) {
        final var activeProject = ScriptApi.activeProject();
        final var referrable = activeProject.getInstance(IAsrReferrableAccess.class).getReferrableByPath(shortNamePath);
        if (!(referrable instanceof MIEvaluatedVariantSet)) {
            throw new IllegalArgumentException("No EvaluatedVariantSet at short name path " + shortNamePath);
        }
        doNotDelete.add(referrable);
        ((MIEvaluatedVariantSet) referrable).getEvaluatedVariant()
                .stream()
                .map(MIGARRef::getRefTarget)
                .filter(Objects::nonNull)
                .forEach(EvsExtractor::doNotDelete_MIPredefinedVariant);
        activeProject.getInstance(IModelRootAccess.class)
                .getAutosarRoot()
                .getSubPackage()
                .stream()
                .toList()
                .forEach(EvsExtractor::prune);
    }

    private static void doNotDelete_MIPredefinedVariant(MIPredefinedVariant o) {
        doNotDelete.add(o);
        o.getPostBuildVariantCriterionValueSet()
                .stream()
                .map(MIGARRef::getRefTarget)
                .filter(Objects::nonNull)
                .forEach(EvsExtractor::doNotDelete_MIPostBuildVariantCriterionValueSet);
    }

    private static void doNotDelete_MIPostBuildVariantCriterionValueSet(MIPostBuildVariantCriterionValueSet o) {
        doNotDelete.add(o);
        o.getPostBuildVariantCriterionValue()
                .stream()
                .map(MIPostBuildVariantCriterionValue::getVariantCriterion)
                .map(MIGARRef::getRefTarget)
                .filter(Objects::nonNull)
                .forEach(EvsExtractor::doNotDelete_MIPostBuildVariantCriterion);
    }

    private static void doNotDelete_MIPostBuildVariantCriterion(MIPostBuildVariantCriterion o) {
        doNotDelete.add(o);
        Optional.ofNullable(o.getCompuMethod())
                .map(MIGARRef::getRefTarget)
                .ifPresent(doNotDelete::add);
    }

    private static void prune(MIARPackage o) {
        o.getElement()
                .stream()
                .filter(Predicate.not(doNotDelete::contains))
                .toList()
                .forEach(MIObject::deleteFromModel);
        o.getSubPackage()
                .forEach(EvsExtractor::prune);
        if (o.getElement().isEmpty() && o.getSubPackage().isEmpty()) {
            o.deleteFromModel();
        }
    }
}
