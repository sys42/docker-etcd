#!/bin/bash

VERSION=2.1.2
RUNMODE=""

if [ $# -ne 0 ];then
  if [ "$1" = "intern" ]; then
    RUNMODE=$1
  elif [ "$1" = "extern" ]; then
    RUNMODE=$1
    INTERFACE="eth0"
    PORTMAPPINGS="-p 4001:4001 -p 2380:2380 -p 2379:2379"
  fi
fi

if [ -z "$RUNMODE" ]; then
  echo "USAGE: $0 type"
  echo "  starts docker etcd instance of given type"
  echo
  echo "type: intern ... uses only Docker private net"
  echo "      extern ... binds to host external net"
  exit 1
fi


if [ "$RUNMODE" = "extern" ]; then
  HostIP=$(ifconfig ${INTERFACE} | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')

  echo "[INFO] starting ${RUNMODE}al etcd on IP ${HostIP} ..." 

  docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs ${PORTMAPPINGS} \
   --name etcd sys42/etcd:${VERSION} \
   -name etcd0 \
   -advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001 \
   -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
   -initial-advertise-peer-urls http://${HostIP}:2380 \
   -listen-peer-urls http://0.0.0.0:2380 \
   -initial-cluster-token etcd-cluster-1 \
   -initial-cluster etcd0=http://${HostIP}:2380 \
   -initial-cluster-state new
else
  echo "[INFO] starting ${RUNMODE}al etcd ..." 

  docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs \
   --name etcd sys42/etcd:${VERSION} \
   -name etcd0 \
   -listen-peer-urls http://0.0.0.0:2380 \
   -listen-client-urls http://0.0.0.0:2379 \
   -advertise-client-urls http://0.0.0.0:2379

fi
