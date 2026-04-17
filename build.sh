#!/usr/bin/env bash
set -Eeo pipefail
HAPROXY_VERSION="v3.2.0"
PCRE2_VERSION="10.47"
OPENSSL_VERSION="3.5.6"
ZLIB_VERSION="v1.3.2"
LUA_VERSION="v5.4.8"
OPENSSL_AWSLC_VERSION="v1.72.0"
USE_OPENSSL_AWSLC="0"
USE_QUIC="0"

while [ $# -gt 0 ]; do
    case "${1:-}" in
        --HAPROXY_VERSION|--haproxy-version)
            HAPROXY_VERSION="$2"
            shift
            ;;
        --PCRE2_VERSION|--pcre2-version)
            PCRE2_VERSION="$2"
            shift
            ;;
        --OPENSSL_VERSION|--openssl-version)
            OPENSSL_VERSION="$2"
            shift
            ;;
        --ZLIB_VERSION|--zlib-version)
            ZLIB_VERSION="$2"
            shift
            ;;
        --LUA_VERSION|--lua-version)
            LUA_VERSION="$2"
            shift
            ;;
        --OPENSSL_AWSLC_VERSION|--openssl-awslc-version)
            OPENSSL_AWSLC_VERSION="$2"
            shift
            ;;
        --USE_OPENSSL_AWSLC)
            USE_OPENSSL_AWSLC="$2"
            shift
            ;;
        --USE_QUIC)
            USE_QUIC="$2"
            shift
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

apk add --no-cache build-base libtool automake autoconf linux-headers git perl cmake readline-dev coreutils musl-dev linux-headers go

rm -rf ${WORK_DIR:?}/*
pushd $WORK_DIR >/dev/null 2>&1 || exit 1
while true; do git clone --recursive --depth 1 -b $ZLIB_VERSION            https://github.com/madler/zlib.git           && break; done
while true; do git clone --recursive --depth 1 -b pcre2-$PCRE2_VERSION     https://github.com/PCRE2Project/pcre2.git    && break; done
while true; do git clone --recursive --depth 1 -b openssl-$OPENSSL_VERSION https://github.com/openssl/openssl.git       && break; done
while true; do git clone --recursive --depth 1 -b $LUA_VERSION             https://github.com/lua/lua.git               && break; done
while true; do git clone --recursive --depth 1 -b $OPENSSL_AWSLC_VERSION   https://github.com/aws/aws-lc.git            && break; done

BASE_VER=${HAPROXY_VERSION#v}
MAJOR_VER=$(echo "$BASE_VER" | cut -d. -f1-2)
HAPROXY_GIT_URL="https://git.haproxy.org/git/haproxy-${MAJOR_VER}.git/"
echo "Targeting haproxy ${HAPROXY_VERSION} Repo: $HAPROXY_GIT_URL"

while true; do git clone --recursive --depth 1 --branch "v$BASE_VER" "$HAPROXY_GIT_URL" "haproxy-$BASE_VER"             && break; done


arch="$(uname -m)"

if [ "${USE_OPENSSL_AWSLC}" = "1" ];then

echo "Building ${arch} aws-lc (Static)..."
pushd aws-lc >/dev/null 2>&1 || exit 1
mkdir build
pushd build >/dev/null 2>&1 || exit 1
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=0 ..
make -j$(nproc)
make install
popd

echo "Building ${arch} aws-lc end"
tree ./build
popd || exit 1

else


echo "Building ${arch} OpenSSL (Static)..."
pushd openssl >/dev/null 2>&1 || exit 1
./config --prefix=$INSTALL_DIR -static
make -j"$(nproc)"
make -j$(nproc) install_sw
echo "Building ${arch} OpenSSL end"
tree ${INSTALL_DIR}
popd || exit 1


fi





echo "Building ${arch} Zlib (Static)..."
pushd zlib >/dev/null 2>&1 || exit 1
./configure --static --prefix=$INSTALL_DIR
make -j$(nproc) install
echo "Building ${arch} Zlib end"
tree ${INSTALL_DIR}
popd || exit 1


echo "Building ${arch} PCRE2 (Static)..."
pushd pcre2 >/dev/null 2>&1 || exit 1
./autogen.sh
./configure --prefix=$INSTALL_DIR --enable-pcre2-8 --enable-jit --disable-shared
make -j$(nproc) install
echo "Building ${arch} PCRE2 end"
tree ${INSTALL_DIR}
popd || exit 1




echo "Building ${arch} lua"
pushd lua >/dev/null 2>&1 || exit 1
make -j"$(nproc)"
echo "Building ${arch} lua end"
tree .
popd || exit 1


echo "Building ${arch} HAProxy (Full Static)..."
pushd "haproxy-$BASE_VER" >/dev/null 2>&1 || exit 1

set -x
if [ "${arch}" = "aarch64" ]; then
    ssl_args="USE_OPENSSL=1 SSL_INC=$INSTALL_DIR/include SSL_LIB=${INSTALL_DIR}/lib"
    ssl_libs="${INSTALL_DIR}/lib/libssl.a ${INSTALL_DIR}/lib/libcrypto.a"
else
    ssl_args="USE_OPENSSL=1 SSL_INC=$INSTALL_DIR/include SSL_LIB=${INSTALL_DIR}/lib64"
    ssl_libs="${INSTALL_DIR}/lib64/libssl.a ${INSTALL_DIR}/lib64/libcrypto.a"
fi

if [ "${USE_OPENSSL_AWSLC}" = "1" ];then
    ssl_args="USE_OPENSSL_AWSLC=1 SSL_INC=$INSTALL_DIR/include SSL_LIB=${INSTALL_DIR}/lib"
    ssl_libs="${INSTALL_DIR}/lib/libssl.a ${INSTALL_DIR}/lib/libcrypto.a"
fi

# USE_LUA=1 LUA_INC=${WORK_DIR}/lua LUA_LIB=${WORK_DIR}/lua
# ${WORK_DIR}/lua/liblua.a

# USE_LUA=1 LUA_INC=${WORK_DIR}/lua LUA_LIB=${WORK_DIR}/lua
# ${WORK_DIR}/lua/liblua.a

lua_args="USE_LUA=1 LUA_INC=${WORK_DIR}/lua LUA_LIB=${WORK_DIR}/lua"
lua_libs="${WORK_DIR}/lua/liblua.a"
if [ "${arch}" = "aarch64" ]; then
    lua_args="";
    lua_libs="";
fi


make -j$(nproc) \
TARGET=linux-musl \
USE_PTHREAD_EMULATION=1 \
USE_GETADDRINFO=1  \
USE_QUIC=1 \
USE_PCRE2_JIT=1 \
USE_PCRE2=1 PCRE2_INC=$INSTALL_DIR/include PCRE2_LIB=$INSTALL_DIR/lib \
${ssl_args} ${lua_args} \
USE_ZLIB=1 ZLIB_INC=$INSTALL_DIR/include ZLIB_LIB=$INSTALL_DIR/lib \
LDFLAGS="-static -no-pie" \
ADDLIB="${ssl_libs} ${lua_libs} ${INSTALL_DIR}/lib/libpcre2-8.a ${INSTALL_DIR}/lib/libz.a -lpthread -ldl" \
CC="gcc -static"
#CFLAGS="-fvect-cost-model=very-cheap"


echo "Verification:"
file ./haproxy
#ldd ./haproxy || true
if ./haproxy -vv; then
  make PREFIX=$INSTALL_DIR install
else
  echo "./haproxy -vv Error, will not install"
fi
set +x
popd || exit 1