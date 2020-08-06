FROM openshift/origin-release:golang-1.13

ENV GOFLAGS="-mod=vendor"

COPY . /go/src/github.com/open-cluster-management/metrics-collector
RUN cd /go/src/github.com/open-cluster-management/metrics-collector && \
    go build ./cmd/telemeter-client && \
    go build ./cmd/telemeter-server && \
    go build ./cmd/authorization-server

#FROM centos:7
FROM registry.access.redhat.com/ubi8/ubi-minimal:8.2

ARG VCS_REF
ARG VCS_URL
ARG IMAGE_NAME
ARG IMAGE_DESCRIPTION
ARG IMAGE_DISPLAY_NAME
ARG IMAGE_NAME_ARCH
ARG IMAGE_MAINTAINER
ARG IMAGE_VENDOR
ARG IMAGE_VERSION
ARG IMAGE_RELEASE
ARG IMAGE_SUMMARY
ARG IMAGE_OPENSHIFT_TAGS

LABEL org.label-schema.vendor="Red Hat" \
      org.label-schema.name="$IMAGE_NAME_ARCH" \
      org.label-schema.description="ACM Metrics collector" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.license="Red Hat Advanced Cluster Management for Kubernetes EULA" \
      org.label-schema.schema-version="1.0" \
      name="metrics-collector" \
      maintainer="smeduri@redhat.com" \
      vendor="Red Hat" \
      version="2.1.0" \
      release="$IMAGE_RELEASE" \
      description="ACM Metrics collector" \
      summary="ACM Metrics collector" \
      io.k8s.display-name="ACM Metrics collector" \
      io.k8s.description="ACM Metrics collector" \
      io.openshift.tags="ACM Metrics collector"

RUN microdnf update &&\
    microdnf install ca-certificates vi --nodocs &&\
    mkdir /licenses &&\
    microdnf clean all

COPY --from=0 /go/src/github.com/open-cluster-management/metrics-collector/telemeter-client /usr/bin/
COPY --from=0 /go/src/github.com/open-cluster-management/metrics-collector/telemeter-server /usr/bin/
COPY --from=0 /go/src/github.com/open-cluster-management/metrics-collector/authorization-server /usr/bin/
