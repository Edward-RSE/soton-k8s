#!/usr/bin/env bash
set -e

# Adding Helm repositories.
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace headlamp --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Deploy Loki chart
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  -f values/values-loki.yaml

# Deploy promtail chart
helm upgrade --install promtail grafana/promtail \
  --namespace monitoring \
  -f values/values-promtail.yaml

# Deploy Kube-Promethus-Grafana stack for monitoring the cluster
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values/values-prometheus.yaml

# Deploy Headlamp which lets you control the cluster
helm upgrade --install headlamp headlamp/headlamp \
  --namespace headlamp \
  -f values/values-headlamp.yaml

# Deploy certificate manager
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  -f values/values-cert-manager.yaml
