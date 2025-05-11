resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name
  node_resource_group = var.node_resource_group

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "systempool"
    vm_size    = "Standard_B2s"
    node_count = var.system_node_count
  }
  
  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "kubenet" # azure (CNI)
  }
  lifecycle {
    ignore_changes = all
  }
}



data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_resource_group.rg.name
}

data "azurerm_resource_group" "node_rg" {
  name = data.azurerm_kubernetes_cluster.aks.node_resource_group
}
resource "azurerm_public_ip" "nginx_ip" {
  name                = "nginx-ingress-ip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.node_rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
  depends_on = [azurerm_kubernetes_cluster.aks]
  lifecycle {
    ignore_changes = all
  }
}
resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "v4.12.1"
  recreate_pods = true
  dependency_update = true
  cleanup_on_fail = true
  
  
  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.nginx_ip.ip_address
  }
  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }
  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }
  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }
  
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_public_ip.nginx_ip
  ]
  lifecycle {
    ignore_changes = all
  }
}


resource "azurerm_mysql_flexible_server" "mysql_server" {
  name                   = "mysql-flexible-server-1"
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  administrator_login    = "squaduser"
  administrator_password = "squadpass123!" # Make sure to store this securely
  version                = "5.7"
  
  sku_name = "B_Standard_B1ms"  # Adjust to your needs

  storage {
    size_gb = 20
  }
  

  tags = {
    environment = "production"
  }
}
# Allow Azure IPs to connect to MySQL
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure_ips" {
  name                = "AllowAllAzureIPs"
  server_name         = azurerm_mysql_flexible_server.mysql_server.name
  resource_group_name = azurerm_resource_group.rg.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# Azure MySQL Flexible Server Database
resource "azurerm_mysql_flexible_database" "db" {
  name                = "squadmaster"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql_server.name
  collation           = "utf8_general_ci"
  charset             = "utf8"
}

# Kubernetes Secret for MySQL credentials
resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name      = "mysql-credentials"
    namespace = "app"
  }

  data = {
    username = base64encode("squaduser")
    password = base64encode("squadpass123!")
    host     = base64encode(azurerm_mysql_flexible_server.mysql_server.fqdn)
    database = base64encode("squadmaster")
  }

  type = "Opaque"
}

# Output MySQL Connection String
output "mysql_connection_string" {
  value = "mysql://squaduser:squadpass123!@${azurerm_mysql_flexible_server.mysql_server.fqdn}:3306/squadmaster"
}