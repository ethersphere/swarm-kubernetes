# Swarm on Kubernetes - User Guide

This document is targeted at developers who want to use a Kubernetes environment documented in the [README.md](https://github.com/ethersphere/swarm-kubernetes/blob/master/README.md)

## Table of Contents
1.  [Requirements](#requirements)
2.  [Configure kubectl](#configure-kubectl)
3.  [Confirm access to K8s cluster](#confirm-access)
4.  [Understand basic K8s/Tiller/Helm concepts](#basic-stuff)
5.  [Deploy sample Swarm](#deploy-sample-swarm)
6.  [Useful commands](#useful-commands)


### Requirements

#### Install aws-cli

https://aws.amazon.com/cli/

#### Setup your AWS Credentials

```
aws configure

export AWS_ACCESS_KEY_ID="xxx"
export AWS_SECRET_ACCESS_KEY="xxx"
```

#### Install aws-iam-authenticator

https://github.com/kubernetes-sigs/aws-iam-authenticator

Make sure you copy the aws-iam-authenticator binary in your PATH.

#### Make sure your AWS user is added to the respective AWS EKS cluster

Ask cluster administrator to apply this to the K8S cluster.

    - userarn: arn:aws:iam::123456789012:user/your-name
      username: your-name
      groups:
        - system:masters

#### Set your default namespace

```
export NAMESPACE=your-namespace
```

#### Install `kubectl` and `helm`

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://github.com/helm/helm)

## Configure kubectl

```
aws eks update-kubeconfig --name your-cluster-name
```

## Confirm access to K8s cluster

```
# list all nodes in the cluster
kubectl get nodes
```

## Understand basic K8s / Tiller / Helm concepts

* kubectl, kube contexts (access to multiple clusters)

* tiller

* helm, charts (helm applications), configurations (values.yaml)

## Ethersphere Helm Charts

- [geth](https://github.com/ethersphere/helm-charts/tree/master/geth)
- [swarm](https://github.com/ethersphere/helm-charts/tree/master/swarm)
- [swarm-private](https://github.com/ethersphere/helm-charts/tree/master/swarm-private)

To be able to use the Ethersphere Helm charts, you need to load them from our registry first:

```sh
helm repo add ethersphere-charts https://ethersphere.github.io/helm-charts-artifacts/
helm repo list
```

## Configure your sample Swarm deployment

```
# your-values.yaml

swarm:
  metricsEnabled: true
  tracingEnabled: false
  profilingEnabled: false
  image:
    repository: ethdevops/swarm
    tag: latest
  replicaCount: 2
  config:
    ens_api: http://mainnet-geth-geth.geth:8545
    verbosity: 3
    debug: true
    maxpeers: 25
    bzznetworkid: 3
    bootnodes: []
  secrets:
    password: qwerty
  persistence:
    enabled: false
  ingress:
    domain: your-domain.com
    enabled: true
    tls:
      acmeEnabled: true
```

## Deploy sample Swarm chart
```sh
export NAMESPACE=your-name

# Create the namespace
kubectl create namespace $NAMESPACE

# Apply tiller Role Based Access Controlls to your namespace only
kubectl -n $NAMESPACE apply -f tiller.rbac.yaml

# Start tiller in your namespace
helm init --service-account tiller --tiller-namespace $NAMESPACE

# Install sample Swarm chart
helm --tiller-namespace=$NAMESPACE \
     --namespace=$NAMESPACE \
     --name=swarm install ethersphere-charts/swarm \
     -f your-values.yaml

# Tear-down Swarm deployment
helm del --purge swarm --tiller-namespace $NAMESPACE

# ... or remove k8s namespace altogether
kubectl delete namespace $NAMESPACE

# Upgrade sample Swarm chart
helm --tiller-namespace=$NAMESPACE \
     --namespace=$NAMESPACE \
     upgrade swarm ethersphere-charts/swarm \
     -f your-values.yaml

# List helm applications
helm list --tiller-namespace $NAMESPACE
```

## Useful commands

```sh
# list all nodes in the cluster
kubectl get nodes

# list all pods in the cluster
kubectl get pods --all-namespaces

# list all pods sorted by node
kubectl get pods -o wide --sort-by="{.spec.nodeName}" --all-namespaces

# list all namespaces
kubectl get namespaces

# attach to a given swarm container and to its javascript console
kubectl exec -n $NAMESPACE -ti swarm-0 -- sh
/geth attach /root/.ethereum/bzzd.ipc

# open Kubernetes dashboard

1. get secret
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

2. run proxy
kubectl proxy

3. open browser
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/


# port forwarding to k8s grafana service (credentials- admin:swarm)
kubectl -n monitoring port-forward service/grafana 3000

# port forwarding to kibana service
kubectl -n logging port-forward service/efk-kibana 8443:443

# port forwarding to access pprof on a swarm pod
kubectl -n your_namespace port-forward swarm-0 6060

# port forwarding to access grafana on a swarm stack
kubectl -n your_namespace port-forward service/swarm-grafana 3001:80
```
