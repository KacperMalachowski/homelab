variable "grafana_storageclass_name" {
  description = "PVC Storage Class for Grafana"
  type        = string
  default     = ""
}

variable "grafana_enable_persistence" {
  description = "Enable persistence for Grafana"
  type        = bool
  default     = false
}

variable "grafana_storage_size" {
  type        = string
  description = "PVC Storage Size for Grafana"
  default     = "10Gi"
}

variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana"
  default     = "admin"
  sensitive   = true
}

variable "grafana_values_file" {
  type        = string
  description = "Path to the values file for Grafana Helm chart"
  default     = "grafana.values.yaml"
}
