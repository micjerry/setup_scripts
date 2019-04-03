#!/bin/bash

LOCAL_IP="127.0.0.1"

setup_sign() {
  apt-get -y install software-properties-common
  add-apt-repository ppa:vbernat/haproxy-1.9 -y
}

setup() {
  apt-get update
  apt-get install haproxy=1.9.\*
}

config() {
cat << EOT > /tmp/haproxy_mq.cfg

frontend mq_service
        bind 127.0.0.1:6660
        mode tcp
        option tcplog
        option clitcpka
        default_backend mq_servers

backend mq_servers
        mode tcp
        balance leastconn
        option tcplog
        option clitcpka
        server rabbitmq1 127.0.0.1:5672 check

EOT

  cat /tmp/haproxy_mq.cfg >> /etc/haproxy/haproxy.cfg
  rm -f /tmp/haproxy_mq.cfg

  systemctl status haproxy.service
}

setup_sign
setup
config
add_users