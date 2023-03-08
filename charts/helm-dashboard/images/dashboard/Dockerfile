FROM docker.io/library/golang:1.20.0 as builder

# renovate: datasource=github-release depName=komodorio/helm-dashboard versioning=semver
ARG HELM_DASHBOARD_VERSION=v1.0.0

WORKDIR /build
RUN git clone https://github.com/komodorio/helm-dashboard --branch ${HELM_DASHBOARD_VERSION}

WORKDIR /build/helm-dashboard
RUN CGO_ENABLED=0 go build \
    -ldflags "-X main.version=${HELM_DASHBOARD_VERSION} -X main.date=$(date --iso-8601=ns) -X main.commit=$(git rev-parse HEAD)" \
    -o ../dashboard .

FROM docker.io/alpine/helm:3.11.1 as helm_packager
FROM docker.io/bitnami/kubectl:1.26.2 as kubectl_packager
FROM docker.io/aquasec/trivy:0.38.2 as trivy_packager

FROM docker.io/alpine:3.17.2

# renovate: datasource=docker depName=komodorio/helm-dashboard versioning=semver
ARG HELM_DASHBOARD_VERSION=1.0.0

RUN apk upgrade --no-cache
COPY --from=builder /build/dashboard /bin/helm-dashboard
COPY --from=helm_packager /usr/bin/helm /bin/helm
COPY --from=kubectl_packager /opt/bitnami/kubectl/bin/kubectl /bin/kubectl
COPY --from=trivy_packager /usr/local/bin/trivy /bin/trivy

USER 65533

EXPOSE 8080
ENTRYPOINT ["/bin/helm-dashboard", "--no-browser", "--bind=0.0.0.0"]

LABEL org.opencontainers.image.authors="Belug-Apps <xunleii@users.noreply.github.com>"
LABEL org.opencontainers.image.created="01/01/1970T00:00:00.000"
LABEL org.opencontainers.image.description="The missing UI for Helm - visualize your releases."
LABEL org.opencontainers.image.documentation=""
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.revision=""
LABEL org.opencontainers.image.source=""
LABEL org.opencontainers.image.title="helm-dashboard"
LABEL org.opencontainers.image.url="https://github.com/belug-apps/catalog"
LABEL org.opencontainers.image.version=${HELM_DASHBOARD_VERSION}

LABEL com.github.belug-apps.ci.workflow.url=""
LABEL com.github.belug-apps.origin.authors="komodor <komodor.io>"
LABEL com.github.belug-apps.origin.licenses="Apache-2.0"
LABEL com.github.belug-apps.origin.source="https://github.com/komodorio/helm-dashboard"
