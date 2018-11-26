# Swarm on Kubernetes

This document is targeted at developers who want to create a Kubernetes environment with Swarm and Geth applications running on it.

Users of this setup should follow the [USER-GUIDE.md](https://github.com/ethersphere/swarm-kubernetes/blob/master/USER-GUIDE.md)

Note that this setup is currently AWS specific.

## Table of Contents
1.  [Kubernetes service](#kubernetes-service)
2.  [Add Kubernetes Dashboard to cluster](#add-kubernetes-dashboard-to-cluster)
3.  [Bootstrap auxiliary services](#bootstrap-auxiliary-services)
4.  [Ethersphere Helm Charts](#ethersphere-helm-charts)
5.  [Cluster monitoring with Prometheus and Grafana](#cluster-monitoring)


## Kubernetes service

### Terraform EKS playbooks

Terraform playbooks for an AWS EKS (AWS Managed Kubernetes Service) with all related AWS resources (VPC, launch configurations, auto-scaling groups, security groups, etc.)

1. Update values in `backend.tf-sample`, and rename it to `backend.tf`.

2. Update users in `outputs.tf-sample`, and rename it to `outputs.tf`. The sample users `arn:aws:iam::123456789012:user/alice` and `arn:aws:iam::123456789012:user/bob` are added a admin for your Kubernetes environment.

```
  mapUsers: |
    - userarn: arn:aws:iam::123456789012:user/alice
      username: alice
      groups:
        - system:masters
    - userarn: arn:aws:iam::123456789012:user/bob
      username: bob
      groups:
        - system:masters
```

3. Review and update `variables.tf`. Note that this setup is running on AWS spot instances that could be terminated by AWS at any time. You will have to amend the Terraform scripts if you want to run on-demand instances.

4. Initialise Terraform and create the infrastructure. These Terraform EKS templates are heavily influenced by https://github.com/codefresh-io/eks-installer

```
terraform init

terraform plan

terraform apply
```

### Update kubeconfig

```
export CLUSTER_NAME=your-cluster-name

./generate_terraform_outputs.sh

aws eks update-kubeconfig --name $CLUSTER_NAME

kubectl apply -f ./outputs/config-map-aws-auth.yaml
```

## Add Kubernetes Dashboard to cluster

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl apply -f eks-admin-and-cluster-role-binding.yaml

echo "http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/"

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```

## Bootstrap auxiliary services

Run `bootstrap-cluster-services.sh` in order to:

1. Setup storage classes
2. Add local persistence volumes to every i3.large instance in the cluster
3. Install tiller on kube-system to manage system wide components.
4. Install nginx ingress controller
5. Install cert-manager and cert issuers
6. Install logging stack

```
./bootstrapping/bootstrap-cluster-services.sh
```


## Ethersphere Helm Charts

- [geth](https://github.com/ethersphere/helm-charts/tree/master/geth)
- [swarm](https://github.com/ethersphere/helm-charts/tree/master/swarm)
- [swarm-private](https://github.com/ethersphere/helm-charts/tree/master/swarm-private)

### Requirements

You'll need access to a k8s cluster and the following binaries on your system:

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://github.com/helm/helm)

### Using the Helm charts

To be able to use our Helm charts you need to load them from our registry first:

```sh
helm repo add ethersphere-charts https://ethersphere.github.io/helm-charts-artifacts/
helm repo list
```

### Create a namespace and deployer Tiller

Tiller is the server portion of Helm and runs inside your Kubernetes cluster.

We need to create a dedicated k8s namespace and deploy tiller there with proper RBAC
to avoid that Tiller has full controll over our k8s cluster,

This can be done like:

```sh
export NAMESPACE=your-namespace

# Create the namespace
kubectl create namespace $NAMESPACE

# Apply tiller Role Based Access Controlls to your namespace only
kubectl -n $NAMESPACE apply -f tiller.rbac.yaml

# Start tiller in your namespace
helm init --service-account tiller --tiller-namespace $NAMESPACE
```

### Deploy your chart

Check out some examples on how to deploy your charts

```sh

# Deploy the geth chart with default values
helm --tiller-namespace=$NAMESPACE \
     --namespace=$NAMESPACE \
     --name=geth install ethersphere-charts/geth

# Deploy the geth chart by providing your own custom-values.yaml file.
# This will overwrite the default values.
helm --tiller-namespace=$NAMESPACE \
     --namespace=$NAMESPACE \
     --name=geth install ethersphere-charts/geth \
     -f custom-values.yaml

```


## Cluster monitoring with Prometheus and Grafana

Based on https://sysdig.com/blog/kubernetes-monitoring-prometheus-operator-part3/

```
git clone https://github.com/coreos/prometheus-operator.git
git clone https://github.com/mateobur/prometheus-monitoring-guide.git

kubectl create -f prometheus-operator/contrib/kube-prometheus/manifests/
```
