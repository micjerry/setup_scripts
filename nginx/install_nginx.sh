#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

BIND_IPADDR=

die() {
  echo "${red}$1${reset}"
  exit 1
}

install_deps() {
  sudo apt-get -y install build-essential libpcre3-dev zlib1g-dev libssl-dev libatomic-ops-dev libxml2-dev libxslt1-dev libgeoip1 libgeoip-dev libgd-dev libperl-dev
}

install_nginx() {
  wget -c http://nginx.org/download/nginx-1.17.5.tar.gz
  tar -xvzf nginx-1.17.5.tar.gz
  
  sudo useradd -s /sbin/nologin nginx
  
  cd nginx-1.17.5
  sudo ./configure --user=nginx --group=nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --with-select_module --with-poll_module --with-threads --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module --with-mail --with-mail=dynamic --with-mail_ssl_module --with-stream --with-stream=dynamic --with-stream_ssl_module --with-stream_realip_module  --with-stream_ssl_preread_module --with-cpp_test_module --with-compat --with-pcre --with-pcre-jit  --with-zlib-asm=CPU --with-debug --with-ld-opt="-Wl,-E"
  
  sudo make && sudo make install
}

config_nginx() {
  rm -f /etc/nginx/nginx.conf
  cp nginx.conf /etc/nginx
  sed -i "s/LOCALHOST/${BIND_IPADDR}/g" /etc/nginx/nginx.conf

cat << EOT > /lib/systemd/system/nginx.service
[Unit]
Description=The Nginx 1.17.5 service
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecStartPost=/bin/sleep 0.1
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOT

  sudo systemctl daemon-reload
}

usage()
{
  echo "Usage: $0 -h bind_ip_addr"
  exit 0
}

while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
    -h|--host)
      BIND_IPADDR="$2"
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

[ -z "${BIND_IPADDR}" ] && usage

install_deps
install_nginx
config_nginx