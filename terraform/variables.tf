variable "admin_username" {
    default = "ketadmin"
}

variable "nodes_subnet" {
    default = "10.0.1.0/24"
}

variable "ssh_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "azure_resource_group_name" {
    default = "ket"
}

variable "bastion_vm_size" {
    default = "Standard_B2s"
}

variable "etcd_count" {
    default = 3
}

variable "etcd_vm_size" {
    default = "Standard_B2ms"
}

variable "master_count" {
    default = 2
}

variable "master_vm_size" {
    default = "Standard_B2ms"
}

variable "master_apiserver_port" {
    default = 6443
}

variable "worker_count" {
    default = 2
}

variable "worker_vm_size" {
    default = "Standard_B2ms"
}