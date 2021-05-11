#!/bin/bash -x
project="konductor-$(hostname)"
docker rm --force konductor 2>/dev/null
docker run -d --rm --privileged \
    --workdir /root/cloudctl \
    -v $(pwd):/root/cloudctl:z \
    --publish 0.0.0.0:8088:8080 \
    --publish 0.0.0.0:2222:2222 \
    -v ${HOME}/.aws:/root/.aws:z \
    -v ${HOME}/.kube:/root/.kube:z \
    -u $(id -u):$(id -g) --user root \
    --name "konductor" -h "konductor" \
    --pull always -v $(pwd)/.ssh:/root/.ssh \
  quay.io/cloudctl/konductor:code
