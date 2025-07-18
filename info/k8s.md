# **Deploying a Kubernetes Cluster on OpenStack with DevStack**

This guide will walk you through deploying a Kubernetes cluster on your DevStack OpenStack environment. I'll cover provisioning resources, installing Kubernetes with kubeadm, and exploring basic Kubernetes concepts.

## Prerequisites

- A Linux server with DevStack already deployed
- OpenStack CLI tools installed and configured
- SSH access to your DevStack host
- Basic familiarity with OpenStack and Kubernetes concepts

### **Step 1: Set Up OpenStack Environment**

First, ensure your OpenStack environment is ready:

```bash
# Source your OpenStack credentials (from DevStack)
source ~/devstack/openrc admin admin

# Verify OpenStack is working
openstack catalog list
```

### **Step 2: Create Network Infrastructure**

```bash
# Create a network for Kubernetes
openstack network create k8s-network

# Create a subnet
openstack subnet create --network k8s-network --subnet-range 192.168.100.0/24 k8s-subnet
openstack subnet set \
  --dns-nameserver 8.8.8.8 \
  --dns-nameserver 1.1.1.1 \
  k8s-subnet

# Create a router and connect it to the external network
openstack router create k8s-router
openstack router add subnet k8s-router k8s-subnet
openstack router set --external-gateway public k8s-router

# Create a security group for Kubernetes nodes
openstack security group create k8s-sg
openstack security group rule create --proto icmp k8s-sg
openstack security group rule create --proto tcp --dst-port 22 k8s-sg
openstack security group rule create --proto tcp --dst-port 6443 k8s-sg
openstack security group rule create --proto tcp --dst-port 2379:2380 k8s-sg
openstack security group rule create --proto tcp --dst-port 10250:10252 k8s-sg
openstack security group rule create --proto tcp --dst-port 30000:32767 k8s-sg
openstack security group rule create --egress --proto udp --dst-port 53 k8s-sg
openstack security group rule create --egress --proto udp --dst-port 67:68 k8s-sg
```

### **Step 3: Create Virtual Machines**

Download the Ubuntu 22.04 Cloud Image (not ISO):
```bash
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

~~Download ubuntu image on the server~~
```bash
depricated wget https://mirror.imt-systems.com/ubuntu/22.04.5/ubuntu-22.04.5-live-server-amd64.iso
```

### Should You Convert .img to .qcow2 for OpenStack?

Short Answer:
No, you typically don’t need to manually convert .img to .qcow2 if the .img file is already in qcow2 format (which is the case for most Ubuntu cloud images). However, if the image is in raw format, converting it to qcow2 can save space and improve performance.
If you downloaded an ISO, convert it to qcow2 for better performance:

1. Check the Existing Format

First, verify the format of your downloaded .img file:

```bash
qemu-img info jammy-server-cloudimg-amd64.img
```

If it says file format: `qcow2`: No conversion needed—upload it directly to OpenStack with `--disk-format qcow2`.
If it says file format: `raw`: Convert it to `qcow2` for better efficiency.

2. How to Convert raw → qcow2 (If Needed)

```bash
qemu-img convert -p -f raw -O qcow2 jammy-server-cloudimg-amd64.img ubuntu-22.04.qcow2
```
Flags:
-p: Show progress.
-f raw: Input format (raw).
-O qcow2: Output format (qcow2).
Result:

The new ubuntu-22.04.qcow2 file will be smaller (due to compression) and more efficient for OpenStack.


~~sudo apt install qemu-utils  # Install qemu-img if needed
qemu-img convert -O qcow2 ubuntu-22.04-live-server-amd64.iso ubuntu-22.04.qcow2~~


3. Upload to OpenStack

```bash
openstack image create "ubuntu-22.04-cloud" \
  --file jammy-server-cloudimg-amd64.img \
  --disk-format qcow2 \
  --container-format bare \
  --public
```

```bash
openstack image create "ubuntu-22.04" \
  --file ubuntu-22.04.qcow2 \
  --disk-format qcow2 \
  --container-format bare \
  --public
```

check downloaded images

```bash
openstack image list
glance image-list
```

Create at least two VMs - one for the control plane and one or more for worker nodes.

```bash
# Create a keypair for SSH access
openstack keypair delete k8s-key
openstack keypair create k8s-key > k8s-key.pem
chmod 600 k8s-key.pem

# Create control plane node
openstack server create \
  --image ubuntu-22.04-cloud \
  --flavor m1.medium \
  --network k8s-network \
  --security-group k8s-sg \
  --key-name k8s-key \
  k8s-control
  --user-data user-network-config.yaml \
  --config-drive true \

# Create worker node(s)
openstack server create \
  --image ubuntu-22.04-cloud \
  --flavor m2.small \
  --network k8s-network \
  --security-group k8s-sg \
  --key-name k8s-key \
  k8s-worker1
  ```

### **Step 4: Install Kubernetes Prerequisites on All Nodes**

SSH into each node (you'll need to assign floating IPs first):

```bash
# Assign floating IPs
openstack floating ip create public
openstack server add floating ip k8s-control <floating-ip>
# openstack server remove floating ip k8s-control <FLOATING_IP>


# SSH into control plane node
ssh -i k8s-key.pem ubuntu@<floating-ip>
```

On each node (control plane and workers), run these commands (example for Ubuntu/Debian):
Run the Official Docker Install Script (Fastest Method)
```bash
# Install Docker
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sudo sh
```
Verify Installation
```bash
sudo docker run hello-world
```

If you see `Hello from Docker!`, it works.



```bash
# Install kubeadm, kubelet and kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### Kubeadmin

1. Install Required Packages
Update your system and install dependencies:
```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl
```

2. Add Kubernetes GPG Key & Repository

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### Install kubeadm

```bash
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### **Step 5: Initialize the Kubernetes Control Plane**

On the control plane node:

```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```
sudo nano /etc/containerd/config.toml
Find the SystemdCgroup option under [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options] and set it to true:

```bash
sudo systemctl restart containerd
```


```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubectl for your user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Check if control plane is running

Run this command to see if all Kubernetes components are active:

```bash
kubectl get pods -n kube-system
```

if you see:
```bash
NAME                                  READY   STATUS    RESTARTS       AGE
etcd-k8s-control                      1/1     Running   1              3m5s
kube-apiserver-k8s-control            1/1     Running   1              3m3s
kube-controller-manager-k8s-control   1/1     Running   4 (102s ago)   3m1s
kube-scheduler-k8s-control            1/1     Running   1              3m
```

### Install a CNI (Container Network Interface) plugin (Flannel)

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

---

sudo systemctl status containerd
sudo systemctl enable --now containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = ["cri"]/' /etc/containerd/config.toml
sudo systemctl restart containerd

sudo tee /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
sudo crictl version

sudo tee /etc/containerd/config.toml <<EOF
version = 2
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.9"
[plugins."io.containerd.grpc.v1.cri".containerd]
  disable_snapshot_annotations = true
  snapshotter = "overlayfs"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
EOF

sudo systemctl restart containerd
sudo crictl images

sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubectl for your user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config