resource "azurerm_availability_set" "master" {
  name                = "master"
  location            = "${azurerm_resource_group.ket.location}"
  resource_group_name = "${azurerm_resource_group.ket.name}"
  managed             = "true"
}

resource "azurerm_network_security_group" "master" {
  name                = "master"
  location            = "${azurerm_resource_group.ket.location}"
  resource_group_name = "${azurerm_resource_group.ket.name}"

  security_rule {
    name                       = "kube_apiserver_6443"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "master" {
  count                     = "${var.master_count}"
  name                      = "master-${count.index}"
  location                  = "East US"
  resource_group_name       = "${azurerm_resource_group.ket.name}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"

  ip_configuration {
    name                                    = "master-${count.index}"
    subnet_id                               = "${azurerm_subnet.kubenodes.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.kubeapi.id}"]
  }
}

resource "azurerm_virtual_machine" "master" {
  count = "${var.master_count}"
  name                  = "master-${count.index}"
  location              = "East US"
  resource_group_name   = "${azurerm_resource_group.ket.name}"
  network_interface_ids = ["${element(azurerm_network_interface.master.*.id, count.index)}"]
  vm_size               = "${var.master_vm_size}"
  availability_set_id   = "${azurerm_availability_set.master.id}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "master-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Optional data disks
#   storage_data_disk {
#     name              = "datadisk_new"
#     managed_disk_type = "Standard_LRS"
#     create_option     = "Empty"
#     lun               = 0
#     disk_size_gb      = "1023"
#   }

#   storage_data_disk {
#     name            = "${azurerm_managed_disk.test.name}"
#     managed_disk_id = "${azurerm_managed_disk.test.id}"
#     create_option   = "Attach"
#     lun             = 1
#     disk_size_gb    = "${azurerm_managed_disk.test.disk_size_gb}"
#   }

  os_profile {
    admin_username = "${var.admin_username}"
    computer_name  = "master-${count.index}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
        key_data = "${file("${var.ssh_key}")}"
    }
  }

  tags {
    ketrole = "master"
  }
}
