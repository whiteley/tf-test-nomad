#!/bin/bash

set -o errexit
set -o nounset
set -o xtrace

if ! grep -q download.docker.com /etc/apt/sources.list; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
fi

apt-get update
apt-get -y install docker-ce jq unzip

PRODUCT=nomad
VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/${PRODUCT} | jq -r .current_version)

if [ ! -f /usr/local/bin/${PRODUCT} ] || [ "$(/usr/local/bin/${PRODUCT} version)" != "${PRODUCT^} v${VERSION}" ]; then
  gpg --list-keys 348FFC4C || gpg --recv-keys 348FFC4C
  pushd /tmp

  for asset in ${PRODUCT}_${VERSION}_linux_amd64.zip ${PRODUCT}_${VERSION}_SHA256SUMS ${PRODUCT}_${VERSION}_SHA256SUMS.sig; do
    wget https://releases.hashicorp.com/${PRODUCT}/${VERSION}/${asset}
  done

  gpg --verify ${PRODUCT}_${VERSION}_SHA256SUMS.sig || exit
  sha256sum --check <(grep _linux_amd64.zip ${PRODUCT}_${VERSION}_SHA256SUMS) || exit


  unzip ${PRODUCT}_${VERSION}_linux_amd64.zip
  for asset in ${PRODUCT}_${VERSION}_linux_amd64.zip ${PRODUCT}_${VERSION}_SHA256SUMS ${PRODUCT}_${VERSION}_SHA256SUMS.sig; do
    rm -fv ${asset}
  done

  install -m 0755 -o root -g root ${PRODUCT} /usr/local/bin/${PRODUCT}
  rm -fv ${PRODUCT}

  popd
fi
