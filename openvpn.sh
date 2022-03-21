#!/bin/bash

docker ps -a
docker-compose --version

apt install ca-certificates gnupg openssl
apt install openvpn -y

wget -O /tmp/easy-rsa.tgz https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz
mkdir -p /etc/openvpn/easy-rsa
tar xzf /tmp/easy-rsa.tgz --strip-components=1 --directory /etc/openvpn/easy-rsa
rm -f /tmp/easy-rsa.tgz

chmod +x openvpn_install.sh
./openvpn_install.sh

systemctl enable openvpn
service openvpn start

rm -rf /etc/nftables.conf

cp nftables1.conf /etc/
mv /etc/nftables1.conf /etc/nftables.conf

service nftables restart
service openvpn restart

chmod +x openvpn_adduser.sh
chmod +x openvpn_removeuser.sh

echo "Installation done"
