resource "azurerm_availability_set" "etcd" {
  name                = "etcd"
  location            = "${azurerm_resource_group.ket.location}"
  resource_group_name = "${azurerm_resource_group.ket.name}"
  managed             = "true"
}

resource "azurerm_network_interface" "etcd" {
  count = "${var.etcd_count}"
  name                = "etcd-${count.index}"
  location            = "East US"
  resource_group_name = "${azurerm_resource_group.ket.name}"

  ip_configuration {
    name                          = "etcd-${count.index}"
    subnet_id                     = "${azurerm_subnet.kubenodes.id}"
    private_ip_address_allocation = "dynamic"
    # public_ip_address_id          = "${element(azurerm_public_ip.etcd.*.id, count.index)}"
  }
}

resource "azurerm_virtual_machine" "etcd" {
  count = "${var.etcd_count}"
  name                  = "etcd-${count.index}"
  location              = "East US"
  resource_group_name   = "${azurerm_resource_group.ket.name}"
  network_interface_ids = ["${element(azurerm_network_interface.etcd.*.id, count.index)}"]
  vm_size               = "${var.etcd_vm_size}"
  availability_set_id   = "${azurerm_availability_set.etcd.id}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "etcd-${count.index}"
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
    computer_name  = "etcd-${count.index}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
        key_data = "${file("${var.ssh_key}")}"
    }
  }

  tags {
    ketrole = "etcd"
  }
}