

provider "azurerm" {
	features {}
	subscription_id = <INSERT_SUBSCR_ID>
}

resource "azurerm_resource_group" "rg" {
	name = "log-parser-rg"
	location = "East US"

}

resource "azurerm_virtual_network" "vnet" {
	name = "log-vnet"
	address_space = ["10.0.0.0/16"]
	location = azurerm_resource_group.rg.location
	resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_subnet" "log_subnet" {
	name = "log-subnet"
	resource_group_name = azurerm_resource_group.rg.name
	virtual_network_name = azurerm_virtual_network.vnet.name
	address_prefixes = ["10.0.1.0/24"]


}

resource "azurerm_public_ip" "public_ip" {
	name = "log-public-ip"
	location = azurerm_resource_group.rg.location
	resource_group_name = azurerm_resource_group.rg.name
	allocation_method = "Dynamic"
	sku = "Basic"
}

resource "azurerm_network_interface" "nic" {
	name = "log-nic"
	location = azurerm_resource_group.rg.location
	resource_group_name = azurerm_resource_group.rg.name
	

	ip_configuration {
		name = "internal"
		subnet_id = azurerm_subnet.log_subnet.id
		private_ip_address_allocation = "Dynamic"
		public_ip_address_id = azurerm_public_ip.public_ip.id
	}
}

resource "azurerm_network_security_group" "nsg" {
	name = "log-nsg"
	location = azurerm_resource_group.rg.location
	resource_group_name = azurerm_resource_group.rg.name

	security_rule {
		name = "SSH"
		priority = 1001
		direction = "Inbound"
		access = "Allow"
		protocol = "Tcp"
		source_port_range = "*"
		destination_port_range = "22"
		source_address_prefix = "*"
		destination_address_prefix = "*"
	}

	security_rule {
		name = "HTTP"
		priority = 1002
		direction = "Inbound"
		access = "Allow"
		protocol = "Tcp"
		source_port_range = "*"
		destination_port_range = "80"
		source_address_prefix = "*"
		destination_address_prefix = "*"
	}
}

resource "azurerm_network_interface_security_group_association" "association" {
	network_interface_id = azurerm_network_interface.nic.id
	network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
	name = "log-vm"
	resource_group_name = azurerm_resource_group.rg.name
	location = azurerm_resource_group.rg.location
	size = "Standard_B1s"
	admin_username = "azureuser"
	network_interface_ids = [
		azurerm_network_interface.nic.id,
	]
	
	admin_ssh_key {
		username = "azureuser"
		public_key = file(<PATH_TO_KEY.PUB>)
	}

	os_disk {
		caching = "ReadWrite"
		storage_account_type = "Standard_LRS"
		name = "log-osdisk"
	}

	source_image_reference {
		publisher = "Canonical"
		offer = "ubuntu-24_04-lts"
		sku = "server"
		version = "latest"
	}

}

output "public_ip" {
	value = azurerm_linux_virtual_machine.vm.public_ip_address
}
