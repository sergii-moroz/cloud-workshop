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

  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - software-properties-common
      - e2fsprogs
      - lsb-release

    runcmd:
      # Disable swap permanently
      - |
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab

      # Load required kernel modules
      - |
        cat <<END > /etc/modules-load.d/k8s.conf
        overlay
        br_netfilter
        END
        modprobe overlay
        modprobe br_netfilter

      # Configure sysctl
      - |
        cat <<END > /etc/sysctl.d/k8s.conf
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                = 1
        END
        sysctl --system

      # Install containerd
      - |
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        apt-get update
        apt-get install -y containerd.io
        mkdir -p /etc/containerd
        containerd config default | tee /etc/containerd/config.toml
        sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
        systemctl restart containerd
        systemctl enable containerd

      # Install CNI plugins
      - |
        mkdir -p /opt/cni/bin
        curl -L "https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz" | tar -C /opt/cni/bin -xz

      # Install Kubernetes components
      - |
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1 kubectl=1.29.6-1.1
        apt-mark hold kubelet kubeadm kubectl

      # Configure crictl
      - |
        cat <<END > /etc/crictl.yaml
        runtime-endpoint: unix:///var/run/containerd/containerd.sock
        image-endpoint: unix:///var/run/containerd/containerd.sock
        timeout: 10
        debug: false
        END

      # Initialize control plane (commented out - better done separately)
      # - |
      #   kubeadm init --pod-network-cidr=10.244.0.0/16 \
      #     --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
      #     --node-name k8s-control
  EOF
  # user_data = <<-EOF
	#   #cloud-config
  #   package_update: true
  #   package_upgrade: true
  #   packages:
  #     - apt-transport-https
  #     - ca-certificates
  #     - curl
  #     - gpg
  #   runcmd:
  #     - |
  #       # Disable swap
  #       swapoff -a
  #       sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  #     - |
  #       # Forwarding IPv4 and letting iptables see bridged traffic
  #       cat <<END | sudo tee /etc/modules-load.d/k8s.conf
  #       overlay
  #       br_netfilter
  #       END
  #     - sudo modprobe overlay
  #     - sudo modprobe br_netfilter
  #     - |
  #       # sysctl params required by setup, params persist across reboots
  #       cat <<END | sudo tee /etc/sysctl.d/k8s.conf
  #       net.bridge.bridge-nf-call-iptables	= 1
  #       net.bridge.bridge-nf-call-ip6tables	= 1
  #       net.ipv4.ip_forward									= 1
  #       END
  #     - |
  #       # Apply sysctl params without reboot
  #       sudo sysctl --system
  #     - curl -LO https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-amd64.tar.gz
  #     - sudo tar Cxzvf /usr/local containerd-1.7.14-linux-amd64.tar.gz
  #     - curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
  #     - sudo mkdir -p /usr/local/lib/systemd/system/
  #     - sudo mv containerd.service /usr/local/lib/systemd/system/
  #     - sudo mkdir -p /etc/containerd
  #     - containerd config default | sudo tee /etc/containerd/config.toml
  #     - sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
  #     - sudo systemctl daemon-reload
  #     - sudo systemctl enable --now containerd
  #     - curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
  #     - sudo install -m 755 runc.amd64 /usr/local/sbin/runc
  #     - |
  #       # Install cni plugin
  #       curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz
  #       sudo mkdir -p /opt/cni/bin
  #       sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz
  #     - |
  #       # Install kubeadm, kubelet and kubectl
  #       curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  #       echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
  #       sudo apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1 kubectl=1.29.6-1.1 --allow-downgrades --allow-change-held-packages
  #       sudo apt-mark hold kubelet kubeadm kubectl
  #     - crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
  # EOF
}

resource "openstack_compute_instance_v2" "k8s_worker_1" {
  count						= var.worker_nodes_count
  provider				= openstack.user
  name						= "k8s-worker-${count.index}"
  image_name			= openstack_images_image_v2.ubuntu_22_04_cloud.name
  flavor_name			= openstack_compute_flavor_v2.k8s_worker_flavor.name
  # image_name			= "cirros-0.6.3-x86_64-disk"
  # flavor_name			= "cirros256"
  key_pair				= openstack_compute_keypair_v2.k8s_key.name
  security_groups	= ["k8s-sg"]

  network {
    name = openstack_networking_network_v2.k8s_network.name
  }

  depends_on = [
    openstack_images_image_v2.ubuntu_22_04_cloud,
    openstack_compute_flavor_v2.k8s_worker_flavor
  ]

  user_data = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - software-properties-common
      - e2fsprogs
      - lsb-release

    runcmd:
      # Disable swap permanently
      - |
        swapoff -a
        sed -i '/ swap / s/^/#/' /etc/fstab

      # Load required kernel modules
      - |
        cat <<END > /etc/modules-load.d/k8s.conf
        overlay
        br_netfilter
        END
        modprobe overlay
        modprobe br_netfilter

      # Configure sysctl
      - |
        cat <<END > /etc/sysctl.d/k8s.conf
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                = 1
        END
        sysctl --system

      # Install containerd
      - |
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        apt-get update
        apt-get install -y containerd.io
        mkdir -p /etc/containerd
        containerd config default | tee /etc/containerd/config.toml
        sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
        systemctl restart containerd
        systemctl enable containerd

      # Install CNI plugins
      - |
        mkdir -p /opt/cni/bin
        curl -L "https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz" | tar -C /opt/cni/bin -xz

      # Install Kubernetes components
      - |
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1
        apt-mark hold kubelet kubeadm

      # Configure crictl
      - |
        cat <<END > /etc/crictl.yaml
        runtime-endpoint: unix:///var/run/containerd/containerd.sock
        image-endpoint: unix:///var/run/containerd/containerd.sock
        timeout: 10
        debug: false
        END
  EOF
}
