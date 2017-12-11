#!/usr/bin/env bash

# Builds d2info.exe (64bit) using MinGW and Luastatic.
# Should be executed from root d2info directory.
# Resulting binary will be in `build/d2info.exe`.

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
cp src/liblua.a .. || exit 1
cd ..

echo
echo "=== Building memreader ==="
echo
cd memreader
cmake -DCMAKE_TOOLCHAIN_FILE=../../scripts/toolchain-mingw.cmake -DLUA_LIBRARIES=../liblua.a -DLUA_INCLUDE_DIR=../lua-$LUA_VERSION/src .
make
cp libmemreader.a .. || exit 1
cd ..

echo
echo "=== Building sleep ==="
echo
cd sleep
cmake -DCMAKE_TOOLCHAIN_FILE=../../scripts/toolchain-mingw.cmake -DLUA_LIBRARIES=../liblua.a -DLUA_INCLUDE_DIR=../lua-$LUA_VERSION/src .
make
cp libsleep.a .. || exit 1
cd ..

echo
echo "=== Copying d2info sources ==="
echo
cp -r ../d2info .
cp ../d2info.lua .

echo
echo "=== Building d2info.exe ==="
echo
CC=x86_64-w64-mingw32-gcc luastatic d2info.lua d2info/*.lua liblua.a libmemreader.a libsleep.a /usr/x86_64-w64-mingw32/lib/libversion.a /usr/x86_64-w64-mingw32/lib/libpsapi.a -Ilua-$LUA_VERSION/src
strip d2info.exe || exit 1

cd ..
