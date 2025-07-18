resource "openstack_compute_keypair_v2" "k8s_key" {
	provider	= openstack.user
	name			= "k8s-key"
}

resource "local_file" "k8s_key_pem" {
	provider				= local
	content					= openstack_compute_keypair_v2.k8s_key.private_key
	filename				= "k8s-key.pem"
	file_permission	= "0600"
}
