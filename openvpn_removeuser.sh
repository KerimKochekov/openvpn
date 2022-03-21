#!/usr/bin/env bash

set -o errtrace -o pipefail -o errexit

NUM_USERS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
if [[ $NUM_USERS == '0' ]]; then
  echo
  echo "No user profiles exist! Exiting."
  echo
  exit 1
fi

echo "Select the existing user name to revoke:"
echo

tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
until [[ $USER_NUMBER -ge 1 && $USER_NUMBER -le $NUM_USERS ]]; do
if [[ $USER_NUMBER == '1' ]]; then
  read -rp "Select one client [1]: " USER_NUMBER
else
      read -rp "Select one client [1-$NUM_USERS]: " USER_NUMBER
fi
done

USER=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$USER_NUMBER"p)

cd /etc/openvpn/easy-rsa/ || return

./easyrsa --batch revoke "$USER"
EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
rm -f /etc/openvpn/crl.pem
cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
chmod 644 /etc/openvpn/crl.pem

find /opt/profiles/ -maxdepth 2 -name "$USER.ovpn" -delete
sed -i "/^$USER,.*/d" /etc/openvpn/ipp.txt

echo
echo "User '$USER' profile has been removed."
echo
