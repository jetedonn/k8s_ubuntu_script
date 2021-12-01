#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No Arguments Supplied"
    echo "Arg Options are: remove or install"
    exit
fi
if [ $1 != 'install' ]
then
   rm -rf /var/lib/rook
   apt remove -y docker \
   docker-ce \
   docker-ce-cli \
   kubelet \
   kubeadm \
   kubectl

   rm -rf /etc/kubernetes
   rm -rf /var/lib/docker/*
   rm -rf /var/lib/kubelet/*
   rm -rf /var/lib/etcd
   rm -rf /var/lib/cni/*
   rm -rf /etc/cni/

   ip link show
fi

if [ $1 == 'remove' ]
then
   echo "exiting"
   exit
fi

mkdir /etc/docker

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "1"
  },
  "storage-driver": "overlay2",
  "insecure-registries" : ["10.10.100.14:5000"]
}
EOF
# Line 45 - this allows Docker to pull from an unsecure local repository. If you do not have one, you can delete this line along with the , at the end of line 44
apt-get update

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
# Lines 58 and 68 specifies which version of Docker and Kubernetes to install. If you change the Kubernetes version, you must also change the version listed on line 75
apt-get install -y docker-ce=5:19.03.13~3-0~ubuntu-bionic docker-ce-cli=5:19.03.13~3-0~ubuntu-bionic containerd.io

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl enable docker
systemctl start docker
systemctl status docker
docker info

apt-get install -y kubelet=1.19.3-00 kubeadm=1.19.3-00 kubectl=1.19.3-00

systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet
# Line 76 must be changed with the appropriate join command. The join command is echoed at the completion of the master script. To create a new join command, execute kubeadm token create --print-join-command on the master
# The below line should be updated
kubeadm join 10.10.100.10:6443 --token lfo4h6.ubjk6868bnyxz3s6 \
            --discovery-token-ca-cert-hash sha256:81029664eb593776c27c504150b539ed59eda6316ad95231227f343d448dbbe6
