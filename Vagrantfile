# -*- mode: ruby -*-
# vi: set ft=ruby :

##############################################################################
rhel9_setup_sh = <<-SCRIPT
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Bratislava /etc/localtime

dnf -y install firewalld net-tools nc tmux emacs-nox

# we will use nftables only
#systemctl disable firewalld >/dev/null 2>/dev/null
#systemctl mask --now firewalld
#systemctl enable --now nftables
systemctl enable --now firewalld || exit 1

# setup NFT filters
# nft add table inet filter || exit 1
# nft add chain inet filter input { type filter hook input priority filter \\; } || exit 1
# nft add chain inet filter forward { type filter hook forward priority filter \\; } || exit 1
# nft add chain inet filter output { type filter hook output priority filter \\; } || exit 1
# grep -q '22 accept' /etc/sysconfig/nftables.conf
# if [ $? != "0" ] ; then
#     nft add rule inet filter input tcp dport 22 accept || exit 1
# fi

# nft add chain inet filter input '{ policy drop; }'
# echo "flush ruleset" > /etc/sysconfig/nftables.conf
# nft list ruleset >> /etc/sysconfig/nftables.conf

dnf -y update
SCRIPT

############################################################################
# will setup k8s cluster to up&running state and create proxy 
app_setup_sh = <<-SCRIPT

#env | sort
echo USING POD_NETWORK_CIDR=${POD_NETWORK_CIDR}


HOSTNAME=$(hostname -s)
# this script is not for proxy, the proxy VM has own setup code
test ${HOSTNAME} == 'proxy' && exit 0

# creating k8s user
grep -q "^k8s:" /etc/passwd
if [[ $? != "0" ]] ; then
    useradd -c "apl. k8s user" k8s || exit 1
fi
K8S_HOME=$( getent passwd k8s | cut -d: -f6 )

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
if [ ! -f /etc/yum.repos.d/kubernetes.repo ] ; then
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
fi

dnf -y makecache || exit 1
dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes || exit 1
systemctl enable --now kubelet || exit 1

if [[ ${HOSTNAME} = "master" ]] ; then
    for PORT in 6443 10250 10251 10259 10257 179
    do  
        firewall-cmd --permanent --add-port=${PORT}/tcp
    done
    firewall-cmd --permanent --add-port=5789/udp
    firewall-cmd --permanent --add-port=2379-2380/udp

    if [[ ! -f /etc/kubernetes/manifests/kube-apiserver.yaml ]] ; then
        kubeadm init --pod-network-cidr ${POD_NETWORK_CIDR} || exit 1  
        mkdir -p $K8S_HOME/.kube || exit 1
        cp -i /etc/kubernetes/admin.conf $K8S_HOME/.kube/config || exit 1
        chown -R k8s:k8s $K8S_HOME/.kube || exit 1
    else
        echo k8s is already initialized, when re-initialization is needed, destroy VMs via vagrant
    fi
else
    firewall-cmd --permanent --add-port=30000-32767/tcp
    firewall-cmd --permanent --add-port=4789/udp
fi
firewall-cmd --reload || exit 1
SCRIPT

net_setup_sh = <<-SCRIPT
K8S_HOME=$( getent passwd k8s | cut -d: -f6 )

if [[ ${HOSTNAME} = "master" ]] ; then
    
    rm -f /tmp/join2cluster
    kubeadm token create --print-join-command >/tmp/join2cluster || exit 1
    if [ -f /tmp/join2cluster ] ; then
        echo Copying join command to workers /tmp/join2cluster
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${K8S_HOME}/.ssh/k8s.key /tmp/join2cluster k8s@node1:/tmp
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${K8S_HOME}/.ssh/k8s.key /tmp/join2cluster k8s@node0:/tmp
    else
        echo $0 error: File /tmp/join2cluster not created
        exit 1
    fi
else
    echo TBD waiting for join command
fi

#if [[ ${USE_HTTP_PROXY} != "0" ]] ; then
#    
#fi
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

    # config.vm.define "proxy" do |proxy|
    #     proxy.vm.hostname    = "proxy"
    # end

    config.vm.provision "system-init", type: "shell", run: "once", :inline => rhel9_setup_sh
    config.vm.provision "reload-after-update", type: "reload",  run: "once"
    config.vm.provision "copy-k8s-priv-key", type: "file", source: "./k8s.key", destination: "/tmp/k8s.key", run: "once"
    config.vm.provision "copy-k8s-pub-key",  type: "file", source: "./k8s.key.pub", destination: "/tmp/k8s.key.pub", run: "once"
    config.vm.provision "app-init", type: "shell", run: "once", :inline => app_setup_sh, \
        env: {"POD_NETWORK_CIDR" => ENV['POD_NETWORK_CIDR'],"USE_HTTP_PROXY" => ENV['USE_HTTP_PROXY']}
    config.vm.provision "net-init", type: "shell", run: "once", :inline => net_setup_sh, \
        env: {"POD_NETWORK_CIDR" => ENV['POD_NETWORK_CIDR'],"USE_HTTP_PROXY" => ENV['USE_HTTP_PROXY']}
end