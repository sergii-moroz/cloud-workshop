# Create a new project
resource "openstack_identity_project_v3" "k8s_cluster" {
	name				= var.user_tennant_name
	description	= "Creating Kubernetes cluster"
	# is_domain		= false
	# enabled			= true
}
