#!/usr/bin/env bash
set -e

# Adding Helm repositories.
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy Loki chart with Promtail enabled as a sub-chart
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --set promtail.enabled=true \
  -f values/values-loki.yaml

# Deploy Kube-Promethus-Grafana stack for monitoring the cluster
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f values/values-prometheus.yaml
