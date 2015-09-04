#!/bin/bash
VERSION=2.1.2
ETCDIP=$(./etcd-addr.sh)

PEERS="http://$ETCDIP:4001,http://$ETCDIP:2379,http://$ETCDIP:2380"

echo "PEERS=[$PEERS]"

docker run -ti --rm sys42/etcdctl:${VERSION} --peers $PEERS "$@"

