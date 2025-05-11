variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which the Kubernetes cluster will be created."
  default     = "pfe-rg"
}

variable "location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be created."
  default     = "eastus2"
}

variable "system_node_count" {
  type        = number
  description = "The initial quantity of nodes for the system node pool."
  default     = 1
}

variable "min_user_node_count" {
  type        = number
  description = "The minimum quantity of nodes for the user node pool."
  default     = 1
}

variable "max_user_node_count" {
  type        = number
  description = "The maximum quantity of nodes for the user node pool."
  default     = 1
}

variable "cluster_name" {
  type        = string
  description = "AKS name in Azure"
  default     = "aks-cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.31.7" # Use a supported Kubernetes version in Azure AKS. Check the latest.
}



variable "node_resource_group" {
  type        = string
  description = "RG name for cluster resources in Azure"
  default = "aks-nodepool-rg"
}

variable "cloudflare_api_key" {
  type      = string
  sensitive = true
  default   = "1f11449a5f30ef175592e7d02471e2ac9618e"
}


