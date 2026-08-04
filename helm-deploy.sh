#!/usr/bin/env bash
set -e

# Adding Helm repositories.
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
helm repo add jetstack https://charts.jetstack.io
helm repo add longhorn https://charts.longhorn.io
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo add nvidia-gpu-exporter https://utkuozdemir.github.io/nvidia_gpu_exporter
helm repo update

# Create namespaces for deployments
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace headlamp --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gpu-operator --dry-run=client -o yaml | kubectl apply -f -

# Deploy the NVIDIA GPU operator which seems to be the most reliable way
# to get GPUs detected by K3s
helm install --wait --generate-name \
    --namespace gpu-operator \
    nvidia/gpu-operator \
    --version=v26.3.3


# Deploy Longhorn, used for storage
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  -f values/values-longhorn.yaml

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

# Deploy NVIDIA GPU exporter for prometheus
helm upgrade --install nvidia-gpu-exporter nvidia-gpu-exporter/nvidia-gpu-exporter \
  --namespace monitoring \
  --set runtimeClassName=nvidia \
  --set computeApps.enabled=true \
  --set hostPID=true \
  --set serviceMonitor.enabled=true

# Deploy blackbox, which is an exporter for prometheus
helm upgrade --install blackbox-exporter prometheus-community/prometheus-blackbox-exporter \
  --namespace monitoring \
  --set serviceMonitor.enabled=true

# Deploy an OpenTelemetry collector we can use for Prometheus
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  -f values/values-otel.yaml

# Deploy Headlamp which lets you control the cluster
helm upgrade --install headlamp headlamp/headlamp \
  --namespace headlamp \
  -f values/values-headlamp.yaml

# Deploy certificate manager
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  -f values/values-cert-manager.yaml

