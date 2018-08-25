#!/bin/bash

# verbose mode
set -x

# wait until the MySQL will be up...
sleep 5

cd /opt/percona-data-recovery-tool-for-innodb-0.5

for table in $(echo "${MYSQL_TABLES}" | sed "s/,/ /g")
do
    echo " >> Recovering table ${table}"
    echo "    + Creating definition..."
    ./create_defs.pl --host=${MYSQL_HOST} --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --db=${MYSQL_DATABASE} --table=${table} > ./include/table_defs.h
    cp ./include/table_defs.h ./table_defs.h
    cat ./include/table_defs.h

    if [[ ! $? ]]; then
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

    #/bin/bash -c "./page_parser ${ibdata_args} -${MYSQL_VERSION}" > "/logs/${table}-pages.log"

    echo "   + Recovering the data"
    /bin/bash -c "./constraints_parser ${ibdata_args} -${MYSQL_VERSION}" > "/recovered/${table}.txt"

    if [[ ! $? ]]; then
        echo "    !!! Error: Cannot recover data for ${table}"
        continue
    fi
done

# give some time to enter the container and inspect
sleep 3600
