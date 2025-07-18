# Create a new user
resource "openstack_identity_user_v3" "k8s_user" {
	provider						= openstack.admin
	name								= "k8s-user"
	default_project_id	= openstack_identity_project_v3.k8s_cluster.id
	password						= var.user_password
	# ignore_change_password_upon_first_use = true
}

# Assign role to the user in the project
resource "openstack_identity_role_assignment_v3" "user_role" {
	provider		= openstack.admin
	project_id	= openstack_identity_project_v3.k8s_cluster.id
	user_id			= openstack_identity_user_v3.k8s_user.id
	role_id			= data.openstack_identity_role_v3.member.id
}

data "openstack_identity_role_v3" "member" {
	provider	= openstack.admin
	name			= "member"
}
