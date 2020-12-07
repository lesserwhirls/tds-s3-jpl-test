#!/bin/bash

BASE_URL="http://localhost:8080/thredds/dodsC"
CURL_TIMING_FMT="time-connect: %{time_connect}, start-transfer: %{time_starttransfer}, total-time: %{time_total}"

LOG_DIR="logs/"
ITERATIONS=1

if [ ! -d "${LOG_DIR}" ]; then
    mkdir ${LOG_DIR}
fi

SINGLE_GRANULE_LOG="${LOG_DIR}/single_granule_benchmark.log"

if [ -e ${SINGLE_GRANULE_LOG} ]; then
    rm ${SINGLE_GRANULE_LOG}
fi

MONTH_AGG_FILE_LOG="${LOG_DIR}/one_month_ncml_file_based_agg_benchmark.log"

if [ -e ${SINGLE_GRANULE_LOG} ]; then
    rm ${SINGLE_GRANULE_LOG}
fi
MONTH_AGG_LOG="${LOG_DIR}/one_month_agg_benchmark.log"

benchmark_it () {
    # arg order: 1. name of test, 2. subset query (unencoded) 
    echo "$1, $2"
    for (( i=1; i<=${ITERATIONS}; i++ ))
    do
        eval "echo -n \"${1}, ${i}, \" ${TEE_COMMAND}"
        eval "${BASE_COMMAND} --data-urlencode \"${2}\" ${TEE_COMMAND}"
    done
}


# access_url, time max index, lat max index, lon max index
declare -A DATASETS=(
    [mur-test/MUR/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc]="1 17999 36000 ${SINGLE_GRANULE_LOG}"
    [mur-test/MUR25/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc]="1 720 1440 ${SINGLE_GRANULE_LOG}"
    [aggregations/mur-2019-01-agg-iam.ncml]="31 17999 36000 ${MONTH_AGG_FILE_LOG}"
    [aggregations/mur25-2019-01-agg-iam.ncml]="31 720 1440 ${MONTH_AGG_FILE_LOG}"
    [scan-aggregation/mur-2019-01.nc]="31 17999 36000 ${MONTH_AGG_LOG}"
    [scan-aggregation/mur25-2019-01.nc]="31 720 1440 ${MONTH_AGG_LOG}"
)


for DATASET in "${!DATASETS[@]}"
do
    echo "Working on ${DATASET}"
    declare -a ARGS=(${DATASETS[$DATASET]})
    LOG_FILE=${ARGS[3]}
    echo "$LOG_FILE"
    MUR_TYPE="MUR"
    if [[ ${DATASET} == *"MUR25"* ]]; then
        MUR_TYPE="MUR25"   
    fi

    CURL_OUT_FMT="\"${MUR_TYPE}, ${CURL_TIMING_FMT}\n\""
    TEE_COMMAND=" | tee -a ${LOG_FILE}"
    BASE_COMMAND="curl -G -s -w ${CURL_OUT_FMT} -o /dev/null ${BASE_URL}/${DATASET}.dods"
    declare -a DIMS=( ${ARGS[0]} ${ARGS[1]} ${ARGS[2]} )
    echo "$DIMS"
    echo "#"
    echo "# 1D Variable Single value"
    echo "#"
    benchmark_it "1d-var-single-val" "lon[0]"
    echo ""

    echo "#"
    echo "# 1D Variable Every 100th value"
    echo "#"
    let STRIDE=${DIMS[2]}/100;
    benchmark_it "1d-var-100th-val" "lon[0:${STRIDE}:${DIMS[1]}]"
    echo ""
    
    echo "#"
    echo "# 1D Variable Full read"
    echo "#"
    benchmark_it "1d-var-all-${DIMS[2]}-vals" "lon"
    echo ""
    
    echo "#"
    echo "# 3D Variable Single value"
    echo "#"
    benchmark_it "3d-var-single-val" "analysed_sst[0,0,0]"
    echo ""
    
    echo "#"
    echo "# 3D Variable Outermost slice"
    echo "#"
    benchmark_it "3d-var-outtermost-slice-${DIMS[0]}-vals" "analysed_sst[:,0,0]"
    echo ""
    
    echo "#"
    echo "# 3D Variable Innermost slice"
    echo "#"
    benchmark_it "3d-var-innermost-slice-${DIMS[2]}-vals" "analysed_sst[0,0,:]"
    echo ""

    echo "#"
    echo "# 3D Variable Inner slice"
    echo "#"
    benchmark_it "3d-var-inner-slice-${DIMS[1]}-vals" "analysed_sst[0,:,0]"
    echo ""

done

