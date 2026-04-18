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


```bash
$ readelf -h ./haproxy |grep Type
  Type:                              EXEC (Executable file)


$ readelf -h /usr/sbin/haproxy |grep Type
  Type:                              DYN (Position-Independent Executable file)

```


ET_EXEC 和 ET_DYN 中的 ET_ 是 ELF（Executable and Linkable Format）文件头中的一个字段，称为 e_type。

e_type 字段用于标识 ELF 文件的类型，取值如下：

```bash
ET_NONE（0）：未知类型
ET_REL（1）：可重定位文件（Relocatable file）
ET_EXEC（2）：可执行文件（Executable file）
ET_DYN（3）：动态链接库（Dynamic Shared Object）
ET_CORE（4）：核心文件（Core file）
```

因此，ET_EXEC 表示可执行文件，而 ET_DYN 表示动态链接库。

在 ELF 文件中，e_type 字段是一个 4 字节的整数，用于标识文件的类型。这个字段在 ELF 文件头中，偏移量为 4 字节。

ET_ 前缀是 ELF 文件格式规范中的一个约定，用于表示 e_type 字段的取值。