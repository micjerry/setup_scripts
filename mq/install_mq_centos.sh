#!/bin/bash

LOCAL_IP="127.0.0.1"
ADMIN_PASS=
ADMIN_USER=

usage()
{
  echo "Usage: $0 -u adminuser -p adminpassword"
  exit 0
}

install_deps() {
  sudo yum -y install epel-release
  sudo yum -y update
  sudo yum -y install erlang socat
}

setup() {
  wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.6.10/rabbitmq-server-3.6.10-1.el7.noarch.rpm
  rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
  rpm -Uvh rabbitmq-server-3.6.10-1.el7.noarch.rpm
  
cat << EOT > /etc/rabbitmq/rabbitmq.config
[
  {rabbit, [
    {disk_free_limit, 50000000},
    {log_levels, [{connection, error}, {channel, error}]},
    {tcp_listeners, [{"${LOCAL_IP}", 5672}]}
  ]}
].
EOT

  systemctl restart rabbitmq-server
  systemctl enable rabbitmq-server
  rabbitmq-plugins enable rabbitmq_management
}

config() {
  if [ ! -z "${ADMIN_PASS}" ] && [ ! -z "${ADMIN_USER}" ]; then
    /usr/sbin/rabbitmqctl add_user ${ADMIN_USER} ${ADMIN_PASS}
    /usr/sbin/rabbitmqctl set_user_tags ${ADMIN_USER} administrator
    /usr/sbin/rabbitmqctl set_permissions -p / ${ADMIN_USER} ".*" ".*" ".*"
  fi
  
  #/usr/sbin/rabbitmqctl add_user custom_user password
  #/usr/sbin/rabbitmqctl add_vhost custom_host
  #/usr/sbin/rabbitmqctl set_permissions -p custom_host custom_user ".*" ".*" ".*"
  #/usr/sbin/rabbitmqctl set_permissions -p custom_host ${ADMIN_USER} ".*" ".*" ".*"
}

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -p|--password)
      ADMIN_PASS="$2"
      shift
      ;;
    -u|--user)
      ADMIN_USER="$2"
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

install_deps
setup
config