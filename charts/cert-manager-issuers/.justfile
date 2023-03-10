chart_name := file_name(justfile_directory())
container_registry := "ghcr.io"

exec := "just _xtrace"

[private]
default:
    @just --list

# ----------------------------------------------------------------------------------------------------------------------
# ----------- BUILD -----------

# build out all "runtime" resources related to the current application (images, charts)
[no-exit-message]
build: build-images build-chart

# build out all "external" resources related to the current application (charts, README, ...)
[no-exit-message]
build-external: build-validation-files build-readme

# build one or multiple images (use relative path from current directory)
[no-exit-message]
build-images +IMAGES="all":

# build out the charts/ directory from the Chart.lock file
[no-exit-message]
@build-chart:
  {{exec}} helm dependency build

# generates all resources managed by this chart application to quickly see any changes
[no-exit-message]
build-validation-files:
  #!/usr/bin/env bash
  {{exec}} rm --recursive --force ~develop/validation/compiled
  for value in ~develop/validation/values/*; do
    {{exec}} helm template {{ chart_name }} . --create-namespace --namespace {{ chart_name }}-validation \
      --values "${value}" \
      --output-dir "~develop/validation/compiled/$(basename "${value}" | cut -d'-' -f1)"
  done

# generates markdown documentation from requirements and values files
[no-exit-message]
@build-readme:
  {{exec}} helm-docs --badge-style flat


# ----------------------------------------------------------------------------------------------------------------------
# ------------ LINT ------------

# lint all "runtime" resources related to the current application (images, charts)
[no-exit-message]
lint: lint-images lint-chart

# lint one or multiple images (use relative path from current directory)
[no-exit-message]
lint-images +IMAGES="all":

# runs a series of tests to verify that the chart is well-formed
[no-exit-message]
@lint-chart:
  {{exec}} ct lint --charts "${PWD}"


# ----------------------------------------------------------------------------------------------------------------------
# --------- E2E TESTS ---------

# install and test the current application into a local cluster
[no-exit-message]
e2e-run: e2e-setup e2e-prepare && e2e-teardown
  ct install --charts ${PWD} --target-branch main --upgrade --debug \
    --helm-extra-args '--timeout 120s' \
    --helm-extra-set-args '--set "global.imageRegistry={{ container_registry }}"'

# prepare the local environment to run e2e tests locally
[private]
[no-exit-message]
e2e-setup CLUSTER_NAME=chart_name: build-images
  #!/usr/bin/env bash
  if ! (kind get clusters 2> /dev/null | grep "^{{ CLUSTER_NAME }}$" &> /dev/null); then
    {{exec}} kind create cluster --name {{ CLUSTER_NAME }} --wait 120s
  fi

# install all required resources to install and run the application properly
[private]
[no-exit-message]
e2e-prepare CLUSTER_NAME=chart_name:
  #!/usr/bin/env bash
  {{exec}} helm repo update
  {{exec}} helm upgrade --install cert-manager jetstack/cert-manager --create-namespace --namespace cert-manager-system --set installCRDs=true

# remove the local environment to run e2e tests locally
[private]
[no-exit-message]
@e2e-teardown CLUSTER_NAME=chart_name:
  {{exec}} kind delete cluster --name {{ CLUSTER_NAME }}


# ----------------------------------------------------------------------------------------------------------------------
# ----- LOCAL DEVELOPMENT -----

# prepare a local environment to develop and/or debug the application
[no-exit-message]
develop +OPTS="": build-images && (e2e-prepare (chart_name + "-dev")) (develop-install OPTS)
  #!/usr/bin/env bash
  if ! (kind get clusters 2> /dev/null | grep "^{{ (chart_name + "-dev") }}$" &> /dev/null); then
    {{exec}} kind create cluster --name {{ (chart_name + "-dev") }} --wait 120s --config ~develop/environment/kind.yaml
  fi
  {{exec}} kubectl apply --filename https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml --wait
  kubectl patch --namespace kube-system deployment/metrics-server --type json --patch '[{"op":"add","path":"/spec/template/spec/containers/0/args/5","value":"--kubelet-insecure-tls"}]'
  kubectl wait --namespace kube-system deployment/metrics-server --for=condition=Available
  {{exec}} helm upgrade --install contour bitnami/contour --namespace projectcontour --create-namespace

# install the application on the local environment
[no-exit-message]
develop-install +OPTS="":
  #!/usr/bin/env bash
  {{exec}} helm upgrade {{ chart_name }}-dev . \
    --install \
    --namespace {{ chart_name }} --create-namespace \
    --values ~develop/environment/values.yaml \
    --set "containerSecurityContext.runAsUser=$(id --user)" --set "containerSecurityContext.runAsGroup=$(id --group)" \
    --set "podSecurityContext.runAsUser=$(id --user)" --set "podSecurityContext.runAsGroup=$(id --group)" \
    --set "global.imageRegistry={{ container_registry }}" \
     {{ OPTS }}

# reinstall the application on the local environment
[no-exit-message]
develop-reinstall +OPTS="": && (develop-install OPTS)
  helm uninstall {{ chart_name }}-dev --namespace {{ chart_name }}

# stop the local environment
[no-exit-message]
develop-teardown: (e2e-teardown (chart_name + "-dev"))


# ----------------------------------------------------------------------------------------------------------------------
# ----- SECURITY ANALYSIS -----

# scan images and chart for missconfiguration or security issues
[no-exit-message]
security-scan OPTS="": (security-scan-images OPTS) (security-scan-chart OPTS)

# scan one or multiple images for missconfiguration or security issues
[no-exit-message]
security-scan-images OPTS="" +IMAGES="all":

# scan current chart for missconfiguration or security issues
[no-exit-message]
@security-scan-chart OPTS="":
  {{ exec }} trivy config . {{ OPTS }}


# ----------------------------------------------------------------------------------------------------------------------
# ------ TOOLS & LIBRARY ------

# rebuild all "external" files (or files used for CI validation and packaging)
# and commit them automatically.
[no-exit-message]
git-commit-package +OPTS="": build-external
  git add ~develop/validation/ README.md
  git commit --message ":package: (apps/{{ chart_name }}): rebuild all packaging files" {{ OPTS }}

# (lib only) print a trace of simple commands then run it. If it runs inside
#            Github Actions, it will also group all outputs inside a block to
#            simplify CI logs.
[private]
[no-exit-message]
@_xtrace +CMD:
  {{ if env_var_or_default("GITHUB_ACTIONS", "false") =~ '[Tt]rue' { "just _xtrace_github_action " + CMD } else { "just _xtrace_default " + CMD } }}

[private]
[no-exit-message]
@_xtrace_default +CMD:
  @{{CMD}}

[private]
[no-exit-message]
@_xtrace_github_action +CMD:
  echo '::group::{{CMD}}'
  {{CMD}}
  echo '::endgroup::'
