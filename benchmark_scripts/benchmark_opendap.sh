#!/bin/bash

. ./config.sh
. ./util.sh

set_service "dodsC"

# benchmark_opendap <name of test> <unencoded subset query>
# ex: benchmark_opendap "1d-var-single-val" "lon[0]"
benchmark_opendap () {
    for (( i=1; i<=${ITERATIONS}; i++ ))
    do
        eval "echo -n \"${1}, ${i}, \" ${TEE_COMMAND}"
        eval "${BASE_COMMAND} --data-urlencode \"${2}\" ${TEE_COMMAND}"
        #eval "${BASE_COMMAND} --data \"${2}\" ${TEE_COMMAND}"
    done
}

# only run if base service URL is defined (e.g. https://localhost:8080/dodsC)
if [ ! -z ${BASE_SERVICE_URL+var} ]; then
for DATASET in "${!DATASETS[@]}"
do
    echo "Working on ${DATASET}"
    declare -a ARGS=(${DATASETS[$DATASET]})

    LOG_FILE=${ARGS[1]}

    let TIME_LAST_IDX=${ARGS[0]}-1

    MUR_TYPE=$(get_mur_type ${DATASET})
    set_mur_dims ${DATASET} ${ARGS[0]}

    CURL_OUT_FMT="\"${MUR_TYPE}, ${CURL_TIMING_FMT}\n\""
    TEE_COMMAND=" | tee -a ${LOG_FILE}"
    BASE_COMMAND="curl -G -s -w ${CURL_OUT_FMT} -o /dev/null ${BASE_SERVICE_URL}/${DATASET}.dods"

    let MID_TIME=${DIMS[0]}/2
    let MID_LAT=${DIMS[1]}/2
    let MID_LON=${DIMS[2]}/2
    # 1D Variable Single value
    benchmark_opendap "1d-var-single-val" "${SUBSET_VAR_1D}[0]"

    # 1D Variable Single value mid var
    benchmark_opendap "1d-var-single-val-mid-var" "${SUBSET_VAR_1D}[${MID_LAT}]"

    # 1D Variable Every 100th value
    benchmark_opendap "1d-var-100th-val" "${SUBSET_VAR_1D}[0:10:${DIMS[2]}]"
    
    # 1D Variable Full read
    benchmark_opendap "1d-var-all-${DIMS[2]}-vals" "${SUBSET_VAR_1D}"
    
    # full slices in time can become massive (size) for the requests below, and
    # opendap will not fulfill many of them, so we will reduce the total number
    # of slices in time to 10
    if (( ${MID_TIME} > 0 ))
    then
        let TIME_STRIDE=(${DIMS[0]}+1)/${MAX_NUMBER_TIMES}
        let TIME_FINAL=${DIMS[0]}-${TIME_STRIDE}
        SLICED_TIME="0:${TIME_STRIDE}:${TIME_FINAL}"
	let SIZE=(${DIMS[0]}/${TIME_STRIDE})
        echo "${TIME_STRIDE} ${DIMS[0]} ${TIME_FINAL}"
    else
        SIZE=1
        SLICED_TIME="0:1:0"
    fi

    # 3D Variable Single value (mid aggregation, if agg)
    benchmark_opendap "3d-var-single-val" "${SUBSET_VAR_3D}[${MID_TIME}][0][0]"

    # 3D Variable Outermost slice (mid aggregation, if agg)
    benchmark_opendap "3d-var-outtermost-slice-${SIZE}-vals" "${SUBSET_VAR_3D}[${SLICED_TIME}][${MID_LAT}][${MID_LON}]"

    # 3D Variable Innermost slice (mid aggregation, if agg)
    benchmark_opendap "3d-var-innermost-slice-${DIMS[2]}-vals" "${SUBSET_VAR_3D}[${MID_TIME}][${MID_LAT}][0:1:${DIMS[2]}]"

    # 3D Variable Inner slice (mid aggregation, if agg)
    benchmark_opendap "3d-var-inner-slice-${DIMS[1]}-vals" "${SUBSET_VAR_3D}[${MID_TIME}][0:1:${DIMS[1]}][${MID_LON}]"
done
fi

