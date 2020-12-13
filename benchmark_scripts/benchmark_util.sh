#!/bin/bash

# no trailing slash
BASE_URL="http://localhost:8080/thredds"

LOG_DIR="logs/"
ITERATIONS=1

CURL_TIMING_FMT="response-code: %{response_code}, time-connect: %{time_connect}, start-transfer: %{time_starttransfer}, total-time: %{time_total}, size-download: %{size_download}, url_effective: %{url_effective}"

SUBSET_VAR_1D="lon"
SUBSET_VAR_3D="analysed_sst"

MUR25_LAT_LAST_IDX=719
MUR25_LON_LAST_IDX=1439
MUR_LAT_LAST_IDX=17998
MUR_LON_LAST_IDX=35999

# some requests can become so large that the server will refuse it. In these
# cases, we limit the number of requests to a total of 10 times.
MAX_NUMBER_TIMES=10

# We stride in time for a few difference services. Define that in one spot.
TIME_STRIDE_VAL=10

GRID_TYPES=("netcdf3" "netcdf4")
GAP_TYPES=("csv" "netcdf3" "netcdf4")

if [ ! -d "${LOG_DIR}" ]
then
    mkdir ${LOG_DIR}
fi

# update_dataset_array
#   (no options)
# do not run directly - run as part of update_log_file_names
declare -A DATASETS
update_dataset_array () {
    # access_url, number of times, log file
    #DATASETS[mur-test/MUR/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1.nc]="1 ${SINGLE_GRANULE_LOG}"
    #DATASETS[mur-test/MUR25/2019_01_01_090000-JPL-L4_GHRSST-SSTfnd-MUR25-GLOB-v02.0-fv04.2.nc]="1 ${SINGLE_GRANULE_LOG}"
    #DATASETS[aggregations/mur-2019-01-iam.ncml]="31 ${MONTH_AGG_FILE_LOG}"
    #DATASETS[aggregations/mur25-2019-01-iam.ncml]="31 ${MONTH_AGG_FILE_LOG}"
    #DATASETS[scan-aggregation/mur-2019-01.nc]="31 ${MONTH_AGG_LOG}"
    DATASETS[scan-aggregation/mur25-2019-01.nc]="31 ${MONTH_AGG_LOG}"
    #DATASETS[scan-aggregation/mur-2019.nc]="365 ${YEAR_AGG_LOG}"
    #DATASETS[scan-aggregation/mur25-2019.nc]="365 ${YEAR_AGG_LOG}"
    #DATASETS[scan-aggregation/mur.nc]="730 ${ALL_AGG_LOG}"
    #DATASETS[scan-aggregation/mur25.nc]="730 ${ALL_AGG_LOG}"
}

remove_old_log () {
    if [ -e ${1} ]
    then
        rm ${1}
    fi
}

# update_log_name <prefix>
# ex: update_log_name "opendap"
update_log_file_names () {
    SINGLE_GRANULE_LOG="${LOG_DIR}/${1}_single_granule_benchmark.log"
    remove_old_log ${SINGLE_GRANULE_LOG}

    MONTH_AGG_FILE_LOG="${LOG_DIR}/${1}_one_month_ncml_file_based_agg_benchmark.log"
    remove_old_log ${MONTH_AGG_FILE_LOG}

    MONTH_AGG_LOG="${LOG_DIR}/${1}_one_month_agg_benchmark.log"
    remove_old_log ${MONTH_AGG_LOG}

    YEAR_AGG_LOG="${LOG_DIR}/${1}_one_year_agg_benchmark.log"
    remove_old_log ${YEAR_AGG_LOG}

    ALL_AGG_LOG="${LOG_DIR}/${1}_full_agg_benchmark.log"
    remove_old_log ${ALL_AGG_LOG}

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

