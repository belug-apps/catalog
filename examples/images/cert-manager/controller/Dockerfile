# renovate: datasource=github-releases depName=cert-manager/cert-manager
ARG JETSTACK_CERTMANAGER_VERSION=v1.11.0
FROM quay.io/jetstack/cert-manager-controller:${JETSTACK_CERTMANAGER_VERSION}

LABEL org.opencontainers.image.authors="Belug-Apps <xunleii@users.noreply.github.com>"
LABEL org.opencontainers.image.created="01/01/1970T00:00:00.000"
LABEL org.opencontainers.image.description="cert-manager is a Kubernetes addon to automate the management and issuance of TLS certificates from various issuing sources."
LABEL org.opencontainers.image.documentation=""
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.revision=""
LABEL org.opencontainers.image.source=""
LABEL org.opencontainers.image.title="cert-manager"
LABEL org.opencontainers.image.url="https://github.com/belug-apps/catalog"
LABEL org.opencontainers.image.version=$JETSTACK_CERTMANAGER_VERSION

LABEL com.github.belug-apps.ci.workflow.url=""
LABEL com.github.belug-apps.origin.authors="JetStack <www.jetstack.io> & cert-manager community <cert-manager.io>"
LABEL com.github.belug-apps.origin.licenses="Apache-2.0"
LABEL com.github.belug-apps.origin.source="https://github.com/cert-manager/cert-manager/blob/master/hack/containers/Containerfile.controller"

USER 1000
