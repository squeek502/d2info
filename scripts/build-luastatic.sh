#!/usr/bin/env bash

# Builds d2info.exe (64bit) using MinGW and Luastatic.
# Should be executed from root d2info directory.
# Resulting binary will be in `build/d2info.exe`.

set -euo pipefail

ROOT_DIR=$PWD
BUILD_DIR=$ROOT_DIR/build

rm -rf build
mkdir build
cd build

LUA_VERSION=5.1.5
LFS_VERSION=1.7.0-2
SLEEP_VERSION=1.0.0-2
MEMREADER_VERSION=1.0.0-1

# ensure luastatic and luarocks are available
which luastatic || { echo "luastatic not found"; exit 1; }
which luarocks || { echo "luarocks not found"; exit 1; }

echo
echo "=== Downloading Lua $LUA_VERSION ==="
echo
curl https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz | tar xz

echo
echo "=== Downloading memreader $MEMREADER_VERSION ==="
echo
luarocks unpack memreader $MEMREADER_VERSION

echo
echo "=== Downloading sleep $SLEEP_VERSION ==="
echo
luarocks unpack sleep $SLEEP_VERSION

echo
echo "=== Downloading LuaFileSystem $LFS_VERSION ==="
echo
luarocks unpack luafilesystem $LFS_VERSION

echo
echo "=== Building Lua ==="
echo
cd lua-$LUA_VERSION
make mingw CC=x86_64-w64-mingw32-gcc AR="x86_64-w64-mingw32-ar rcu"
cp src/liblua.a $BUILD_DIR
cd $BUILD_DIR

echo
echo "=== Building memreader ==="
echo
cd memreader-$MEMREADER_VERSION/memreader
cmake -DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/scripts/toolchain-mingw.cmake -DLUA_LIBRARIES=$BUILD_DIR/liblua.a -DLUA_INCLUDE_DIR=$BUILD_DIR/lua-$LUA_VERSION/src .
make
cp libmemreader.a $BUILD_DIR
cd $BUILD_DIR

echo
echo "=== Building sleep ==="
echo
cd sleep-$SLEEP_VERSION/sleep
cmake -DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/scripts/toolchain-mingw.cmake -DLUA_LIBRARIES=$BUILD_DIR/liblua.a -DLUA_INCLUDE_DIR=$BUILD_DIR/lua-$LUA_VERSION/src .
make
cp libsleep.a $BUILD_DIR
cd $BUILD_DIR

echo
echo "=== Building LuaFileSystem $LFS_VERSION ==="
echo
cd luafilesystem-$LFS_VERSION/luafilesystem
x86_64-w64-mingw32-gcc -c -O2 src/lfs.c -I$BUILD_DIR/lua-$LUA_VERSION/src -o src/lfs.o
x86_64-w64-mingw32-ar rcs src/lfs.a src/lfs.o
cp src/lfs.a $BUILD_DIR
cd $BUILD_DIR

echo
echo "=== Copying d2info sources ==="
echo
cp -r $ROOT_DIR/d2info $BUILD_DIR
cp $ROOT_DIR/d2info.lua $BUILD_DIR

echo
echo "=== Building d2info.exe ==="
echo
CC=x86_64-w64-mingw32-gcc luastatic d2info.lua d2info/*.lua liblua.a libmemreader.a libsleep.a lfs.a /usr/x86_64-w64-mingw32/lib/libversion.a /usr/x86_64-w64-mingw32/lib/libpsapi.a -Ilua-$LUA_VERSION/src
strip d2info.exe

cd $ROOT_DIR
