# haproxy-linux-musl

- [haproxy/wiki/wiki/SSL-Libraries-Support-Status](https://github.com/haproxy/wiki/wiki/SSL-Libraries-Support-Status)
- [git.haproxy.org](https://git.haproxy.org/)

| version     | git url                                                |
| ----------- | ------------------------------------------------------ |
| haproxy-2.8 | <https://git.haproxy.org/?p=haproxy-2.8.git;a=summary> |
| haproxy-2.9 | <https://git.haproxy.org/?p=haproxy-2.9.git;a=summary> |
| haproxy-3.0 | <https://git.haproxy.org/?p=haproxy-3.0.git;a=summary> |
| haproxy-3.1 | <https://git.haproxy.org/?p=haproxy-3.1.git;a=summary> |
| haproxy-3.2 | <https://git.haproxy.org/?p=haproxy-3.2.git;a=summary> |
| haproxy-3.3 | <https://git.haproxy.org/?p=haproxy-3.3.git;a=summary> |


compared with debian `apt install haproxy -y`

```bash

docker rm -f tmp;
docker run -d --name tmp --entrypoint="" dyrnq/haproxy-linux-musl:v3.2.15 sh -c "sleep 1h;"
docker cp tmp:/usr/local/bin/haproxy .
docker rm -f tmp;

scanelf --needed --nobanner --recursive ./haproxy
ET_EXEC  ./haproxy 

scanelf --needed --nobanner --recursive /usr/sbin/haproxy 
ET_DYN libcrypt.so.1,libssl.so.3,libcrypto.so.3,liblua5.4.so.0,libopentracing-c-wrapper.so.0,libpcre2-8.so.0,libjemalloc.so.2,libc.so.6 /usr/sbin/haproxy 
```