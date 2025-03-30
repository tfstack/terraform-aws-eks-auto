output "prometheus_server_port_forward" {
  value       = "kubectl --namespace prometheus port-forward $(kubectl get pods -n prometheus -l app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus -o jsonpath=\"{.items[0].metadata.name}\") 9090"
  description = "Port-forward to access the Prometheus server UI at http://localhost:9090"
}

output "prometheus_alertmanager_port_forward" {
  value       = "kubectl --namespace prometheus port-forward $(kubectl get pods -n prometheus -l app.kubernetes.io/name=alertmanager,app.kubernetes.io/instance=prometheus -o jsonpath=\"{.items[0].metadata.name}\") 9093"
  description = "Port-forward to access the Prometheus Alertmanager UI at http://localhost:9093"
}

output "prometheus_pushgateway_port_forward" {
  value       = "kubectl --namespace prometheus port-forward $(kubectl get pods -n prometheus -l app.kubernetes.io/name=prometheus-pushgateway,app.kubernetes.io/instance=prometheus -o jsonpath=\"{.items[0].metadata.name}\") 9091"
  description = "Port-forward to access the Prometheus PushGateway at http://localhost:9091"
}

output "prometheus_node_exporter_port_forward" {
  value       = "kubectl --namespace prometheus port-forward $(kubectl get pods -n prometheus -l app.kubernetes.io/name=prometheus-node-exporter,app.kubernetes.io/instance=prometheus -o jsonpath=\"{.items[0].metadata.name}\") 9100"
  description = "Port-forward to access node exporter metrics at http://localhost:9100/metrics"
}
