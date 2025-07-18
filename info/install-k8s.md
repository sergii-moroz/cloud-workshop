### K8S Controle Plane
---

worker 
tcp 10256
tcp 30000:32767
ttcp 22
tcp 10250

### 1. Disable Swap
---
```bash
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

3. Forwarding IPv4 and letting iptables see bridged traffic

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
lsmod | grep br_netfilter
lsmod | grep overlay

# Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
```

4. Install container runtime
```bash
curl -LO https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.14-linux-amd64.tar.gz
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Check that containerd service is up and running
systemctl status containerd
```

5. Install runc

```bash
curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
```

6. Install cni plugin

```bash
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz
```

7. Install kubeadm, kubelet and kubectl

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1 kubectl=1.29.6-1.1 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl

kubeadm version
kubelet --version
kubectl version --client
```

8. Configure crictl to work with containerd

```bash
sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
```

9. initialize control plane

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=172.31.89.68 --node-name master
# 10.244.0.0/16
# 192.168.0.0/16 
```

OUTPUT:
```bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.100.247:6443 --token z6wm0j.64ejpkq23hc77ooa \
        --discovery-token-ca-cert-hash sha256:1991ce920dca27b550ec962d2bd810480c95e626271589e04b1b96550138ed97
```

10. Prepare kubeconfig

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

11. Install Flannel

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

If all the above steps were completed, you should be able to run kubectl get nodes on the master node

---

https://github.com/piyushsachdeva/CKA-2024/tree/main/Resources/Day27

### Testing a Kubernetes Cluster with a Simple Nginx Example
This simple test helps verify that your Kubernetes cluster is working properly by deploying a basic Nginx pod and checking its status. Let me break down what these commands do and how to interpret the results.

1. Create a test pod:
```bash
kubectl run nginx-test --image=nginx --restart=Never
```

- kubectl run: Creates and runs a particular image in a pod
- nginx-test: Name you're giving to this pod
- --image=nginx: Uses the official Nginx image from Docker Hub
- --restart=Never: Creates a simple pod (not a Deployment)

2. Check the pod status:

```bash
kubectl get pods -o wide
```

- get pods: Lists all pods in the current namespace
- -o wide: Shows additional details (IP address, node name, etc.)

#### What to Expect

##### After running the first command:

Kubernetes will pull the Nginx image from Docker Hub (if not already present)
It will schedule the pod to run on one of your worker nodes
You should see a message like: pod/nginx-test created

##### After running the second command:

You should see output similar to:

```bash
NAME         READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE
nginx-test   1/1     Running   0          30s   10.244.1.2   worker-1   <none>
```

Additional Verification Steps
Check pod logs:
```bash
kubectl logs nginx-test
```

Execute commands in the pod:
```bash
kubectl exec -it nginx-test -- /bin/bash
```

Delete the test pod when done:
```bash
kubectl delete pod nginx-test
```