# Openvpn
Before start assign SERVER_IPV4 to your server ip in "openvpn_install.sh" and give permission to "setup.sh".
```bash
bar@foo$:chmod +x setup.sh
```
SSH to server and run script:
```bash
bar@foo$:./setup.sh
```
SSH to server once again and run other script:
```bash
bar@foo$:./openvpn.sh
```
Create user account with some name <username>
```bash
bar@foo$:./openvpn_adduser.sh <username>
```
Check whether vpn user has been created:
```bash
bar@foo$:ls /opt/profiles/
```
If yes, exit from server and pull created openvpn account with name <username> to your local machine with SCP protocol:
```bash
bar@foo$:scp oldtown:/opt/profiles/<username>.ovpn ~/Desktop/
```
Now you can view your created openvpn user in your Desktop, congrats!
  
### Reference
[Original link](https://stream3.morazow.com/)
