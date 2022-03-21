#!/usr/bin/env bash

set -o errtrace -o nounset -o pipefail -o errexit

SERVER_IPV4=

PORT="443"
PROTOCOL="udp"

if [[ "$(whoami)" != "root" ]]; then
  echo
  echo "Run as root user! Aborting now, please run script again as root user."
  echo
  exit 1
fi

if [[ -z "$SERVER_IPV4" ]]; then
  echo
  echo "Please set the server IPv4 address and run again."
  echo
  exit 1
fi

NIC=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)

# Ensure that the $NIC exists.
if [[ -z $NIC ]]; then
  echo
  echo "It could not detect public network interface. Please set it manually."
  echo
  exit 1
fi

# Find out if the machine uses nogroup or nobody
# for the permissionless group.
if grep -qs "^nogroup:" /etc/group; then
  NOGROUP=nogroup
else
  NOGROUP=nobody
fi

CIPHER="AES-128-GCM"
CERT_CURVE="prime256v1"
CC_CIPHER="TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256"
DH_CURVE="prime256v1"
HMAC_ALG="SHA256"

cd /etc/openvpn/easy-rsa/ || return

#
# Set Easy RSA Variables
#

echo "set_var EASYRSA_ALGO ec" > vars
echo "set_var EASYRSA_CURVE $CERT_CURVE" >> vars

# Generate a random, alphanumeric identifier of 15
# characters for CN and  one for server name
SERVER_CN="cn_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"
echo "$SERVER_CN" > SERVER_CN_GENERATED

SERVER_NAME="server_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)"
echo "$SERVER_NAME" > SERVER_NAME_GENERATED

echo "set_var EASYRSA_REQ_CN $SERVER_CN" >> vars

# Create the PKI, set up the CA, the DH params
# and the server certificate.
./easyrsa init-pki
./easyrsa --batch build-ca nopass

./easyrsa build-server-full "$SERVER_NAME" nopass
EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl

# Generate tls-crypt key
openvpn --genkey --secret /etc/openvpn/tls-crypt.key

# Move all the generated files
cp pki/ca.crt pki/private/ca.key "pki/issued/$SERVER_NAME.crt" "pki/private/$SERVER_NAME.key" /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn

# Make cert revocation list readable for non-root
chmod 644 /etc/openvpn/crl.pem

# Create client-config-dir dir
mkdir -p /etc/openvpn/ccd

# Create log dir
mkdir -p /var/log/openvpn

# Generate server.conf
cat <<-EOF > /etc/openvpn/server.conf
port $PORT
proto $PROTOCOL
dev tun
group $NOGROUP
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.13.23.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 94.140.14.14"
push "dhcp-option DNS 94.140.15.15"
push "redirect-gateway def1 bypass-dhcp"
dh none
ecdh-curve $DH_CURVE
tls-crypt tls-crypt.key 0
crl-verify crl.pem
ca ca.crt
cert $SERVER_NAME.crt
key $SERVER_NAME.key
auth $HMAC_ALG
cipher $CIPHER
ncp-ciphers $CIPHER
tls-server
tls-version-min 1.2
tls-cipher $CC_CIPHER
client-config-dir /etc/openvpn/ccd
status /var/log/openvpn/status.log
verb 3
EOF

# Generate client-template.txt, so we have a template
# to add users later on.
cat <<-EOF > /etc/openvpn/client-template.txt
client
proto $PROTOCOL
explicit-exit-notify
remote $SERVER_IPV4 $PORT
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name $SERVER_NAME name
auth $HMAC_ALG
auth-nocache
cipher $CIPHER
tls-client
tls-version-min 1.2
tls-cipher $CC_CIPHER
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns
status-version 2
verb 3
EOF
