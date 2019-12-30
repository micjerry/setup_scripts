#!/bin/bash

JAVA_FILE=
JAVA_DIR=
JAVA_HOME=
JAVA_ROOT="/opt/jdks"

die() {
  echo $1
  exit 1
}

usage() {
  echo "Usage: $0 -f jdkfile"
  exit 0
}

install() {
  [ -f ${JAVA_FILE} ] || die "${JAVA_FILE} not exist."
  [ -d ${JAVA_ROOT} ] || mkdir -p ${JAVA_ROOT}
  tar -xzvf ${JAVA_FILE} -C ${JAVA_ROOT}
  JAVA_DIR=$(echo ${JAVA_FILE} | sed 's/.tar.gz//')
  JAVA_HOME="${JAVA_ROOT}/${JAVA_DIR}"
  [ -d ${JAVA_DIR} ] || die "install failed."
}

config() {
  echo "JAVA_HOME=${JAVA_HOME}" >> /etc/profile
  echo 'PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
  echo 'CLASSPATH=.:$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar' >> /etc/profile
  echo 'export PATH JAVA_HOME CLASSPATH' >> /etc/profile
  source /etc/profile
}

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -f|--file)
      JAVA_FILE="$2"
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

[ -z ${JAVA_FILE} ] && usage
install
config
