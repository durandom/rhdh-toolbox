# https://github.com/containers/toolbox/blob/main/images/fedora/f39/Containerfile
# https://registry.access.redhat.com/ubi9/nodejs-22
# FROM registry.access.redhat.com/ubi9/nodejs-22:9.5-1746535891
FROM registry.fedoraproject.org/fedora-toolbox:43

ARG NAME=rhdh-toolbox
ARG VERSION=0.1
LABEL com.github.containers.toolbox="true" \
      name="$NAME" \
      version="$VERSION" \
      usage="This image is meant to be used with the toolbox(1) command" \
      summary="Image for working with Red Hat Developer Hub"

USER 0

RUN dnf install -q -y --allowerasing --nobest \
  nodejs-devel nodejs-libs \
  # already installed or installed as deps:
  openssl openssl-devel ca-certificates make cmake cpp gcc gcc-c++ zlib zlib-devel brotli brotli-devel python3 nodejs-packaging && \
  dnf update -y && dnf clean all

RUN npm install -g @janus-idp/cli@latest

ENTRYPOINT [ "/bin/bash" ]

