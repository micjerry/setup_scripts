#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

APP_NAMESMAP="/tmp/swinstalltemp.txt"
APP_HOME="/opt/swapps"
APP_LOGHOME="/var/log"
APP_JARNAME=""
APP_NAME=""
APP_CONFFILE=""
APP_CONFPATH="config"

die() {
  echo "${red}$1${reset}"
  exit 1
}

echo "
swagent-mod-main.jar=swagent
lgsw-mgr.jar=swoutcall
" > ${APP_NAMESMAP}

load_env() {
  if [ -z "${APP_NAME}" ]
  then
    APP_JARNAME=`ls *.jar`
	[ -z "${APP_JARNAME}" ] && die "jar file was not found in the current path."
    APP_NAME=`cat ${APP_NAMESMAP} | grep "${APP_JARNAME}" | awk -F = '{print $2}'`
  else
    APP_JARNAME=`cat ${APP_NAMESMAP} | grep "${APP_NAME}" | awk -F = '{print $1}'`
  fi

  [ -z "${APP_NAME}" ] && die "unkown server."

  APP_CONFFILE=`echo "${APP_JARNAME}" | sed -e 's/.jar/.conf/'`
  [ -d ${APP_CONFPATH} ] || die "${APP_CONFPATH} does noe exist."
}

#clean the old version
clean() {
  local app_path="${APP_HOME}/${APP_NAME}"
  local app_log="${APP_LOGHOME}/${APP_NAME}"
  
  [ -d ${app_path} ] && rm -rf ${app_path}
  mkdir -p ${app_path}

  [ -d ${app_log} ] && rm -rf ${app_log}
  mkdir -p ${app_log}
}

#install the new version
install() {
  local app_path="${APP_HOME}/${APP_NAME}"
  cp ${APP_JARNAME} ${app_path} > /dev/null 2>&1
  cp ${APP_CONFFILE} ${app_path} > /dev/null 2>&1
  cp -r ${APP_CONFPATH} ${app_path} > /dev/null 2>&1
  
  cd ${app_path} > /dev/null 2>&1
  chmod +x ${APP_JARNAME} > /dev/null 2>&1
  dos2unix "${APP_CONFFILE}" > /dev/null 2>&1
  cd - > /dev/null 2>&1
  
  echo "${green}${APP_NAME} installed${reset}"
}

autostart() {
local full_path="${APP_HOME}/${APP_NAME}/${APP_JARNAME}"

cat << EOT > /etc/systemd/system/${APP_NAME}.service
[Unit]
Description=APP_NAME Server
After=syslog.target

[Service]
ExecStart=APP_PATH SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOT

sed -i "s/APP_NAME/${APP_NAME}/g" /etc/systemd/system/${APP_NAME}.service
sed -i "s#APP_PATH#${full_path}#g" /etc/systemd/system/${APP_NAME}.service

systemctl enable ${APP_NAME}.service
}

usage()
{
  echo "Usage: $0 -s servicename"
  exit 0
}

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -s|--service)
      APP_NAME="$2"
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

load_env
clean
install
autostart
