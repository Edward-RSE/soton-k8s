# Monitoring

To monitor metrics on the cluster, we have added the Kube-Prometheus-Grafana stack, with additional services such as log
aggregation with Loki.

- Prometheus: monitoring system and time series database - used to capture the metrics
- Grafana: observability platform, used to log metrics and display metric dashboards
- Loki: log aggregation system for Prometheus and Grafana

## Monitoring of vLLM and the K3s cluster

To monitor the status of both the K3s cluster and the metrics of the vLLM servers, we use the kube-prometheus stack with a Grafana dashboard. This can be deployed using a script in monitoring directory,

cd kubernetes/monitoring && ./helm-deploy.sh

To enable monitoring the metrics API endpoints of the vLLM servers, we need to configure a K8s Service Monitor:

cd kubernetes/monitoring && kubectl apply -f service-monitor-vllm.yaml

This Service Monitor will target any service with the label app: vllm and create a Grafana dashboard showing metrics such as the token throughput and E2E latency. If there is no vLLM dashboard, you will need to import it manually using the pre-made JSON template.

The dashboard has been configured to be accessible at <http://dashboard.sotongpt.soton.ac.uk>.
