# haproxy-linux-musl

- [haproxy/wiki/wiki/SSL-Libraries-Support-Status](https://github.com/haproxy/wiki/wiki/SSL-Libraries-Support-Status)
- [git.haproxy.org](https://git.haproxy.org/)

| version     | git url                                                | docker-library/haproxy Dockerfile                                                                            |
| ----------- | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| haproxy-2.8 | <https://git.haproxy.org/?p=haproxy-2.8.git;a=summary> | [2.8/alpine/Dockerfile](https://github.com/docker-library/haproxy/blob/master/2.8/alpine/Dockerfile) |
| haproxy-2.9 | <https://git.haproxy.org/?p=haproxy-2.9.git;a=summary> |                                                                                                      |
| haproxy-3.0 | <https://git.haproxy.org/?p=haproxy-3.0.git;a=summary> | [3.0/alpine/Dockerfile](https://github.com/docker-library/haproxy/blob/master/3.0/alpine/Dockerfile) |
| haproxy-3.1 | <https://git.haproxy.org/?p=haproxy-3.1.git;a=summary> | [3.1/alpine/Dockerfile](https://github.com/docker-library/haproxy/blob/master/3.1/alpine/Dockerfile) |
| haproxy-3.2 | <https://git.haproxy.org/?p=haproxy-3.2.git;a=summary> | [3.2/alpine/Dockerfile](https://github.com/docker-library/haproxy/blob/master/3.2/alpine/Dockerfile) |
| haproxy-3.3 | <https://git.haproxy.org/?p=haproxy-3.3.git;a=summary> | [3.3/alpine/Dockerfile](https://github.com/docker-library/haproxy/blob/master/3.3/alpine/Dockerfile) |

compared with debian `apt install haproxy -y`

```bash

docker rm -f tmp;
docker run -d --name tmp --entrypoint="" dyrnq/haproxy-linux-musl:v3.2.15 sh -c "sleep 1h;"
docker cp tmp:/usr/local/bin/haproxy .
docker rm -f tmp;

$ scanelf --needed --nobanner --recursive ./haproxy
ET_EXEC  ./haproxy

$ scanelf --needed --nobanner --recursive /usr/sbin/haproxy
ET_DYN libcrypt.so.1,libssl.so.3,libcrypto.so.3,liblua5.4.so.0,libopentracing-c-wrapper.so.0,libpcre2-8.so.0,libjemalloc.so.2,libc.so.6 /usr/sbin/haproxy

$ scanelf --needed --nobanner --recursive /lib/x86_64-linux-gnu/libssl3.so
ET_DYN libnss3.so,libnssutil3.so,libplc4.so,libnspr4.so,libc.so.6 /lib/x86_64-linux-gnu/libssl3.so
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


```bash
$ readelf -h ./haproxy |grep Type
  Type:                              EXEC (Executable file)


$ readelf -h /usr/sbin/haproxy |grep Type
  Type:                              DYN (Position-Independent Executable file)

$ readelf -h /lib/x86_64-linux-gnu/libssl3.so |grep Type
  Type:                              DYN (Shared object file)

```


`readelf` 可以更加细化的区分出`DYN (Position-Independent Executable file)`和 `DYN (Shared object file)`


`file-extension-magic-numbers`

- [File Signature Table](https://filesig.search.org/)
- [List_of_file_signatures List_of_file_signatures](https://en.wikipedia.org/wiki/List_of_file_signatures)



在 GCC 编译器中，`Position-Independent`（位置无关）和 `-no-pie` 选项直接关系到程序的**内存布局**和**安全性**。

`什么是 Position-Independent Code (PIC) 与 PIE？`

- **PIC (Position-Independent Code)**：这是一项**技术**。它指的是代码中所有对数据或函数的引用都使用**相对地址（Relative Addressing）**，而不是绝对内存地址。这使得一段代码无论被操作系统加载到内存的哪个位置，都能正常执行。

- **PIE (Position-Independent Executable)**：这是一个**结果**。当PIC 技术应用到整个可执行程序（即不仅是库，而是程序本身）时，生成的二进制文件就是 PIE。

PIE 的存在主要是为了支持 **ASLR (地址空间布局随机化)**。

- **非 PIE (Traditional)**：程序总是被加载到固定的内存地址（例如 `0x400000`）。攻击者如果想通过“缓冲区溢出”跳转到程序的函数，他不需要猜测，因为地址是死的。

- **PIE (Modern)**：程序每次启动时，操作系统都会随机分配一个新的基地址。攻击者根本不知道函数或代码段到底在哪里，从而大大提高了攻击难度。
