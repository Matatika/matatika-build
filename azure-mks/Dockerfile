FROM microsoft/azure-cli

#
# Install Helm
#
# variable "HELM_VERSION" can be passed as docker environment variables during the image build
# docker build --no-cache --build-arg HELM_VERSION=2.12.0 --build-arg REGISTRY_PASSWORD=[THE TOKEN] -t local/azure-mks .
ARG HELM_VERSION=2.9.1
ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"
RUN apk add --update --no-cache curl ca-certificates && \
    curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64 && \
    apk del curl && \
    rm -f /var/cache/apk/*

#
# Install kubectl
#
ARG KUBE_VERSION="v1.10.0"
RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && rm /var/cache/apk/*

#
# Install docker client
#
RUN apk add --no-cache bash curl git openssh-client
ENV DOCKER_VERSION "17.03.1-ce"
RUN curl -L -o /tmp/docker-$DOCKER_VERSION.tgz https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz \
    && tar -xz -C /tmp -f /tmp/docker-$DOCKER_VERSION.tgz \
    && mv /tmp/docker/docker /usr/local/bin \
    && rm -rf /tmp/docker-$DOCKER_VERSION /tmp/docker

WORKDIR /apps

#
# A simple Dockerfile for a local dev environment to work with Azure
# (az, helm, tiller)
#

ARG REGISTRY_PASSWORD
ARG REGISTRY_CERTIFICATES
ARG REGISTRY_URL
# Check for mandatory build arguments
RUN if { [ -z "$REGISTRY_PASSWORD" ] && [ -z "$REGISTRY_CERTIFICATES" ]; }; then { echo 'Build argument REGISTRY_PASSWORD or REGISTRY_CERTIFICATES needs to be set and non-empty.' > /dev/stderr; exit 1; }; else exit 0; fi;

RUN	apk update && apk add bash git dos2unix
SHELL ["/bin/bash", "-c"]
RUN echo "Europe/London" > /etc/timezone && date

ENV SRC_DIR=/tmp/src
ADD . $SRC_DIR
RUN find $SRC_DIR -regex ".*\.\(sh\)" -type f -print0 | xargs -0 dos2unix
RUN find $SRC_DIR -regex ".*\.\(sh\)" -type f -print0 | xargs -0 chmod a+x

ENV STAGE=dev \
	IMAGE_NAME=matatika-www \
	REGISTRY_NAME=matatika \
	REGISTRY_LOGIN=matatika \
	REGISTRY_PASSWORD=$REGISTRY_PASSWORD \
	REGISTRY_CERTIFICATES=$REGISTRY_CERTIFICATES \
	REGISTRY_URL=$REGISTRY_URL \
	CHART_VERSION=

ENTRYPOINT find ./ -regex ".*\.\(sh\)" -type f -print0 | xargs -0 dos2unix && cat $SRC_DIR/ReadMe.txt && /bin/bash
