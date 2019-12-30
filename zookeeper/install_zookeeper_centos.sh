#!/bin/bash

LOCAL_IP="127.0.0.1"
ZOO_DOWNLOAD_PATH="https://archive.apache.org/dist/zookeeper/zookeeper-3.4.14/zookeeper-3.4.14.tar.gz"
ZOO_FILE="zookeeper-3.4.14.tar.gz"
ZOO_DIR=$(echo ${ZOO_FILE} | sed 's/.tar.gz//')
LOG_CONFIGFILE="log4j.properties"
ZOO_ROOT="/opt/zookeeper"
ZOO_HOME="${ZOO_ROOT}/${ZOO_DIR}"
ZOO_LOG="/var/log/zookeeper"
ZOO_DATAPATH="${ZOO_ROOT}/data"
ZOO_CLASSPATH="${ZOO_HOME}/conf/:${ZOO_HOME}/lib/*:${ZOO_HOME}/*"

ADMIN_PASSWORD="hcHWqyn2019"

. /etc/profile

echo "${JAVA_HOME}"

die() {
  echo "$1"
  exit 1
}

usage() {
  echo "Usage: $0 -p adminpassword"
  exit 0
}

check_require() {
  [ -z ${JAVA_HOME} ] && die "JAVA_HOME not found."
  [ -f ${LOG_CONFIGFILE} ] || echo "${LOG_CONFIGFILE} not exist."
}

download() {
  [ -f ${ZOO_FILE} ] || wget ${ZOO_DOWNLOAD_PATH}
  [ -f ${ZOO_FILE} ] || die "download ${ZOO_FILE} failed"
}

install() {
  [ -d ${ZOO_DATAPATH} ] || mkdir -p ${ZOO_DATAPATH}
  [ -d ${ZOO_ROOT} ] || mkdir -p ${ZOO_ROOT}
  
  tar -xzvf ${ZOO_FILE} -C ${ZOO_ROOT}
  [ -d ${ZOO_HOME} ] || die "install failed"
}

config() {
cat << EOF > ${ZOO_HOME}/conf/zoo.cfg
tickTime=2000
initLimit=10
syncLimit=5
dataDir=${ZOO_DATAPATH}
clientPort=2181
clientPortaddress=${LOCAL_IP}
EOF

cat << EOF > ${ZOO_HOME}/conf/java.env
#!/bin/bash

export JAVA_HOME=${JAVA_HOME}
export ZOO_LOG_DIR=${ZOO_LOG}
export ZOO_LOG4J_PROP="INFO,ROLLINGFILE"
EOF

  if [ -f ${LOG_CONFIGFILE} ]; then
    [ -f "${ZOO_HOME}/conf/${LOG_CONFIGFILE}" ] && rm -f "${ZOO_HOME}/conf/${LOG_CONFIGFILE}"
    cp -f ${LOG_CONFIGFILE} "${ZOO_HOME}/conf"
  fi
  
  if [ ! -z ${ADMIN_PASSWORD} ]; then
    local output=$(java -cp ${ZOO_CLASSPATH} org.apache.zookeeper.server.auth.DigestAuthenticationProvider super:${ADMIN_PASSWORD})
    local digest=$(echo ${output} | awk -F : '{print $3}')
    echo "" >> ${ZOO_HOME}/bin/zkEnv.sh
    echo "SERVER_JVMFLAGS=-Dzookeeper.DigestAuthenticationProvider.superDigest=super:${digest}" >> ${ZOO_HOME}/bin/zkEnv.sh
  fi
}

autostart() {
cat << EOF > /lib/systemd/system/zookeeper.service
[Unit]
Description=Zookeeper
After=syslog.target

[Service]
SyslogIdentifier=zookeeper
TimeoutStartSec=10min
Type=forking
ExecStart=${ZOO_HOME}/bin/zkServer.sh start
ExecStop=${ZOO_HOME}/bin/zkServer.sh stop

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl start zookeeper.service
}

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -p|--password)
      ADMIN_PASSWORD="$2"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "invalid arguments"
      usage
      ;;
  esac
  shift 
done

check_require
download
install
config
autostart
