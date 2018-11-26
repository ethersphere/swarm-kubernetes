#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# Setup storage classes
kubectl apply -f storage-classes/

# Add local persistence volumes to every i3.large instance in the cluster
temp="$(mktemp)"
kubectl get nodes -l 'beta.kubernetes.io/instance-type in (i3.large)' \
                  -o go-template --template="$(cat pv.gotpl)" > $temp
kubectl apply -f $temp

# Install tiller on kube-system to manage system wide components.
kubectl apply -f tiller-admin-rbac.yaml
helm init --tiller-namespace=kube-system --service-account tiller
kubectl -n kube-system wait --timeout=120s --for condition=ready pod -l app=tiller

# Update information of available charts locally from chart repositories
helm repo update

# Install nginx ingress controller
helm install --namespace=nginx-ingress \
             --name=nginx-ingress stable/nginx-ingress --version=0.29.2 \
             --values helm-values/nginx-ingress.yaml

# Install cert-manager and cert issuers
helm install --namespace kube-system \
             --name cert-manager stable/cert-manager --version=v0.5.0 \
             --values helm-values/cert-manager.yaml
kubectl apply -f cert-manager.clusterissuers.yaml

# Install logging stack
helm repo add akomljen-charts \
    https://raw.githubusercontent.com/komljen/helm-charts/master/charts/

helm install --namespace logging \
             --name es-operator akomljen-charts/elasticsearch-operator --version=0.1.5 \
             --values helm-values/elasticsearch-operator.yaml

kubectl -n logging wait --timeout=120s --for condition=ready pod -l app=elasticsearch-operator

kubectl apply -n logging -f fluent-bit.configmap.yaml
helm install --namespace logging \
             --name efk akomljen-charts/efk --version=0.1.2 \
             --values helm-values/efk.yaml

kubectl -n logging wait --timeout=120s --for condition=ready pod -l role=data,component=elasticsearch-efk-cluster

helm install --namespace logging \
             --name elasticsearch-curator stable/elasticsearch-curator --version=1.0.1 \
             --values helm-values/elasticsearch-curator.yaml


# TODO: Install monitoring stack
