#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

MYSQL_HOST="localhost"
MYSQL_SUSER="root"
MYSQL_TMPAUFILE="mysql.temp"

MYSQL_NEW_DBPATH="/opt/mysqldb"
MYSQL_SEC="ak2s.@N098913"

MYSQL_ELOG="/var/log/mysqld.log"

cat << EOF > mysql.users
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_SEC}';
GRANT ALL ON *.* to 'root'@'%' IDENTIFIED BY '${MYSQL_SEC}';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
EOF

die() {
  echo "${red}$1${reset}"
  exit 1
}

install_mysql() {
  [ -f ${MYSQL_ELOG} ] && rm -f ${MYSQL_ELOG}
  [ -f mysql57-community-release-el7-11.noarch.rpm ] || wget 'https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm'
  [ -f mysql57-community-release-el7-11.noarch.rpm ] || die "can not download mysql57-community-release-el7-11.noarch.rpm"
  rpm -Uvh mysql57-community-release-el7-11.noarch.rpm
  yum -y install mysql-community-server
}

initial_mysql() {
  #change mysql db path in conf
  sed -i "s#datadir\(.*\)#datadir=${MYSQL_NEW_DBPATH}#" /etc/my.cnf
  
  rm -rf ${MYSQL_NEW_DBPATH}
  mkdir -p ${MYSQL_NEW_DBPATH}
  chmod 755 ${MYSQL_NEW_DBPATH}
  chown mysql:mysql ${MYSQL_NEW_DBPATH}
  
  systemctl start mysqld
}

config_mysql() {
  sleep 5
  local temp_se=`grep 'temporary password' ${MYSQL_ELOG} | awk -F 'localhost: ' '{print $2}'`
  [ -z "${temp_se}" ] && die "no temporary password found."
cat << EOF > ${MYSQL_TMPAUFILE}
[mysql]
host = ${MYSQL_HOST}
user = ${MYSQL_SUSER}
password = ${temp_se}
EOF

  mysql --defaults-extra-file=${MYSQL_TMPAUFILE} --connect-expired-password < mysql.users
  rm -f mysql.users
  rm -f ${MYSQL_TMPAUFILE}
}

initial_dbs() {
cat << EOF > ${MYSQL_TMPAUFILE}
[mysql]
host = ${MYSQL_HOST}
user = ${MYSQL_SUSER}
password = ${MYSQL_SEC}
EOF
  for filename in $(find . -name "create_*.sql"); do
    local dbfile_name=$(basename "$filename")
    local db_name=$(echo ${dbfile_name} | awk -F_ '{print $2}' | awk -F. '{print $1}')
    [ -z "${db_name}" ] && continue
    
    echo "CREATE DATABASE ${db_name} CHARACTER SET utf8 COLLATE utf8_general_ci; " | mysql --defaults-extra-file=${MYSQL_TMPAUFILE}
    mysql --defaults-extra-file=${MYSQL_TMPAUFILE} ${db_name} < ${filename}
  done
  
  rm -f ${MYSQL_TMPAUFILE}
}

install_mysql
initial_mysql
config_mysql
initial_dbs
