# Admin's variables
variable "auth_url" {
	type		= string
	default	= "http://192.168.56.10/identity/v3"
}

variable "admin_name" {
	type		= string
	default	= "admin"
}

variable "admin_password" {
	type		= string
	default = "password"
}

variable "admin_tenant_name" {
	type		= string
	default = "admin"
}

# User's variables
variable "user_name" {
	type		= string
	default	= "admin"
}

variable "user_password" {
	type		= string
	default = "password"
}

variable "user_tenant_name" {
	type		= string
	default	= "k8s-cluster"
}

#
variable "worker_nodes_count" {
	type		= number
	default	= 1
}
