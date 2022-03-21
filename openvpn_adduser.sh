#!/usr/bin/env bash

set -o errtrace -o pipefail -o errexit

NAME=$1
if [[ -z "$NAME" ]]; then
  echo
  echo "The user name is empty. Please provide a name and run again."
  echo
  exit 1
fi

# EXISTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c -E "/CN=$NAME\$")
# if [[ $EXISTS == '1' ]]; then
#   echo
#   echo "The specified user was already created, please choose another name."
#   echo
#   exit 1
# fi

echo "Creating a profile for: $NAME"

cd /etc/openvpn/easy-rsa/
./easyrsa build-client-full "$NAME" nopass

PROFILE_DIR="/opt/profiles/"
mkdir -p "$PROFILE_DIR"

# Generate the user $NAME.ovpn file
cp /etc/openvpn/client-template.txt "$PROFILE_DIR/$NAME.ovpn"
{
   echo "<ca>"
   cat "/etc/openvpn/easy-rsa/pki/ca.crt"
   echo "</ca>"

   echo "<cert>"
   awk '/BEGIN/,/END/' "/etc/openvpn/easy-rsa/pki/issued/$NAME.crt"
   echo "</cert>"

   echo "<key>"
   cat "/etc/openvpn/easy-rsa/pki/private/$NAME.key"
   echo "</key>"

   echo "<tls-crypt>"
   cat /etc/openvpn/tls-crypt.key
   echo "</tls-crypt>"
} >> "$PROFILE_DIR/$NAME.ovpn"

echo
echo "The profile file for use '$NAME' has been written to $PROFILE_DIR/$NAME.ovpn."
echo "Download the .ovpn file and import it into OpenVPN client application."
echo
