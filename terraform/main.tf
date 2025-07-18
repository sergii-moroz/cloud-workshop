terraform {
	required_providers {
		openstack = {
			source = "terraform-provider-openstack/openstack"
			version = "~> 1.52.1"
		}
		local = {
			source = "hashicorp/local"
      		version = "~> 2.4"
		}
	}
}

# Admin provider
provider "openstack" {
	alias			= "admin"
	auth_url	= var.auth_url
	user_name	= var.admin_name
	password	= var.admin_password
	tenant_name	= var.admin_tenant_name
}

# k8s-cluster provider
provider "openstack" {
	alias			= "user"
	auth_url	= var.auth_url
	user_name	= openstack_identity_user_v3.k8s_user.name
	password	= openstack_identity_user_v3.k8s_user.password
	tenant_name	= openstack_identity_project_v3.k8s_cluster.name
}
