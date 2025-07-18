Complete Solution

1. First, Clean Up the Existing Cluster

bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/pki
sudo rm -rf /var/lib/etcd
sudo rm -rf $HOME/.kube
2. Reinitialize the Cluster with Proper Settings

bash
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=192.168.100.22 \
  --upload-certs \
  --control-plane-endpoint=192.168.100.22 \
  --v=5  # For detailed logs
3. Configure kubectl

bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
4. Fix Network Connectivity

bash
# Ensure proper firewall rules
sudo ufw allow 6443/tcp
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250/tcp

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
5. Install CNI Plugin (Flannel)

bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
6. Verify Installation

bash
kubectl get pods -n kube-system -w
Critical Additional Checks

Certificate Validity:
bash
sudo kubeadm certs check-expiration
Resource Availability:
Ensure your VM has at least 2GB RAM and 2 vCPUs
Check memory: free -h
Check CPU: nproc
Time Synchronization:
bash
sudo timedatectl set-ntp true
timedatectl status
If Components Still Crash

Check kubelet logs:
bash
journalctl -u kubelet -n 100 --no-pager
Manual Certificate Renewal:
bash
sudo kubeadm certs renew all
sudo systemctl restart kubelet
Alternative CNI (if Flannel fails):
bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
This comprehensive approach should resolve your control plane issues. The key was the complete reset and proper reinitialization with correct network settings. Let me know if you encounter any specific errors during this process.