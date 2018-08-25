FROM debian:8.11-slim

ENV MYSQL_USER="root"
ENV MYSQL_PASSWORD="root"
ENV MYSQL_DATABASE="db"
ENV MYSQL_TABLES="t1,t2"
ENV MYSQL_VERSION=5
ENV MYSQL_HOST="db_with_structure"
ENV USE_PAGE_PARSER=1

RUN apt-get update && apt-get install -y wget tar bash make build-essential procps automake netcat file bzr \
    && mkdir -p /opt \
    && cd /opt && bzr branch lp:percona-data-recovery-tool-for-innodb \
    && mv /opt/percona-data-recovery-tool-for-innodb /opt/percona-data-recovery-tool-for-innodb-0.5 \
    && cd /opt/percona-data-recovery-tool-for-innodb-0.5 \
    && ls -la

RUN apt-get update \
    && apt-get install -y libncurses5-dev automake1.10 libc6-dev libmysqlclient-dev libmysql++-dev libmysqld-dev \
                          libncurses5 perl libdbi-perl mysql-client nano vim \
                          libdbd-mysql libdbd-mysql-perl \
    && cd /opt/percona-data-recovery-tool-for-innodb-0.5 && make

ADD ./kit/recovery-entrypoint.sh /recovery-entrypoint.sh

ENTRYPOINT /recovery-entrypoint.sh
