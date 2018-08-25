FROM debian:8.11-slim

ENV MYSQL_USER="root"
ENV MYSQL_PASSWORD="root"
ENV MYSQL_DATABASE="db"
ENV MYSQL_TABLES="t1,t2"
ENV MYSQL_VERSION=5
ENV MYSQL_HOST="db_with_structure"

RUN apt-get update && apt-get install -y wget tar bash make build-essential procps automake \
    && mkdir -p /opt \
    && wget https://launchpad.net/percona-data-recovery-tool-for-innodb/trunk/release-0.5/+download/percona-data-recovery-tool-for-innodb-0.5.tar.gz -O /opt/innodb-recovery.tar.gz \
    && cd /opt && tar xvf innodb-recovery.tar.gz \
    && cd /opt/percona-data-recovery-tool-for-innodb-0.5 \
    && ls -la

RUN apt-get update \
    && apt-get install -y libncurses5-dev automake1.10 libc6-dev \
                          libncurses5 perl libdbi-perl file \
                          libdbd-mysql libdbd-mysql-perl \
    && cd /opt/percona-data-recovery-tool-for-innodb-0.5 && make

ADD ./kit/recovery-entrypoint.sh /recovery-entrypoint.sh

ENTRYPOINT /recovery-entrypoint.sh
