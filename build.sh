SHORTVERSION="2.1.2"

VERSION="v${SHORTVERSION}"
PREFIX="https://github.com/coreos/etcd/releases/download"
DISTRO="etcd-${VERSION}-linux-amd64"
DISTFILE="${DISTRO}.tar.gz"

URL="${PREFIX}/${VERSION}/${DISTFILE}"

set -o pipefail
set -e
#set -x

if [ -f "${DISTFILE}" ]; then
  echo "[INFO] [${URL}] already fetched ..."
else 
  echo "[INFO] fetching [${URL}] ..."
  curl -sL "${URL}" -o "${DISTFILE}"
fi

if [ -d "${DISTRO}" ]; then
  echo "[INFO] [${DISTFILE}] already unpacked ..."
else
  echo "[INFO] unpacking [${DISTFILE}] ..."
  tar xzf "${DISTFILE}"
fi

copyOnDiff () {
  [ ! -d "$1" ] && mkdir "$1" 
  if [ -f "$1/$2" ]; then
     diff "$1/$2" "$3/$4"
     if [ $? -ne 0 ]; then
        echo "[WARN] $1/$2 differs -> copy"
        cp "$3/$4" "$1/$2" 
     else
        echo "[INFO] $1/$2 exists"
     fi
  else  
    echo "[INFO] copying to $1/$2 ..."
    cp "$3/$4" "$1/$2" 
  fi
}

genDockerfile () {
  if [ ! -f "$1/Dockerfile" ]; then
    echo "[INFO] generating $1/Dockerfile ..."
    cat >"$1/Dockerfile" << END_OF_BLOCK
FROM scratch
MAINTAINER Tom Nussbaumer <thomas.nussbaumer@gmx.net>
COPY ./$2 /$2
ENTRYPOINT ["/$2"]
END_OF_BLOCK
  else  
    echo "[INFO] $1/Dockerfile exists"
  fi
}

buildImage () {
  docker build --rm -t sys42/$2:${SHORTVERSION} $1/.
}

copyOnDiff "etcdctl-${VERSION}" "etcdctl"   "${DISTRO}" "etcdctl"
copyOnDiff "etcdctl-${VERSION}" "README.md" "${DISTRO}" "README-etcdctl.md"
copyOnDiff "etcd-${VERSION}"    "etcd"      "${DISTRO}" "etcd"
copyOnDiff "etcd-${VERSION}"    "README.md" "${DISTRO}" "README.md"

genDockerfile "etcdctl-${VERSION}" "etcdctl" 
genDockerfile "etcd-${VERSION}"    "etcd"

rm ${DISTFILE}
rm -rf ${DISTRO}

buildImage "etcdctl-${VERSION}" "etcdctl" 
buildImage "etcd-${VERSION}"    "etcd"

docker images | head -1
docker images | grep "sys42/etcd"

