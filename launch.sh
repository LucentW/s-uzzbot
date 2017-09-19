#!/usr/bin/env bash

THIS_DIR=$(cd $(dirname $0); pwd)
LUA_DIR="$THIS_DIR/.lua"
cd $THIS_DIR

update() {
  git pull
  git submodule update --init --recursive
  cd Madeline_lua_shim
  composer update
  cd ..
}

install_lua() {
  if [ ! -f $LUA_DIR]; then
    mkdir $LUA_DIR
  fi
  curl -R -O http://www.lua.org/ftp/lua-5.3.4.tar.gz
  tar zxf lua-5.3.4.tar.gz
  cd lua-5.3.4
  sed -i 's/CFLAGS= -O2/CFLAGS= -fPIC -O2/g' src/Makefile
  sed -i "s:/usr/local:$LUA_DIR:g" Makefile
  make linux
  make install
  cd ..
  rm -rf lua-5.3.4*
}

install_php_lua() {
  git clone https://github.com/giuseppem99/php-lua
  cd php-lua
  phpize
  ./configure --with-lua=$LUA_DIR
  make
  cp modules/lua.so ..
  cd ..
  rm -rf php-lua
}

# Will install luarocks on THIS_DIR/.luarocks
install_luarocks() {
  if [ ! -f .luarocks/bin/luarocks ]; then
    git clone https://github.com/keplerproject/luarocks.git
    cd luarocks
    git checkout tags/v2.4.2 # Current stable

    PREFIX="$THIS_DIR/.luarocks"

    ./configure --prefix=$PREFIX --sysconfdir=$PREFIX/luarocks --with-lua=$LUA_DIR --force-config

    RET=$?; if [ $RET -ne 0 ];
      then echo "Error. Exiting."; exit $RET;
    fi

    make build && make install
    RET=$?; if [ $RET -ne 0 ];
      then echo "Error. Exiting.";exit $RET;
    fi

    cd ..
    rm -rf luarocks
  fi
}

install_rocks() {
  ./.luarocks/bin/luarocks install luasocket
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install luasec
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  git clone https://github.com/ignacio/LuaOAuth oauth
  cp -a oauth/src/* .luarocks/share/lua/5.3/
  rm -rf oauth

  ./.luarocks/bin/luarocks install redis-lua
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install lua-cjson
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install fakeredis
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install luafilesystem
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install lub
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install luaexpat
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install xml
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install feedparser
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install serpent
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install lunitx
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install set
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi

  ./.luarocks/bin/luarocks install htmlparser 0.3.2-1
  RET=$?; if [ $RET -ne 0 ];
    then echo "Error. Exiting."; exit $RET;
  fi
}

install() {
  git pull
  git submodule update --init --recursive
  cd Madeline_lua_shim && composer update
  cd ..
  install_lua
  install_php_lua
  install_luarocks
  install_rocks
}

botlogin() {
  if [ ! -f ./Madeline_lua_shim/vendor/autoload.php ]; then
    echo "MadelineProto not found, installing..."
    install
  fi
  cd Madeline_lua_shim
  php botlogin.php
  cp bot.madeline ../bot.madeline
  cd ..
}

login() {
  if [ ! -f ./Madeline_lua_shim/vendor/autoload.php ]; then
    echo "MadelineProto not found, installing..."
    install
  fi
  cd Madeline_lua_shim
  php userlogin.php
  cp bot.madeline ../bot.madeline
  cd ..
}

if [ "$1" = "install" ]; then
  install
elif [ "$1" = "update" ]; then
  update
elif [ "$1" = "login" ]; then
  login
elif [ "$1" = "botlogin" ]; then
  botlogin
else
  if [ ! -f ./Madeline_lua_shim/vendor/autoload.php ]; then
    echo "MadelineProto not found"
    echo "Run $0 install"
    exit 1
  fi

  if [ ! -e "bot.madeline" ]; then
    echo "Login file not found"
    echo "Run $0 login or $0 botlogin"
    exit 1
  fi

  php -d extension='./lua.so' madeline.php

fi
