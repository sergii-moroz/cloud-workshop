terraform {
	required_providers {
		openstack = {
			source = "terraform-provider-openstack/openstack"
			version = "~> 1.52.1"
		}
	}
}

provider "openstack" {
	auth_url	= var.auth_url
	user_name	= var.user_name
	password	= var.password
	tenant_name	= var.tenant_name
}
