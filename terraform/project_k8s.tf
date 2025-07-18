# Create a new project
resource "openstack_identity_project_v3" "k8s_cluster" {
	provider		= openstack.admin
	name				= var.user_tenant_name
	description	= "Creating Kubernetes cluster"
	# is_domain		= false
	# enabled			= true
}
