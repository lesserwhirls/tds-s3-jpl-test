#!/bin/bash

CURL_TIMING_FMT="response-code: %{response_code}, time-connect: %{time_connect}, start-transfer: %{time_starttransfer}, total-time: %{time_total}, size-download: %{size_download}, url_effective: %{url_effective}"

MUR25_LAT_LAST_IDX=719
MUR25_LON_LAST_IDX=1439
MUR_LAT_LAST_IDX=17998
MUR_LON_LAST_IDX=35999

GRID_TYPES=("netcdf3" "netcdf4")
GAP_TYPES=("csv" "netcdf3" "netcdf4")

remove_file_if_exists () {
    if [ -e ${1} ]
    then
        rm ${1}
    fi
}

# update_log_name <prefix>
# ex: update_log_name "opendap"
update_log_file_names () {
    SINGLE_GRANULE_LOG="${LOG_DIR}/${1}_single_granule_benchmark.log"
    remove_file_if_exists ${SINGLE_GRANULE_LOG}

    SINGLE_GRANULE_LOCAL_LOG="${LOG_DIR}/${1}_single_granule_local_benchmark.log"
    remove_file_if_exists ${SINGLE_GRANULE_LOCAL_LOG}

    MONTH_AGG_FILE_LOG="${LOG_DIR}/${1}_one_month_ncml_file_based_agg_benchmark.log"
    remove_file_if_exists ${MONTH_AGG_FILE_LOG}

    MONTH_AGG_FILE_LOCAL_LOG="${LOG_DIR}/${1}_one_month_ncml_file_based_local_agg_benchmark.log"
    remove_file_if_exists ${MONTH_AGG_FILE_LOCAL_LOG}

    MONTH_AGG_LOG="${LOG_DIR}/${1}_one_month_agg_benchmark.log"
    remove_file_if_exists ${MONTH_AGG_LOG}

    MONTH_AGG_LOCAL_LOG="${LOG_DIR}/${1}_one_month_local_agg_benchmark.log"
    remove_file_if_exists ${MONTH_AGG_LOCAL_LOG}

    YEAR_AGG_LOG="${LOG_DIR}/${1}_one_year_agg_benchmark.log"
    remove_file_if_exists ${YEAR_AGG_LOG}

    ALL_AGG_LOG="${LOG_DIR}/${1}_full_agg_benchmark.log"
    remove_file_if_exists ${ALL_AGG_LOG}

    # now update the dataset array to include the new log names
    update_dataset_array
}

# set the service url for requests and the common service name used as a prefix
# for the log file names.
#
# set_service <service>
# ex: set_service dodsC
# service types:
#   * dodsC
#   * ncss
set_service () {
    unset SERVICE_BASE
    if [ ${1} = "dodsC" ]
    then
        update_log_file_names "opendap"
        SERVICE_BASE="dodsC"
    elif [ ${1} = "ncss" ]
    then
        update_log_file_names "ncss"
        SERVICE_BASE="ncss/grid"
    fi
    if [ -z ${var+SERVICE_BASE} ]
    then
      BASE_SERVICE_URL=${BASE_URL}/${SERVICE_BASE}
    fi
}

# get_mur_type <dataset>
# ex: var=$(get_mur_type "scan-aggregation/mur25-2019-01.nc")
# Based on Dataset name, is it MUR or MUR25?
declare -a DIMS
get_mur_type () {
    if [[ ${1,,} == *"mur25"* ]]
    then
        DIMS=( ${TIME_LAST_IDX} ${MUR25_LAT_LAST_IDX} ${MUR25_LON_LAST_IDX} )
        echo "MUR25"
    else
        DIMS=( ${TIME_LAST_IDX} ${MUR_LAT_LAST_IDX} ${MUR_LON_LAST_IDX} )
        echo "MUR"
    fi
}

# set_mur_dims <dataset> <number of times>
# ex: set_mur_dims "scan-aggregation/mur25-2019-01.nc" "31"
# Based on Dataset name and number of times, set the DIMS array
declare -a DIMS
set_mur_dims () {
    if [[ ${1,,} == *"mur25"* ]]
    then
        DIMS=( ${TIME_LAST_IDX} ${MUR25_LAT_LAST_IDX} ${MUR25_LON_LAST_IDX} )
    else
        DIMS=( ${TIME_LAST_IDX} ${MUR_LAT_LAST_IDX} ${MUR_LON_LAST_IDX} )
    fi
}

