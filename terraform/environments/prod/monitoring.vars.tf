variable "prometheus_storageclass_name" {
  description = "PVC Storage Class"
  type        = string
  default     = ""
}

variable "prometheus_storage_size" {
  type        = string
  description = "PVC Storage Size"
  default     = "10Gi"
}

variable "prometheus_values_file" {
  type        = string
  description = "Path to the values file for the Prometheus Helm chart"
  default     = "prometheus.values.yml"
}


