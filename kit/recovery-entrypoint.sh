#!/bin/bash

apply_patch () {
    sed -i 's/if( $db_socket != "" ){/if( $db_socket == "" ){/g' /opt/percona-data-recovery-tool-for-innodb-0.5/create_defs.pl
}

prepare () {
    echo "[client]" > /etc/mysql/my.cnf
    echo "host	= ${MYSQL_HOST}" >> /etc/mysql/my.cnf
    echo "password	= ${MYSQL_PASSWORD}" >> /etc/mysql/my.cnf
    echo "port		= 3306" >> /etc/mysql/my.cnf
}

wait_for_mysql_to_get_up () {
    while ! nc -z "${MYSQL_HOST}" 3306; do
        echo " ~> Waiting 0.5 second for MySQL to get up on ${MYSQL_HOST}:3306"
        echo "    If it takes too long then something may be wrong in your database configuration"
        sleep 0.5
    done

    echo " >> Waiting 5 seconds, just to be sure"
    sleep 5
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
            recover_with_page_split "${ibdata_args}" "${table}"
            break
        fi

        recover_without_page_split "${ibdata_args}" "${table}"
    done
}

recover_with_page_split () {
    ibdata_args=$1
    table=$2

    set -x

    echo " >> Using page_parser"
    /bin/bash -c "./page_parser ${ibdata_args} -${MYSQL_VERSION}" > "/logs/${table}-pages.log"

    for page in $(ls pages-*/FIL_PAGE_TYPE_BLOB/*)
    do
        echo " >> Recovering page ${page} for table ${table}"
        /bin/bash -c "./constraints_parser -f ${page} -${MYSQL_VERSION}" >> "/recovered/${table}_page.sql"
    done

    set +x
}

recover_without_page_split () {
    ibdata_args=$1
    table=$2

    echo "   + Recovering the data" && set -x
    /bin/bash -c "./constraints_parser ${ibdata_args} -${MYSQL_VERSION}" > "/recovered/${table}.txt"
    set +x

    if [[ $? != 0 ]]; then
        echo "    !!! Error: Cannot recover data for ${table}"
        continue
    fi
}

give_some_time_to_inspect () {
    # give some time to enter the container and inspect
    echo " >> Finished, feel free to terminate the containers"
    sleep 3600
}

apply_patch
prepare
wait_for_mysql_to_get_up
do_the_recovery
give_some_time_to_inspect
