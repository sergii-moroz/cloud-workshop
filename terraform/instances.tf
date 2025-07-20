# Compute
resource "openstack_compute_instance_v2" "k8s_control" {
	provider				= openstack.user
	name						= "k8s-control"
	image_name			= openstack_images_image_v2.ubuntu_22_04_cloud.name
	flavor_name			= openstack_compute_flavor_v2.k8s_control_flavor.name
	# image_name			= "cirros-0.6.3-x86_64-disk"
	# flavor_name			= "cirros256"
	key_pair				= openstack_compute_keypair_v2.k8s_key.name
	security_groups	= ["k8s-sg"]

	network {
		name = openstack_networking_network_v2.k8s_network.name
	}

	depends_on = [
		openstack_images_image_v2.ubuntu_22_04_cloud,
		openstack_compute_flavor_v2.k8s_control_flavor
	]

	# provisioner "remote-exec" {
	# 	inline = [
	# 		"sudo touch start.txt",
	# 		"sudo apt-get update",
	# 		"sudo apt-get upgrade -y",
	# 		"sudo touch end.txt"
	# 	]

	# 	connection {
	# 		type				= "ssh"
	# 		user				= "ubuntu"
	# 		private_key	= file(local_file.k8s_key_pem.filename)
	# 		host				= self.access_ip_v4
	# 	}
	# }

	# #cloud-config
	# package_update: true
	# package_upgrade: true
	user_data = <<-EOF
		runcmd:
			- |
				# Start
				sudo touch start.txt
			- |
				# Disable swap
				swapoff -a
				sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
			- |
				# Forwarding IPv4 and letting iptables see bridged traffic
				cat <<END | sudo tee /etc/modules-load.d/k8s.conf
				overlay
				br_netfilter
				END
			- |
				sudo modprobe overlay
				sudo modprobe br_netfilter
			- |
				# sysctl params required by setup, params persist across reboots
				cat <<END | sudo tee /etc/sysctl.d/k8s.conf
				net.bridge.bridge-nf-call-iptables	= 1
				net.bridge.bridge-nf-call-ip6tables	= 1
				net.ipv4.ip_forward									= 1
				END
			- |
				# Apply sysctl params without reboot
				sudo sysctl --system
			- |
				# end
				sudo touch end.txt
	EOF
}

# resource "openstack_compute_instance_v2" "k8s_worker_1" {
# 	count						= var.worker_nodes_count
# 	provider				= openstack.user
# 	name						= "k8s-worker-${count.index}"
# 	image_name			= openstack_images_image_v2.ubuntu_22_04_cloud.name
# 	flavor_name			= openstack_compute_flavor_v2.k8s_worker_flavor.name
# 	# image_name			= "cirros-0.6.3-x86_64-disk"
# 	# flavor_name			= "cirros256"
# 	key_pair				= openstack_compute_keypair_v2.k8s_key.name
# 	security_groups	= ["k8s-sg"]

# 	network {
# 		name = openstack_networking_network_v2.k8s_network.name
# 	}

# 	depends_on = [
# 		openstack_images_image_v2.ubuntu_22_04_cloud,
# 		openstack_compute_flavor_v2.k8s_worker_flavor
# 	]

# 	user_data = <<-EOF
# 		#cloud-config
# 		package_update: true
# 		package_upgrade: true
# 	EOF
# }
