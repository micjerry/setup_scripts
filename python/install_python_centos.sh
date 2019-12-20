#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

CUR_PATH=`pwd`

die() {
  echo "${red}$1${reset}"
  exit 1
}

install_pyenv() {
  sudo yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel libffi-devel
  sudo yum -y install readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel
  
  [ -d /root/.pyenv ]
  mkdir -p /root/.pyenv
  tar -xzvf pyenv-1.2.14.tar.gz -C /root/.pyenv
  mv -rf /root/.pyenv/pyenv-1.2.14/* /root/.pyenv
  rm -rf /root/.pyenv/pyenv-1.2.14
  sed -i "/PYENV_ROOT/d" ~/.bashrc
  sed -i "/pyenv init/d" ~/.bashrc
  echo "export PYENV_ROOT=\"\$HOME/.pyenv\"" >> ~/.bashrc
  echo "export PATH=\"\$PYENV_ROOT/bin:\$PATH\"" >> ~/.bashrc
  echo "eval \"\$(pyenv init -)\"" >> ~/.bashrc
  source ~/.bashrc
}

install_python() {
  export PYTHON_BUILD_CACHE_PATH=${CUR_PATH}
  pyenv install 3.8.0
  pyenv global 3.8.0
  pyenv rehash
  python -m pip install --upgrade pip
}

install_packages() {
  #python -m pip install --no-index --find-links=pypackages tornado==6.0.3
  python -m pip install tornado
  python -m pip install redis
  python -m pip install redis-py-cluster
  python -m pip install python-redis
  
  [ -f Tornado-MySQL-0.5.tar.gz ] || die "Tornado-MySQL-0.5.tar.gz does not exist"
  tar -xzvf Tornado-MySQL-0.5.tar.gz -C ${CUR_PATH}
  cd  Tornado-MySQL-0.5
  python setup.py install
  cd - 
  rm -rf Tornado-MySQL-0.5
}

install_pyenv
install_python
install_packages
