
resource "azurerm_public_ip" "bastion" {
  name                         = "bastion"
  location                     = "East US"
  resource_group_name          = "${azurerm_resource_group.ket.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "bastion" {
  name                      = "bastion"
  location                  = "East US"
  resource_group_name       = "${azurerm_resource_group.ket.name}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"

  ip_configuration {
    name                          = "bastion"
    subnet_id                     = "${azurerm_subnet.kubenodes.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion.id}"
  }
}

resource "azurerm_network_security_group" "bastion" {
  name                = "bastion"
  location            = "${azurerm_resource_group.ket.location}"
  resource_group_name = "${azurerm_resource_group.ket.name}"

  security_rule {
    name                       = "allow_ssh_in_all"
    description                = "Allow SSH access from anywhere"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_virtual_machine" "bastion" {
  name                  = "bastion"
  location              = "East US"
  resource_group_name   = "${azurerm_resource_group.ket.name}"
  network_interface_ids = ["${azurerm_network_interface.bastion.id}"]
  vm_size               = "${var.bastion_vm_size}"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "bastion"
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
    computer_name  = "bastion"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
        key_data = "${file("${var.ssh_key}")}"
    }
  }
}