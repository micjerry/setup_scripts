#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

die() {
  echo "${red}$1${reset}"
  exit 1
}

install_pyenv() {
  sudo apt-get install -y build-essential libbz2-dev libssl-dev libreadline-dev libsqlite3-dev tk-dev
  sudo apt-get install -y libpng-dev libfreetype6-dev
  curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
}

install_python() {
  sudo apt update
  sudo apt -y install software-properties-common
  sudo add-apt-repository -y ppa:deadsnakes/ppa
  sudo apt -y install python3.7
}

install_packages() {

}

config_nginx() {

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