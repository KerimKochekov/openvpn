# Openvpn
## Before start, set local SSH keys
```bash
$ ssh-keygen -t ed25519 -C 'sysadm' -f ~/.ssh/sysadm_ed25519
$ ssh-keygen -t rsa -b 4096 -C 'sysadm' -f ~/.ssh/sysadm_rsa
```

## How to SSH to server?
```bash
$ ssh root@<server-ip>
```

## Start setting vpn
Before start assign SERVER_IPV4 to your server ip in "openvpn_install.sh" and give permission to "setup.sh" with following command:
```bash
$ chmod +x setup.sh
```
Now, SSH to server and run script:
```bash
$ ./setup.sh
```
Once **Paste the cryptic text from your local SSH public key:** appears on screen, copy and paste public SSH key to it (for example, in my case: *cat /home/kerim/.ssh/sysadm_ed25519.pub*) and Ctrl+D to move forward.

Later, SSH to server once again and run other script:
```bash
$ ./openvpn.sh
```
Create user account with some name <username>
```bash
$ ./openvpn_adduser.sh <username>
```
Delete user account in case of you need:
```bash
$ ./openvpn_removeuser.sh
```
Check whether vpn user has been created:
```bash
$ ls /opt/profiles/
```
If yes, exit from server and pull created openvpn account to your local machine with SCP protocol:
```bash
$ scp -P 2219 sysadm@<server-ip>:/opt/profiles/<username>.ovpn ~/Desktop/
```
Now you can view your created openvpn user in your Desktop, congrats!
  

### Nginx reverse proxy
First install nginx:

```bash
$ sudo apt install nginx
```

Redirect requests to your preferred server, e.g., add 

`return 301 https://www.google.com/;` after 
```
listen 80 default_server;
listen [::]:80 default_server;
```
in `/etc/nginx/sites-available/default`. 

Save and restart nginx: 

```bash
$ sudo systemctl status nginx
```

Test if visiting your server IP in your browser redirects HTTP requests.

### Reference
[Original link](https://stream3.morazow.com/)
