terraform {
	required_providers {
		openstack = {
			source = "terraform-provider-openstack/openstack"
			version = "~> 1.52.1"
		}
	}
}

# Admin provider (default)
provider "openstack" {
	auth_url	= var.auth_url
	user_name	= var.admin_name
	password	= var.admin_password
	tenant_name	= var.tenant_name
}

# k8s-cluster provider (aliased)
provider "openstack" {
	alias			= var.user_project_name
	auth_url	= var.auth_url
	user_name	= openstack_identity_user_v3.k8s_user.name
	password	= openstack_identity_user_v3.k8s_user.password
	tenant_name	= openstack_identity_project_v3.k8s_cluster.name
}
