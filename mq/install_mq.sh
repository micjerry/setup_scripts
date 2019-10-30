#!/bin/bash

LOCAL_IP="127.0.0.1"

install_deps() {
  sudo apt-get update -y
  sudo apt-get install curl gnupg -y
}

setup_sign() {
  #wget -O - "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" | sudo apt-key add -
  
  #echo "deb https://dl.bintray.com/rabbitmq-erlang/debian" > /etc/apt/sources.list.d/bintray.rabbitmq.list
  #echo "deb https://dl.bintray.com/rabbitmq/debian bionic main" >> /etc/apt/sources.list.d/bintray.rabbitmq.list
  
  curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo apt-key add -
  sudo apt-get install apt-transport-https
  
sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang-21.x
deb https://dl.bintray.com/rabbitmq/debian bionic main
EOF
}

setup() {
  #apt-get update
  #apt-get -y install rabbitmq-server
  #rabbitmq-plugins enable rabbitmq_management
  sudo apt-get update -y
  sudo apt-get install rabbitmq-server -y --fix-missing
  rabbitmq-plugins enable rabbitmq_management
  
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

config() {
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

install_deps
setup_sign
setup
config