import com.vector.cfg.automation.scripting.api.IScriptCreationApi;
import com.vector.cfg.automation.scripting.api.IScriptFactory;
import com.vector.cfg.automation.scripting.base.IProjectScriptExecutionContext;
import com.vector.cfg.automation.scripting.base.IScriptTaskCode;
import com.vector.cfg.model.pai.api.TransactionApiEntryPointKt;
import org.jspecify.annotations.Nullable;
import java.util.List;
import static com.vector.cfg.automation.scripting.api.IScriptTaskTypeApi.DV_ON_ECU_EXTRACT_PRODUCER;

public class ArxmlPatcher implements IScriptFactory, IScriptTaskCode<IProjectScriptExecutionContext> {
    @Override
    public void createScript(IScriptCreationApi creationApi) {
        creationApi.scriptTask("patch", DV_ON_ECU_EXTRACT_PRODUCER, b -> b.code(this));
    }

    @Override
    public @Nullable Object execute(IProjectScriptExecutionContext ctx, List<@Nullable Object> arguments) {
        return TransactionApiEntryPointKt.transaction(ctx, "patch", t -> {
            // CALL;
            return null;
        });
    }
}
