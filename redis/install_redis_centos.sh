#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

LOCAL_IP="127.0.0.1"

REDIS_CONFIG_PATH=/etc/rds_cluster
REDIS_DB_PATH=/opt/rds_cluster
REDIS_LOG_PATH=/var/log/rds_cluster

die() {
  echo "${red}$1${reset}"
  exit 1
}

install_deps() {
  [ -f /etc/redhat-release ] || die "it is not a centos os."
  if ! [ -x "$(command -v systemctl)" ]; then
    die "systemctl is not installed."
  fi
  [ -f rds_cluster_mgr.py ] || die "rds_cluster_mgr.py not found."
  [ -f rds_cluster_centos.sh ] || die "rds_cluster_centos.sh not found."
  #sudo apt-get update && sudo apt-get upgrade
  sudo yum -y install gcc glibc-devel tcl
  
}

install_redis() {
  wget http://download.redis.io/redis-stable.tar.gz
  tar xvzf redis-stable.tar.gz
  cd redis-stable
  sudo make install
  cd -
}

create_redis_process() {
  local process_port=$1
  [ -z "${process_port}" ] && die "invalid call"
  
  rm -rf ${REDIS_CONFIG_PATH}/${process_port}
  mkdir -p ${REDIS_CONFIG_PATH}/${process_port}
  
  rm -rf ${REDIS_DB_PATH}/${process_port}
  mkdir -p ${REDIS_DB_PATH}/${process_port}
  
  rm -rf ${REDIS_LOG_PATH}/${process_port}
  mkdir -p ${REDIS_LOG_PATH}/${process_port}

cat << EOF > ${REDIS_CONFIG_PATH}/${process_port}/redis.conf
port ${process_port}
dir ${REDIS_DB_PATH}/${process_port}
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 6000
appendonly yes
appendfilename appendonly.aof
daemonize yes
client-output-buffer-limit slave 0 0 0
repl-backlog-size 150mb
pidfile /var/run/rds_${process_port}.pid
loglevel notice
logfile ${REDIS_LOG_PATH}/rds_proc_${process_port}.log
bind ${LOCAL_IP}
EOF
}

config_autostart() {
  dos2unix rds_cluster.sh
  chmod +x rds_cluster.sh
  [ -f ${REDIS_CONFIG_PATH}/rds_cluster.sh ] && rm -f ${REDIS_CONFIG_PATH}/rds_cluster.sh
  cp rds_cluster_centos.sh ${REDIS_CONFIG_PATH}
  mv -f ${REDIS_CONFIG_PATH}/rds_cluster_centos.sh ${REDIS_CONFIG_PATH}/rds_cluster.sh
cat << EOT > /lib/systemd/system/rdscluster.service
[Unit]
Description=Redis Cluster
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=${REDIS_CONFIG_PATH}/rds_cluster.sh start
ExecStop=${REDIS_CONFIG_PATH}/rds_cluster.sh stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOT

  sudo systemctl daemon-reload
  systemctl start rdscluster.service
}

config_redis() {
  mkdir -p /var/log/rds_cluster
  for (( c=7001; c<=7006; c++ ))
  do
    create_redis_process "${c}"
  done
  
  config_autostart
  
  dos2unix rds_cluster_mgr.py
  chmod +x rds_cluster_mgr.py
  python3 rds_cluster_mgr.py ${LOCAL_IP}:7001 ${LOCAL_IP}:7002 ${LOCAL_IP}:7003 ${LOCAL_IP}:7004 ${LOCAL_IP}:7005 ${LOCAL_IP}:7006
  
}

create_appconf() {
  mkdir -p /etc/rds_apps
 
cat << EOF > /etc/rds_apps/redis.conf
{
"nodes": [{"host": "${LOOP_IP}", "port": "7001"},
          {"host": "${LOOP_IP}", "port": "7002"},
          {"host": "${LOOP_IP}", "port": "7003"},
          {"host": "${LOOP_IP}", "port": "7004"},
          {"host": "${LOOP_IP}", "port": "7005"},
          {"host": "${LOOP_IP}", "port": "7006"}
         ]
}
EOF
}

install_deps
install_redis
config_redis
create_appconf