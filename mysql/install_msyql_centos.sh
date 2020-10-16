#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

MYSQL_HOST="localhost"
MYSQL_SUSER=""
MYSQL_SEC=""
MYSQL_TMPAUFILE="mysql.temp"

MYSQL_NEW_DBPATH="/opt/mysqldb"

MYSQL_ELOG="/var/log/mysqld.log"

die() {
  echo "${red}$1${reset}"
  exit 1
}

install_deps() {
  [ -f odbc.ini ] || die "odbc.ini not exist"
  [ -f odbcinst.ini ] || die "odbc.ini not exist"
  [ -f unixODBC-2.3.9.tar.gz ] || die "unixODBC-2.3.9.tar.gz not exist"
  [ -f mysql-connector-odbc-8.0.20-1.el7.x86_64.rpm ] || die "mysql-connector-odbc-8.0.20-1.el7.x86_64.rpm not exist"
  [ -f mysql57-community-release-el7-11.noarch.rpm ] || die "mysql57-community-release-el7-11.noarch.rpm not exist"

  [ -d unixODBC-2.3.9 ] && rm -rf unixODBC-2.3.9
  
  yum install -y unixODBC-devel
  tar -xzvf unixODBC-2.3.9.tar.gz
  cd unixODBC-2.3.9
  ./configure --sysconfdir=/etc --prefix=/usr/lib/unixODBC
  make
  make install
  cd -
  echo "/usr/lib/unixODBC/lib" > /etc/ld.so.conf.d/odbc.conf
  /sbin/ldconfig
  
  rpm --nodeps -ivh mysql-connector-odbc-8.0.20-1.el7.x86_64.rpm
}

config_odbc() {
    cp -f odbc.ini /etc
    cp -f odbcinst.ini /etc
	
	dos2unix /etc/odbc.ini
    dos2unix /etc/odbcinst.ini
  
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
  
  #disable mysql auth
  systemctl set-environment MYSQLD_OPTS="--skip-grant-tables"
  systemctl start mysqld
}

config_mysql() {
  sleep 5

  MYSQL_SEC=`cat /etc/odbc.ini | grep "PASSWORD" | awk -F = '{print $2}' | sed 's/ //g'`
  [ -z "${MYSQL_SEC}" ] && die "mysql password was not configed"
  MYSQL_SUSER=`cat /etc/odbc.ini | grep "USER" | awk -F = '{print $2}' | sed 's/ //g'`
  [ -z "${MYSQL_SUSER}" ] && die "mysql user was not configed"

cat << EOF > mysql.users
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_SEC}';
GRANT ALL ON *.* to 'root'@'%' IDENTIFIED BY '${MYSQL_SEC}';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
EOF

  mysql -u root < mysql.users
  rm -f mysql.users

  #enable mysql auth
  systemctl stop mysqld
  systemctl unset-environment MYSQLD_OPTS
  systemctl start mysqld
}

initial_dbs() {
  sleep 5

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

install_deps
config_odbc
install_mysql
initial_mysql
config_mysql
initial_dbs
