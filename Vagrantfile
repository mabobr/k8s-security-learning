# -*- mode: ruby -*-
# vi: set ft=ruby :

##############################################################################
rhel9_setup_sh = <<-SCRIPT
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Bratislava /etc/localtime

dnf -y install firewalld net-tools nc tmux emacs-nox
systemctl enable --now firewalld
dnf -y update
SCRIPT

############################################################################
# will setup k8s cluster to up&running state and create proxy 
app_setup_sh = <<-SCRIPT

HOSTNAME=$(hostname -s)
# this script is not for proxy, the proxy VM has own setup code
test ${HOSTNAME} == 'proxy' && exit 0

# creating k8s user
grep -q "^k8s:" /etc/passwd
if [[ $? != "0" ]] ; then
    useradd -c "apl. k8s user" k8s || exit 1
fi
K8S_HOME=$( getent passwd "$USER" | cut -d: -f6 )

if [[ ! -d ${K8S_HOME}/.ssh ]] ; then
    mkdir -p ${K8S_HOME}/.ssh || exit 1
fi
if [[ -f /tmp/k8s.key ]] ; then
    mv /tmp/k8s.key ${K8S_HOME}/.ssh || exit 1
fi
if [[ -f /tmp/k8s.key.pub ]] ; then
    cat /tmp/k8s.key.pub >${K8S_HOME}/.ssh/authorized_keys
    rm -f /tmp/k8s.key.pub
fi
chown -R k8s:k8s ${K8S_HOME}/.ssh || exit 1
chmod 700 ${K8S_HOME}/.ssh || exit 1
chmod 600 ${K8S_HOME}/.ssh/k8s.key ${K8S_HOME}/.ssh/authorized_keys || exit 1

# enabling firewall deny logs to debug network problems
sed -i "s/LogDenied=.*/LogDenied=all/" /etc/firewalld/firewalld.conf
systemctl reload firewalld

#Create a configuration file for containerd:
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay || exit 1
modprobe br_netfilter || exit 1

#Set system configurations for Kubernetes networking:
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl -q --system

# instralling container.io
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || exit 1
dnf -y makecache || exit 1
dnf install -y containerd.io curl || exit 1
# backup default config
mv /etc/containerd/config.toml /etc/containerd/config.toml.bak
containerd config default > /etc/containerd/config.toml
sed -ir 's/^(\s+SystemdCgroup = ).*/\1 true/' /etc/containerd/config.toml

systemctl enable --now containerd.service || exit 1

####################################################
# selinux disable
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/sysconfig/selinux

# swap off
swapoff -a || exit 1
sed -e '/swap/s/^/#/g' -i /etc/fstab || exit 1

#####################################################
# installing
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
dnf -y makecache || exit 1
dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes || exit 1
systemctl enable --now kubelet || exit 1

if [[ ${HOSTNAME} = "master" ]] ; then
    firewall-cmd -q --permanent --add-port=6443/tcp
    firewall-cmd -q --permanent --add-port=2379-2380/tcp
    firewall-cmd -q --permanent --add-port=10250/tcp
    firewall-cmd -q --permanent --add-port=10251/tcp
    firewall-cmd -q --permanent --add-port=10259/tcp
    firewall-cmd -q --permanent --add-port=10257/tcp
    firewall-cmd -q --permanent --add-port=179/tcp
    firewall-cmd -q --permanent --add-port=4789/udp
    firewall-cmd --reload

    if [[ ! -f /etc/kubernetes/manifests/kube-apiserver.yaml ]] ; then
        kubeadm init --pod-network-cidr ${POD_NETWORK_CIDR} || exit 1  
    else
        echo k8s is already initialized, when re-initialization is needed, destroy VMs via vagrant
    fi
else
    firewall-cmd -q --permanent --add-port=179/tcp
    firewall-cmd -q --permanent --add-port=10250/tcp
    firewall-cmd -q --permanent --add-port=30000-32767/tcp
    firewall-cmd -q --permanent --add-port=4789/udp
    firewall-cmd -q --reload
fi
SCRIPT

Vagrant.configure("2") do |config|
  
    config.vm.box         = "rockylinux/9"
    config.vm.synced_folder ".", "/vagrant", disabled: true
  
    config.vm.provider "libvirt" do |v|
        v.memory = 2048
        v.cpus = 2
        v.graphics_type = 'none'
    end
  
    config.vm.define "master" do |master|
        master.vm.hostname    = "master"
    end
  
    config.vm.define "node0" do |node0|
        node0.vm.hostname    = "node0"
    end
  
    config.vm.define "node1" do |node1|
        node1.vm.hostname    = "node1"
    end

    config.vm.define "proxy" do |proxy|
        proxy.vm.hostname    = "proxy"
    end

    config.vm.provision "system-init", type: "shell", run: "once", :inline => rhel9_setup_sh
    config.vm.provision "reload-after-update", type: "reload",  run: "once"
    config.vm.provision "copy-k8s-priv-key", type: "file", source: "./k8s.key", destination: "/tmp/k8s.key", run: "once"
    config.vm.provision "copy-k8s-pub-key",  type: "file", source: "./k8s.key.pub", destination: "/tmp/k8s.key.pub", run: "once"
    config.vm.provision "app-init", type: "shell", run: "once", :inline => app_setup_sh, \
        env: {"POD_NETWORK_CIDR" => ENV['POD_NETWORK_CIDR'],"USE_HTTP_PROXY" => ENV['USE_HTTP_PROXY']}
end