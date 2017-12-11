#!/usr/bin/env bash

# Builds d2info.exe (64bit) using MinGW and Luastatic.
# Should be executed from root d2info directory.
# Resulting binary will be in `build/d2info.exe`.

ROOT_DIR=$PWD
BUILD_DIR=$ROOT_DIR/build

rm -rf build
mkdir build
cd build

LUA_VERSION=5.1.5

echo
echo "=== Downloading Lua $LUA_VERSION ==="
echo
curl https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz | tar xz

echo
echo "=== Downloading memreader ==="
echo
git clone https://github.com/squeek502/memreader.git || exit 1

echo
echo "=== Downloading sleep ==="
echo
git clone https://github.com/squeek502/sleep.git || exit 1

echo
echo "=== Building Lua ==="
echo
cd lua-$LUA_VERSION
make mingw CC=x86_64-w64-mingw32-gcc AR="x86_64-w64-mingw32-ar rcu"
cp src/liblua.a $BUILD_DIR || exit 1
cd $BUILD_DIR

echo
echo "=== Building memreader ==="
echo
cd memreader
cmake -DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/scripts/toolchain-mingw.cmake -DLUA_LIBRARIES=$BUILD_DIR/liblua.a -DLUA_INCLUDE_DIR=$BUILD_DIR/lua-$LUA_VERSION/src .
make
cp libmemreader.a $BUILD_DIR || exit 1
cd $BUILD_DIR

echo
echo "=== Building sleep ==="
echo
cd sleep
cmake -DCMAKE_TOOLCHAIN_FILE=$ROOT_DIR/scripts/toolchain-mingw.cmake -DLUA_LIBRARIES=$BUILD_DIR/liblua.a -DLUA_INCLUDE_DIR=$BUILD_DIR/lua-$LUA_VERSION/src .
make
cp libsleep.a $BUILD_DIR || exit 1
cd $BUILD_DIR

echo
echo "=== Copying d2info sources ==="
echo
cp -r $ROOT_DIR/d2info $BUILD_DIR
cp $ROOT_DIR/d2info.lua $BUILD_DIR

echo
echo "=== Building d2info.exe ==="
echo
CC=x86_64-w64-mingw32-gcc luastatic d2info.lua d2info/*.lua liblua.a libmemreader.a libsleep.a /usr/x86_64-w64-mingw32/lib/libversion.a /usr/x86_64-w64-mingw32/lib/libpsapi.a -Ilua-$LUA_VERSION/src
strip d2info.exe || exit 1

cd $ROOT_DIR
