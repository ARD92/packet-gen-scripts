#!/usr/bin/env bash

rm -rf dpdk/vhost-blue-net.sock

pkt_size=$1
pktgen_script="pktgen_${pkt_size}.pkt"
/usr/local/bin/pktgen  -l 5-6 -n 8 --socket-mem 1024 --no-pci --file-prefix=pktgen --vdev=net_virtio_user1,mac=aa:bb:cc:dd:ee:50,path=/dpdk/vhost-blue-net.sock,server=1 --single-file-segments -- -P -m "[6].0" -f $pktgen_script
