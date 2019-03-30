#!/bin/bash

LOCAL_IP="127.0.0.1"

setup_sign() {
  wget -O - "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" | sudo apt-key add -
  
  echo "deb https://dl.bintray.com/rabbitmq-erlang/debian" > /etc/apt/sources.list.d/bintray.rabbitmq.list
  echo "deb https://dl.bintray.com/rabbitmq/debian bionic main" >> /etc/apt/sources.list.d/bintray.rabbitmq.list
}

setup_mq() {
  apt-get update
  apt-get install rabbitmq-server
  rabbitmq-plugins enable rabbitmq_management
}

config_mq() {
cat << EOT > /etc/rabbitmq/rabbitmq.config
[
  {rabbit, [
    {disk_free_limit, 50000000},
    {log_levels, [{connection, error}, {channel, error}]},
    {tcp_listeners, [{"${LOCAL_IP}", 5672}]}
  ]}
].
EOT  

  systemctl restart rabbitmq-server.service
}

add_users() {
  /usr/sbin/rabbitmqctl add_user lgcall sysbaseAKL2019
  
  /usr/sbin/rabbitmqctl add_vhost vhostoper
  /usr/sbin/rabbitmqctl add_vhost vhostcmd
  /usr/sbin/rabbitmqctl add_vhost vhostevent
  /usr/sbin/rabbitmqctl add_vhost vhostcdr
  
  /usr/sbin/rabbitmqctl set_permissions -p vhostoper lgcall ".*" ".*" ".*"
  /usr/sbin/rabbitmqctl set_permissions -p vhostcmd lgcall ".*" ".*" ".*"
  /usr/sbin/rabbitmqctl set_permissions -p vhostevent lgcall ".*" ".*" ".*"
  /usr/sbin/rabbitmqctl set_permissions -p vhostcdr lgcall ".*" ".*" ".*"
  
  /usr/sbin/rabbitmqctl add_user lgadmin aklsFINO2019
  /usr/sbin/rabbitmqctl set_user_tags lgadmin administrator
  /usr/sbin/rabbitmqctl set_permissions -p / lgadmin ".*" ".*" ".*"
  /usr/sbin/rabbitmqctl set_permissions -p vhostoper lgadmin ".*" ".*" ".*"
  /usr/sbin/rabbitmqctl set_permissions -p vhostcmd lgadmin ".*" ".*" ".*"
  /usr/sbin/rabbitmqctl set_permissions -p vhostevent lgadmin ".*" ".*" ".*"
  /usr/sbin/rabbitmqctl set_permissions -p vhostcdr lgadmin ".*" ".*" ".*"
}

setup_sign
setup_mq
config_mq
add_users