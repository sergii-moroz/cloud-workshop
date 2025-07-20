resource "openstack_compute_flavor_v2" "k8s_control_flavor" {
	provider		= openstack.admin
	name				= "k8s-control-flavor"
	ram					= 4096
	vcpus				= 2
	disk				= 10
	is_public		= true
}

resource "openstack_compute_flavor_v2" "k8s_worker_flavor" {
	provider		= openstack.admin
	name				= "k8s-worker-flavor"
	ram					= 4096
	vcpus				= 2
	disk				= 10
	is_public		= true
}
