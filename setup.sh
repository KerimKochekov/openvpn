#!/bin/bash

# Disclaimer: Below some commands need root privileges

#set -e

# Init setup

echo "Updating essential packages"
apt update -y
apt upgrade -y
apt dist-upgrade -y
apt install -y apt-transport-https ca-certificates sudo

echo "Creating main user and adding to the groups"
useradd -m -d /home/sysadm -s /bin/bash sysadm
usermod -a -G sudo sysadm

echo "Enabling passwordless access"
echo "sysadm ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sysadm

echo "Setting correct file permissions"
chmod 0440 /etc/sudoers.d/sysadm
visudo -cf /etc/sudoers.d/sysadm

echo "Authorizing user for SSH access"
mkdir -p /home/sysadm/.ssh/

echo "Paste the cryptic text from your local SSH public key:"
key=`cat`
echo "$key" > /home/sysadm/.ssh/authorized_keys

chmod 700 /home/sysadm/.ssh
chmod 600 /home/sysadm/.ssh/authorized_keys
chown -R sysadm:sysadm /home/sysadm

echo "Backing up old SSH config file and replacing with new one"
mv /etc/ssh/sshd_config sshd_config.bak
cp sshd_config /etc/ssh/

echo "Restarting SSH service"
service sshd restart

echo "Stopping and removing iptables"
service iptables stop
systemctl disable iptables
apt remove --purge --auto-remove iptables -y

echo "Installing nftables"
apt update -y && apt install nftables -y

echo "Backing up nftables config file"
mv /etc/nftables.conf nftables.conf.bak

cp nftables.conf /etc/

echo "Enabling and starting nftables"
systemctl enable nftables
service nftables start

echo "Finished initial set-up"

# Docker
echo "Setting up Docker"

echo "Installing software common properties"
apt install software-properties-common -y

echo "Installing curl"
apt install curl -y

echo "Installing gnugpg"
apt install gnupg -y

echo "Adding apt repo key"
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
curl -fsSL https://download.docker.com/linux/debian/gpg -o /tmp/docker
gpg --dearmor /tmp/docker
cp /tmp/docker.gpg /etc/apt/trusted.gpg.d/docker.gpg
rm -rf /tmp/docker /tmp/docker.gpg

echo "Installing docker-ce"
apt update -y && apt install docker-ce aufs-tools- -y

echo "Setting default docker DNS"
echo "{
  \"dns\": [
     \"8.8.8.8\",
     \"8.8.4.4\",
     \"1.1.1.1\",
     \"1.0.0.1\"
  ]
}" >> /etc/docker/daemon.json

echo "Disabling iptables for Docker"
echo "DOCKER_OPTS=\"--iptables=false\"" >> /etc/default/docker

echo "Overriding Docker config"
mkdir -p /etc/systemd/system/docker.service.d/
echo "[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --iptables=false --ipv6 --bip 172.17.0.1/16 --fixed-cidr=172.17.0.0/16 --fixed-cidr-v6=2a01::/48
ExecStartPost=/usr/sbin/nft -f /etc/nftables.conf" > /etc/systemd/system/docker.service.d/override.conf

echo "Enabling and restarting Docker service"
systemctl daemon-reload
systemctl enable docker
service docker restart

echo "Adding sysadm to Docker group"
usermod -a -G docker sysadm

echo "Installing docker-compose"
apt install libffi-dev -y
apt install python3 python3-pip python3-setuptools -y
pip3 install docker-compose

echo "Restarting nftables and checking rules"
service nftables restart
nft list ruleset

echo "Finished Docker installation"

exit
