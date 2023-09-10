#!/bin/bash

branch="argo"

set -Eeuo pipefail

mkdir -p $HOME/bin
echo "curl -s -L https://raw.githubusercontent.com/csantanapr/argo-workflows-intro-course/master/argo-workflows/sync-workshop.sh | bash" > $HOME/bin/sync-workshop.sh
chmod +x $HOME/bin/sync-workshop.sh

temp_dir=$(mktemp -u)

git clone --depth 1 -b "$branch" https://github.com/csantanapr/eks-workshop-v2 $temp_dir

cp -R $temp_dir/manifests/* /eks-workshop/manifests/



