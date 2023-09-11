#!/bin/sh
echo
echo "It typically takes between 1m and 2m to get Argo Workflows ready."
echo
echo "Any problems? Visit the repo to open an issue: https://github.com/csantanapr/argo-workflows-intro-course/"
echo


echo "1. Installing Argo Workflows..."

ARGO_WORKFLOWS_VERSION='v3.4.11'

kubectl create ns argo > /dev/null
kubectl config set-context --current --namespace=argo > /dev/null
kubectl apply -f https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/install.yaml > /dev/null
kubectl apply -f https://raw.githubusercontent.com/csantanapr/argo-workflows-intro-course/master/config/minio/minio.yaml  > /dev/null
kubectl apply -f https://raw.githubusercontent.com/csantanapr/argo-workflows-intro-course/master/config/argo-workflows/canary-workflow.yaml > /dev/null
kubectl apply -f https://raw.githubusercontent.com/csantanapr/argo-workflows-intro-course/master/config/argo-workflows/patchpod.yaml > /dev/null
kubectl apply -f https://raw.githubusercontent.com/csantanapr/argo-workflows-intro-course/master/config/argo-workflows/workflows-controller-configmap.yaml > /dev/null

uname_m=$(uname -m)
if [ "${uname_m}" == "amd64" ]; then
  echo "2. Installing Argo CLI..."
  curl -sLO https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/argo-linux-amd64.gz
  gunzip argo-linux-amd64.gz
  chmod +x argo-linux-amd64
  sudo mv ./argo-linux-amd64 /usr/local/bin/argo
fi

echo "3. Starting Argo Server..."

if [ "${AUTHCLIENT:-0}" -eq 1 ]; then
  echo "Setting Argo Server to Client Auth..."
  kubectl patch deployment \
    argo-server \
    --namespace argo \
    --type='json' \
    -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
    "server",
    "--auth-mode=client",
    "--secure=false"
  ]},
  {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/scheme", "value": "HTTP"},
  {"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [
    { "name": "FIRST_TIME_USER_MODAL", "value": "false" },
    { "name": "FEEDBACK_MODAL", "value": "false" },
    { "name": "NEW_VERSION_MODAL", "value": "false" }
  ]}
  ]' > /dev/null

else
  echo "Setting Argo Server to Server Auth..."
  # To reduce confusion when following the courses, we suppress the modals.
  kubectl patch deployment \
    argo-server \
    --namespace argo \
    --type='json' \
    -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
    "server",
    "--auth-mode=server",
    "--secure=false"
  ]},
  {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/scheme", "value": "HTTP"},
  {"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [
    { "name": "FIRST_TIME_USER_MODAL", "value": "false" },
    { "name": "FEEDBACK_MODAL", "value": "false" },
    { "name": "NEW_VERSION_MODAL", "value": "false" }
  ]}
  ]' > /dev/null

kubectl wait deploy/argo-server --for condition=Available --timeout 2m > /dev/null
fi

echo "4. Waiting for the Workflow Controller to be available..."
kubectl rollout restart deployment workflow-controller  > /dev/null
kubectl wait deploy/workflow-controller --for condition=Available --timeout 2m > /dev/null


echo "5. Copy Argo Workflow template examples"
temp_dir=$(mktemp -u)
git clone -q --depth 1 https://github.com/argoproj/argo-workflows $temp_dir
mkdir -p /eks-workshop/manifests/modules/automation/workflows/argo/examples
cp -R $temp_dir/examples/* /eks-workshop/manifests/modules/automation/workflows/argo/examples/ > /dev/null


echo "6. Updating manifests and installing sync-worskshop.sh"
curl -s -L https://raw.githubusercontent.com/csantanapr/argo-workflows-intro-course/master/argo-workflows/sync-workshop.sh | bash

echo
echo "Ready"
