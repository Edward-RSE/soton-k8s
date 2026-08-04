# Soton K8s

This repository contains scripts used to deploy various management services
to the Kubernetes cluster used by the Southampton Research Software Group.

## Services

The deployment script installs the following services via Helm:

- GPU Operator - provides NVIDIA GPU support for the Kubernetes cluster
- Longhorn - provides distributed storage for persistent volumes
- Loki - centralised log aggregation backend
- Promtail - log collector for shipping logs to Loki
- kube-prometheus-stack - monitoring stack with Prometheus, Grafana, and Alertmanager
- NVIDIA GPU exporter - exposes GPU metrics for Prometheus
- Prometheus Blackbox Exporter - probes endpoints and exports availability metrics
- OpenTelemetry Collector - collects and exports telemetry data
- Headlamp - Kubernetes dashboard and cluster management UI
- cert-manager - manages TLS certificates and issuers
