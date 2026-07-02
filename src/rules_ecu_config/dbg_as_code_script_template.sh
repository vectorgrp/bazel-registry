export DVCFG_JVM_ARGS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n -Djdk.attach.allowAttachSelf=true'
export DVCFG_TIMEOUT=-1
IDE_INTEGRATION=" --ide-integration-port ${EAC_IDE_PORT--2 --no-undo}"
if [[ "${EAC_DEBUG-}" == "true" ]]; then
    IDE_INTEGRATION+=" --debug"
fi

_term() {
    kill "$child" 2>/dev/null
}
trap _term SIGINT

FILE_ARGS
"CLI" eac --project "DVJSON" --bsw-package "BSW_PKG"JARS${IDE_INTEGRATION-} &

child=$!
wait "$child"
