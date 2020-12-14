#!/bin/bash

. ./config.sh
. ./util.sh

RUNTIME_LOG="${LOG_DIR}/runtimes.log"
CONFIG_LOG="${LOG_DIR}/configs.log"

LOG_ARCH="logs_for_analysis.tar.bz2"

remove_file_if_exists ${RUNTIME_LOG}
remove_file_if_exists ${CONFIG_LOG}
remove_file_if_exists ${LOG_ARCH}

# log_runtime <benchmark> <start> <end>
log_runtime () {
    let RUNTIME=${3}-${2}
    RUNTIME_MSG="${1} runtime: ${RUNTIME} seconds"
    echo $RUNTIME_MSG | tee -a ${RUNTIME_LOG}
}

log_configs () {
    RUNDATE=`date`
    CONFIGS=(
        "DATE: ${RUNDATE}"
        "BASE_URL: ${BASE_URL}"
        "LOG_DIR: ${LOG_DIR}"
        "ITERATIONS: ${ITERATIONS}"
        "SUBSET_VAR_1D:${SUBSET_VAR_1D}"
        "SUBSET_VAR_3D: ${SUBSET_VAR_3D}"
        "MAX_NUMBER_TIMES: ${MAX_NUMBER_TIMES}"
        "TIME_STRIDE_VAL: ${TIME_STRIDE_VAL}"
        "GRID_TYPES: ${GRID_TYPES[*]}"
        "GAP_TYPES: ${GAP_TYPES[*]}")
    echo "Benchmark Configs:"
    for ((i = 0; i<${#CONFIGS[@]}; i++))
    do
        echo "${CONFIGS[${i}]}" | tee -a ${CONFIG_LOG}
    done
    echo ""
    echo ""
}

run_opendap () {
    T1=`date +%s`
    bash benchmark_opendap.sh
    T2=`date +%s`
    log_runtime "opendap benchmark" ${T1} ${T2}
}

run_ncss () {
    T1=`date +%s`
    bash benchmark_ncss.sh
    T2=`date +%s`
    log_runtime "ncss benchmark" ${T1} ${T2}
}

echo ""
log_configs
echo "Starting benchmarks."
echo ""
echo ""

START_TIME=`date +%s`
echo "run opendap benchmarks"
run_opendap
echo ""
echo ""
echo "run ncss benchmarks"
run_ncss
END_TIME=`date +%s`

echo ""
echo ""
echo "Finished benchmarks."

log_runtime "Total" ${START_TIME} ${END_TIME}
echo ""

tar -cjf ${LOG_ARCH} ${LOG_DIR}

