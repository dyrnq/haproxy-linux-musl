#!/usr/bin/env bash

HAPROXY_VERSION="v3.2.0"
PCRE2_VERSION="10.47"
OPENSSL_VERSION="3.6.2"
ZLIB_VERSION="v1.3.2"
LUA_VERSION="v5.4.8"



while [ $# -gt 0 ]; do
    case "${1:-}" in
        --HAPROXY_VERSION|--haproxy-version)
            HAPROXY_VERSION="$2"
            ;;
        --PCRE2_VERSION|--pcre2-version)
            PCRE2_VERSION="$2"
            ;;
        --OPENSSL_VERSION|--openssl-version)
            OPENSSL_VERSION="$2"
            ;;
        --ZLIB_VERSION|--zlib-version)
            ZLIB_VERSION="$2"
            ;;
        --LUA_VERSION|--lua-version)
            LUA_VERSION="$2"
            ;;
        --*)
            echo "Illegal option $1"
            ;;
    esac
    shift $(( $# > 0 ? 1 : 0 ))
done



WORK_DIR="/tmp/haproxy-build"
INSTALL_DIR="/opt/haproxy-static"
mkdir -p $WORK_DIR $INSTALL_DIR

apk add --no-cache build-base libtool automake autoconf linux-headers git perl cmake readline-dev coreutils

rm -rf ${WORK_DIR:?}/*
pushd $WORK_DIR >/dev/null 2>&1 || exit 1
git clone --recursive --depth 1 -b $ZLIB_VERSION            https://github.com/madler/zlib.git
git clone --recursive --depth 1 -b pcre2-$PCRE2_VERSION     https://github.com/PCRE2Project/pcre2.git
git clone --recursive --depth 1 -b openssl-$OPENSSL_VERSION https://github.com/openssl/openssl.git
git clone --recursive --depth 1 -b $HAPROXY_VERSION         https://github.com/haproxy/haproxy.git
git clone --recursive --depth 1 -b $LUA_VERSION             https://github.com/lua/lua.git

echo "Building Zlib (Static)..."
pushd zlib >/dev/null 2>&1 || exit 1
./configure --static --prefix=$INSTALL_DIR
make -j$(nproc) install
popd || exit 1


echo "Building PCRE2 (Static)..."
pushd pcre2 >/dev/null 2>&1 || exit 1
./autogen.sh
./configure --prefix=$INSTALL_DIR --enable-pcre2-8 --enable-jit --disable-shared
make -j$(nproc) install
popd || exit 1

echo "Building OpenSSL (Static)..."
pushd openssl >/dev/null 2>&1 || exit 1
./config --prefix=$INSTALL_DIR -static
make -j"$(nproc)"
make -j$(nproc) install_sw
popd || exit 1


echo "Building lua"
pushd lua >/dev/null 2>&1 || exit 1
make -j"$(nproc)"
popd || exit 1


echo "Building HAProxy (Full Static)..."
pushd haproxy >/dev/null 2>&1 || exit 1


make -j$(nproc) \
TARGET=linux-musl \
USE_PTHREAD_EMULATION=1 \
USE_GETADDRINFO=1  \
USE_QUIC=1 \
USE_PCRE2_JIT=1 \
USE_PCRE2=1 PCRE2_INC=$INSTALL_DIR/include PCRE2_LIB=$INSTALL_DIR/lib \
USE_OPENSSL=1 SSL_INC=$INSTALL_DIR/include SSL_LIB=${INSTALL_DIR}/lib64 \
USE_ZLIB=1 ZLIB_INC=$INSTALL_DIR/include ZLIB_LIB=$INSTALL_DIR/lib \
USE_LUA=1 LUA_INC=${WORK_DIR}/lua LUA_LIB=${WORK_DIR}/lua \
LDFLAGS="-static -no-pie" \
ADDLIB="${WORK_DIR}/liblua.a ${INSTALL_DIR}/lib64/libssl.a ${INSTALL_DIR}/lib64/libcrypto.a ${INSTALL_DIR}/lib/libpcre2-8.a ${INSTALL_DIR}/lib/libz.a -lpthread -ldl" \
CC="gcc -static" \
CFLAGS="-fvect-cost-model=very-cheap"

echo "Verification:"
file ./haproxy
ldd ./haproxy || true
if ./haproxy -vv; then
  make PREFIX=$INSTALL_DIR install
fi
popd || exit 1