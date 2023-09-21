FROM ubuntu:20.04

ENV PKGCONFIG_PATH=/usr/local/lib/x86_64-linux-gnu/pkgconfig/
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /root
RUN apt-get update && \
    apt-get -y install python3-pip && \
    pip3 install meson && \
    pip3 install meson && \
    pip3 install ninja && \
    pip3 install pyelftools && \
    apt-get -y install libnuma-dev && \
    apt-get -y install libhugetlbfs-dev && \
    apt-get -y install build-essential && \
    apt-get -y install git && \
    git clone https://dpdk.org/git/dpdk dpdk-21.11

WORKDIR /root/dpdk-21.11
RUN git checkout v21.11 && \
    meson build && \
    ninja -C build && \
    ninja -C build install

WORKDIR /root
RUN git clone https://github.com/pktgen/Pktgen-DPDK Pktgen-DPDK-21.11

WORKDIR /root/Pktgen-DPDK-21.11
RUN git checkout pktgen-21.11.0 && \
    apt-get update && \
    apt-get -y install libpcap-dev && \
    apt-get -y install pkg-config && \
    make
