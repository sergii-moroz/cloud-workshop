# Create image
resource "openstack_images_image_v2" "ubuntu_22_04_cloud" {
	provider					= openstack.admin
	name							= "ubuntu-22.04-cloud"
	local_file_path		= pathexpand("~/images/jammy-server-cloudimg-amd64.img")
	disk_format				= "qcow2"
	container_format	= "bare"
	visibility				= "public"

  # # Optional properties
  # min_disk_gb      = 20       # Minimum disk size
  # min_ram_mb       = 2048     # Minimum RAM
  # properties = {
  #   hw_disk_bus    = "scsi"   # Additional image properties
  #   hw_scsi_model  = "virtio-scsi"
  # }
}
