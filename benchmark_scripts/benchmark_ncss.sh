#!/bin/bash

. ./benchmark_util.sh

set_service "ncss"

LAT_VAL=29
LON_VAL=42
GAP_LAT="latitude=${LAT_VAL}"
GAP_LON="longitude=${LON_VAL}"
GAP_TIME_STRIDE="timeStride=${TIME_STRIDE_VAL}"
SUBSET_VAR="var=${SUBSET_VAR_3D}"
TIME_ALL="time=all"

# benchmark_ncss <name of test> <one or more subset parameter key-value pairs>
# ex: benchmark_opendap "1d-var-single-val" "var=analysis_sst" "time=all" "latitude=15" "longitude=-50"
benchmark_ncss () {
    CURL_DATA_OPTS=""
    for (( i=1; i<=${ITERATIONS}; i++ ))
    do
        # build --data-urlencode strings to pass to curl
	for ((DATA_OPT=2; DATA_OPT<=$#; DATA_OPT++))
        do
            CURL_DATA_OPTS="${CURL_DATA_OPTS} --data-urlencode \"${!DATA_OPT}\""
        done
        eval "echo -n \"${1}, ${i}, \" ${TEE_COMMAND}"
        eval "${BASE_COMMAND} ${CURL_DATA_OPTS} ${TEE_COMMAND}"
    done
    CURL_DATA_OPTS=""
}

# subset grid by passing in lat_width, lon_width, number_of_times, accept_type
grid_subset_from_delta () {
    let LAT_WIDTH=2*${1}
    let LON_WIDTH=2*${2}

    let NORTH_VAL=${LAT_VAL}+${1}
    let SOUTH_VAL=${LAT_VAL}-${1}
    let EAST_VAL=${LON_VAL}+${2}
    let WEST_VAL=${LON_VAL}-${2}

    NORTH="north=${NORTH_VAL}"
    SOUTH="south=${SOUTH_VAL}"
    EAST="east=${EAST_VAL}"
    WEST="west=${WEST_VAL}"

    TOTAL_NUMBER_TIMES=${3}
    ACCEPT="accept=${4}"

    # 3D Variable Grid most recent time
    benchmark_ncss "grid-most-recent-${LAT_WIDTH}_lat-${LON_WIDTH}_lon-${RETURN_TYPE}" ${SUBSET_VAR} ${NORTH} ${SOUTH} ${EAST} ${WEST} ${ACCEPT}

    # if more than one time, also subset in time
    if (( ${TOTAL_NUMBER_TIMES} > 1 ))
    then
        let TIME_STRIDE_FOR_MAX=(${TOTAL_NUMBER_TIMES}+1)/${MAX_NUMBER_TIMES}
        TIME_STRIDE="timeStride=${TIME_STRIDE_VAL_FOR_MAX}"

	# 3D Variable Grid 10 times
        benchmark_ncss "grid-${MAX_NUMBER_TIMES}_time-${LAT_WIDTH}_lat-${LON_WIDTH}_lon-${RETURN_TYPE}" ${SUBSET_VAR} ${NORTH} ${SOUTH} ${EAST} ${WEST} ${TIME_ALL} ${TIME_STRIDE} ${ACCEPT}
    fi
}

# only run if base service URL is defined (e.g. https://localhost:8080/dodsC)
if [ -z ${var+BASE_SERVICE_URL} ]; then
for DATASET in "${!DATASETS[@]}"
do
    echo "Working on ${DATASET}"
    declare -a ARGS=(${DATASETS[$DATASET]})

    LOG_FILE=${ARGS[1]}

    let TIME_LAST_IDX=${ARGS[0]}-1

    if [[ ${DATASET,,} == *"mur25"* ]]
    then
        MUR_TYPE="MUR25"
    else
        MUR_TYPE="MUR"
    fi

    CURL_OUT_FMT="\"${MUR_TYPE}, ${CURL_TIMING_FMT}\n\""
    TEE_COMMAND=" | tee -a ${LOG_FILE}"
    BASE_COMMAND="curl -G -s -w ${CURL_OUT_FMT} -o /dev/null ${BASE_SERVICE_URL}/${DATASET}"
    for RETURN_TYPE in "${GRID_TYPES[@]}"
    do
        DELTAS=(1 2)
        for DELTA_LAT in "${DELTAS[@]}"
        do
            for DELTA_LON in "${DELTAS[@]}"
            do
                grid_subset_from_delta ${DELTA_LAT} ${DELTA_LON} ${ARGS[0]} ${RETURN_TYPE}
            done
        done
    done

    for RETURN_TYPE in "${GAP_TYPES[@]}"
    do
        ACCEPT="accept=${RETURN_TYPE}"
        # 3D Variable Grid-as-point most recent time
        #benchmark_ncss "gap-most-recent-${RETURN_TYPE}" ${SUBSET_VAR} ${GAP_LAT} ${GAP_LON} ${ACCEPT}

        #if (( ${TIME_LAST_IDX} > 0 ))
        #then
            # 3D Variable Grid-as-point every 10th time
        #benchmark_ncss "gap-every-10th-time-${RETURN_TYPE}" ${SUBSET_VAR} ${GAP_LAT} ${GAP_LON} ${TIME_ALL} ${GAP_TIME_STRIDE} ${ACCEPT}
        # 3D Variable Grid-as-point all times
        #benchmark_ncss "var-gap-all-${RETURN_TYPE}" ${SUBSET_VAR} ${GAP_LAT} ${GAP_LON} ${TIME_ALL} ${ACCEPT}
    #fi
    done
    done
fi

