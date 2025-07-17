variable "host" {
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

variable "user_name" {
	type		= string
	default	= "admin"
}

variable "user_password" {
	type		= string
	default = "password"
}

variable "user_project_name" {
	type		= string
	default	= "k8s-cluster"
}
