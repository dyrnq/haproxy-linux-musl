#!/usr/bin/env bash
set -Eeo pipefail

base_image="${base_image:-}"
version="${version:-v3.2.0}";
push="${push:-false}"
repo="${repo:-dyrnq}"
image_name="${image_name:-haproxy-linux-musl}"
platforms="${platforms:-linux/amd64,linux/arm64/v8}"
curl_opts="${curl_opts:-}"
docker_file=${docker_file:-./Dockerfile}


HAPROXY_VERSION="v3.2.0"
PCRE2_VERSION="10.47"
OPENSSL_VERSION="3.5.6"
ZLIB_VERSION="v1.3.2"
LUA_VERSION="v5.4.8"
OPENSSL_AWSLC_VERSION="v1.72.0"
USE_OPENSSL_AWSLC="0"

while [ $# -gt 0 ]; do
    case "$1" in
        --docker-file)
            docker_file="$2"
            shift
            ;;
        --base-image|--base)
            base_image="$2"
            shift
            ;;
        --version|--ver)
            version="$2"
            shift
            ;;
        --push)
            push="$2"
            shift
            ;;
        --curl-opts)
            curl_opts="$2"
            shift
            ;;
        --platforms)
            platforms="$2"
            shift
            ;;
        --repo)
            repo="$2"
            shift
            ;;
        --image-name|--image)
            image_name="$2"
            shift
            ;;
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
        --OPENSSL_AWSLC_VERSION|--openssl-awslc-version)
            OPENSSL_AWSLC_VERSION="$2"
            ;;
        --USE_OPENSSL_AWSLC)
            USE_OPENSSL_AWSLC="$2"
            ;;
        --*)
            echo "Illegal option $1"
            ;;
    esac
    shift $(( $# > 0 ? 1 : 0 ))
done


latest_tag=" --tag ${repo}/${image_name}:${version}"

if [ "1" = "${USE_OPENSSL_AWSLC}" ]; then
latest_tag=" --tag ${repo}/${image_name}:awslc-${version}"
fi

docker buildx build \
--platform ${platforms} \
--output "type=image,push=${push}" \
--build-arg HAPROXY_VERSION=${HAPROXY_VERSION} \
--build-arg PCRE2_VERSION=${PCRE2_VERSION} \
--build-arg OPENSSL_VERSION=${OPENSSL_VERSION} \
--build-arg ZLIB_VERSION=${ZLIB_VERSION} \
--build-arg LUA_VERSION=${LUA_VERSION} \
--build-arg OPENSSL_AWSLC_VERSION=${OPENSSL_AWSLC_VERSION} \
--build-arg USE_OPENSSL_AWSLC=${USE_OPENSSL_AWSLC} \
--file ${docker_file} . \
${latest_tag}



