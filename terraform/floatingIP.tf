# Create a floating IP from the 'public' pool
resource "openstack_networking_floatingip_v2" "k8s_control_floating_ip" {
	provider = openstack.user
	pool = "public"
}

# Assign the floating IP to your instance
resource "openstack_compute_floatingip_associate_v2" "k8s_control_fip" {
	provider		= openstack.user
	floating_ip = openstack_networking_floatingip_v2.k8s_control_floating_ip.address
	instance_id = openstack_compute_instance_v2.k8s_control.id
}

# Output the floating IP address
output "k8s_control_floating_ip" {
	value = openstack_networking_floatingip_v2.k8s_control_floating_ip.address
}
