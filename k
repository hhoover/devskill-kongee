#!/bin/bash -x
project="konductor-$(hostname)"
docker rm --force konductor 2>/dev/null
docker run -d --rm --privileged \
    --workdir /root/cloudctl \
    -v $(pwd):/root/cloudctl:z \
    -v ${HOME}/.kube:/root/.kube:z \
    -u $(id -u):$(id -g) --user root \
    --name "konductor" -h "konductor" \
    --pull always -v $(pwd)/.ssh:/root/.ssh \
  quay.io/cloudctl/konductor:latest
