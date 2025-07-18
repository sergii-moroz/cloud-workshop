# Compute
resource "openstack_compute_instance_v2" "k8s_control" {
	provider				= openstack.user
	name						= "k8s-control"
	# image_name			= "ubuntu-22.04-cloud"
	# flavor_name			= "m1.medium"
	image_name			= "cirros-0.6.3-x86_64-disk"
	flavor_name			= "cirros256"
	# key_pair				= openstack_compute_keypair_v2.k8s_key.name
	security_groups	= ["k8s-sg"]

	network {
		name = "k8s-network"
	}

	# user_data = <<-EOF
	#   #cloud-config
	#   package_update: true
	#   package_upgrade: true
	# EOF
}

resource "openstack_compute_instance_v2" "k8s_worker_1" {
	provider				= openstack.user
	name						= "k8s-worker-1"
	# image_name			= "ubuntu-22.04-cloud"
	# flavor_name			= "m1.medium"
	image_name			= "cirros-0.6.3-x86_64-disk"
	flavor_name			= "cirros256"
	# key_pair				= openstack_compute_keypair_v2.k8s_key.name
	security_groups	= ["k8s-sg"]

	network {
		name = "k8s-network"
	}

	# user_data = <<-EOF
	#   #cloud-config
	#   package_update: true
	#   package_upgrade: true
	# EOF
}
