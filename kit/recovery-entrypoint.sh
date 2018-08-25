#!/bin/bash

# verbose mode
set -x

wait_for_mysql_to_get_up () {
    while ! nc -z "${MYSQL_HOST}" 3306; do
        echo " ~> Waiting 0.5 second for MySQL to get up on ${MYSQL_HOST}:3306"
        echo "    If it takes too long then something may be wrong in your database configuration"
        sleep 0.5
    done
}

do_the_recovery () {
    cd /opt/percona-data-recovery-tool-for-innodb-0.5

    for table in $(echo "${MYSQL_TABLES}" | sed "s/,/ /g")
    do
        echo " >> Recovering table ${table}"
        echo "    + Creating definition..."
        ./create_defs.pl --host=${MYSQL_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --db=${MYSQL_DATABASE} --table=${table} > ./include/table_defs.h
        cp ./include/table_defs.h ./table_defs.h
        cat ./include/table_defs.h

        if [[ $? != 0 ]]; then
            echo "    !!! Error: Cannot create definition for ${table}"
            continue
        fi

        echo "    + Building the tool with the custom definition..."
        make > "/logs/${table}-build.log"

        echo "    + Parsing pages..."
        ibdata_args="-f"


        for ibdata_file in $(ls /data/ibdata*)
        do
            ibdata_args="${ibdata_args} ${ibdata_file}"
        done

        if [[ ${USE_PAGE_PARSER} == 1 ]]; then
            echo " >> Using page_parser"
            /bin/bash -c "./page_parser ${ibdata_args} -${MYSQL_VERSION}" > "/logs/${table}-pages.log"
        fi

        echo "   + Recovering the data"
        /bin/bash -c "./constraints_parser ${ibdata_args} -${MYSQL_VERSION}" > "/recovered/${table}.txt"

        if [[ $? != 0 ]]; then
            echo "    !!! Error: Cannot recover data for ${table}"
            continue
        fi
    done
}

give_some_time_to_inspect () {
    # give some time to enter the container and inspect
    echo " >> Finished, feel free to terminate the containers"
    sleep 3600
}

wait_for_mysql_to_get_up
do_the_recovery
give_some_time_to_inspect
