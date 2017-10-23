resource "azurerm_public_ip" "kube_api" {
  name                         = "kubernetes_api"
  location                     = "${azurerm_resource_group.ket.location}"
  resource_group_name          = "${azurerm_resource_group.ket.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "kubernetes-api"
}

resource "azurerm_lb" "kubernetes" {
  name                = "kubernetes-api"
  location                     = "${azurerm_resource_group.ket.location}"
  resource_group_name          = "${azurerm_resource_group.ket.name}"

  frontend_ip_configuration {
    name                          = "api"
    public_ip_address_id          = "${azurerm_public_ip.kube_api.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_rule" "kubeapi" {
  name                    = "kubeapi-6443"
  resource_group_name     = "${azurerm_resource_group.ket.name}"
  loadbalancer_id         = "${azurerm_lb.kubernetes.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.kubeapi.id}"
  probe_id                = "${azurerm_lb_probe.kubeapi.id}"

  protocol                       = "tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  frontend_ip_configuration_name = "api"
}

resource "azurerm_lb_probe" "kubeapi" {
  name                = "api-6443"
  resource_group_name = "${azurerm_resource_group.ket.name}"
  loadbalancer_id     = "${azurerm_lb.kubernetes.id}"
  protocol            = "tcp"
  port                = 6443
}

resource "azurerm_lb_backend_address_pool" "kubeapi" {
  name                = "api-lb-pool"
  resource_group_name = "${azurerm_resource_group.ket.name}"
  loadbalancer_id     = "${azurerm_lb.kubernetes.id}"
}
