data "openstack_networking_network_v2" "public" {
	provider	= openstack.admin
	name			= "public"
}

# Create network
resource "openstack_networking_network_v2" "k8s_network" {
	provider				= openstack.user
	name						= "k8s-network"
	admin_state_up	= "true"

	depends_on = [
		openstack_identity_role_assignment_v3.user_role
	]
}

# Create subnet
resource "openstack_networking_subnet_v2" "k8s_subnet" {
	provider				= openstack.user
	name						= "k8s-subnet"
	network_id			= openstack_networking_network_v2.k8s_network.id
	cidr						= "192.168.100.0/24"
	ip_version			= 4
	dns_nameservers	= ["8.8.8.8", "1.1.1.1"]
}

# Create router
resource "openstack_networking_router_v2" "k8s_router" {
	provider						= openstack.user
	name								= "k8s-router"
	admin_state_up			= true
	external_network_id	= data.openstack_networking_network_v2.public.id
}

# Connect router to subnet
resource "openstack_networking_router_interface_v2" "k8s_router_interface" {
	provider	= openstack.user
	router_id	= openstack_networking_router_v2.k8s_router.id
	subnet_id	= openstack_networking_subnet_v2.k8s_subnet.id
}

# Create security group
resource "openstack_networking_secgroup_v2" "k8s_sg" {
	provider		= openstack.user
	name				= "k8s-sg"
	description	= "Security group for Kubernetes nodes"
}

# Security group rules
resource "openstack_networking_secgroup_rule_v2" "icmp" {
	provider					= openstack.user
	direction					= "ingress"
	ethertype					= "IPv4"
	protocol					= "icmp"
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
	provider					= openstack.user
	direction					= "ingress"
	ethertype					= "IPv4"
	protocol					= "tcp"
	port_range_min		= 22
	port_range_max		= 22
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "kube_api" {
	provider					= openstack.user
	direction					= "ingress"
	ethertype					= "IPv4"
	protocol					= "tcp"
	port_range_min		= 6443
	port_range_max		= 6443
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "etcd" {
	provider					= openstack.user
	direction					= "ingress"
	ethertype					= "IPv4"
	protocol					= "tcp"
	port_range_min		= 2379
	port_range_max		= 2380
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "kubelet" {
	provider					= openstack.user
	direction					= "ingress"
	ethertype					= "IPv4"
	protocol					= "tcp"
	port_range_min		= 10248
	port_range_max		= 10260
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "nodeports" {
	provider					= openstack.user
	direction					= "ingress"
	ethertype					= "IPv4"
	protocol					= "tcp"
	port_range_min		= 30000
	port_range_max		= 32767
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "dns_egress" {
	provider					= openstack.user
	direction					= "egress"
	ethertype					= "IPv4"
	protocol					= "udp"
	port_range_min		= 53
	port_range_max		= 53
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "dhcp_egress" {
	provider					= openstack.user
	direction					= "egress"
	ethertype					= "IPv4"
	protocol					= "udp"
	port_range_min		= 67
	port_range_max		= 68
	security_group_id	= openstack_networking_secgroup_v2.k8s_sg.id
}
