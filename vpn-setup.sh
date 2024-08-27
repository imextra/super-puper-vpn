#!/bin/bash

# ===================
# Requirements:
# - Ubuntu 22.04 LTS / Debian 12
# - Strongswan & plugins
# - iptables
# - zsh
# ===================

echo "================================"
echo "Script started"
echo "================================"
echo


echo "Update system..."
apt update -y
echo "================================"
echo "Update is done!"
echo "================================"
echo


echo "Upgrade system..."
apt upgrade -y
echo "================================"
echo "Upgrade is done!"
echo "================================"
echo


echo "Install components..."
apt install strongswan strongswan-pki -y
apt install libstrongswan-standard-plugins libstrongswan-extra-plugins libcharon-extra-plugins libcharon-extauth-plugins libtss2-tcti-tabrmd0 -y
apt install zsh iptables-persistent -y
echo "================================"
echo "Install components is done!"
echo "================================"
echo


# set (find) my external IP
myip=$(wget -qO - eth0.me)
echo "My IP: $myip"
echo


echo "$ ip route show default:"
ip route show default
echo

while [ "$networkInterfaceConfirmation" != "Y" ]
do
  read -p "Enter network interface: " -r networkInterface
  echo
  read -p "Network Interface is $networkInterface. Are you sure? (Y/n): " -r networkInterfaceConfirmation
  echo
done


#echo "Go to /etc/ipsec.d/"
#cd /etc/ipsec.d
#echo
echo "Create ./pki/{folders}"
mkdir -p ./pki/private
mkdir -p ./pki/cacerts
mkdir -p ./pki/certs
chmod 700 ./pki
echo "Done!"
echo


# StrongSwan PKI Docs 
# https://docs.strongswan.org/docs/5.9/pki/pki.html

echo "Root certificate CA (Certificate Authority), which will issue other certificates. Create it in a (ca-cert.pem) file:"
pki --gen --type rsa --size 4096 --outform pem > ./pki/private/ca-key.pem

pki --self --ca --lifetime 3650 --in ./pki/private/ca-key.pem \
	--type rsa --digest sha256 \
	--dn "CN=$myip" \
	--outform pem > ./pki/cacerts/ca-cert.pem
echo "Created ./pki/private/ca-key.pem"
echo "Created ./pki/cacerts/ca-cert.pem"
echo

echo "Create server’s private key certificate in the (server-cert.pem) file:"
pki --gen --type rsa --size 4096 --outform pem > ./pki/private/server-key.pem

pki --pub --in ./pki/private/server-key.pem --type rsa |
	pki --issue --lifetime 3650 --digest sha256 \
		--cacert ./pki/cacerts/ca-cert.pem \
		--cakey ./pki/private/ca-key.pem \
		--dn "CN=$myip" \
		--san @$myip --san $myip \
		--flag serverAuth --flag ikeIntermediate \
		--outform pem > ./pki/certs/server-cert.pem
echo "Created ./pki/private/server-key.pem"
echo "Created ./pki/certs/server-cert.pem"
echo

echo "Create the certificate for our devices in the (me.pem) file"
pki --gen --type rsa --size 4096 --outform pem > ./pki/private/me.pem

pki --pub --in ./pki/private/me.pem --type rsa |
	pki --issue --lifetime 3650 --digest sha256 \
		--cacert ./pki/cacerts/ca-cert.pem \
		--cakey ./pki/private/ca-key.pem \
		--dn "CN=me" \
		--san me \
		--flag clientAuth \
		--outform pem > ./pki/certs/me.pem
echo "Created ./pki/private/me.pem"
echo "Created ./pki/certs/me.pem"
echo

echo "Copy ./pki/* to /etc/ipsec.d/"
cp -r ./pki/* /etc/ipsec.d/
echo

echo "Remove folder ./pki/"
rm -rf ./pki/
echo


echo "Save ipsec.conf to ipsec.conf.original"
cp /etc/ipsec.conf /etc/ipsec.conf.original
echo

# IPSEC Docs
# https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf

echo "Set new config to ipsec.conf"
cat << EOF > /etc/ipsec.conf
config setup
	charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2,  mgr 2"
	uniqueids=never

conn %default
	auto=add
	dpdaction=clear
	fragmentation=yes
	keyexchange=ikev2
	rekey=no
	type=tunnel
	left=%any
	leftid=$myip
	leftsourceip=$myip
	leftsubnet=0.0.0.0/0
	leftcert=server-cert.pem
	leftsendcert=always
	right=%any
	rightdns=8.8.8.8,8.8.4.4
	rightsourceip=10.10.10.0/24

conn ikev2-password
	compress=no
	dpddelay=300s
	eap_identity=%identity
	esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!
	forceencaps=yes
	ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024,aes256-sha256-modp2048!
	rightauth=eap-mschapv2
	rightid=%any
	rightsendcert=never

conn ikev2-pubkey
	compress=yes
	dpddelay=30s
	esp=aes256-sha256-modp2048!
	forceencaps=no
	ike=aes256-sha256-modp2048!
	leftauth=pubkey
	rightauth=pubkey
EOF
echo


echo "Set data to /etc/ipsec.secrets"
cat << EOF > /etc/ipsec.secrets
: RSA server-key.pem
# your_username : EAP "your_password" - use this format for create new user
# sudo systemctl restart strongswan-starter - for the changes to take effect, after adding a new user, close the file and restart the server with this command
user1 : EAP "pass1"
user2 : EAP "pass2"
keenetic : EAP "keenetic"
EOF
echo


echo "Restart ipsec"
ipsec restart
echo "Done!"
echo


echo "Configure a core network parameters at file (sysctl.conf)"
echo
echo "Make a copy of /etc/sysctl.conf to /etc/sysctl.conf.original"
cp /etc/sysctl.conf /etc/sysctl.conf.original
echo

echo "Set a new config data to /etc/sysctl.conf"
cat << EOF >> /etc/sysctl.conf

# New config data
net.ipv4.ip_forward=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.ip_no_pmtu_disc=1

EOF


sysctl -p
echo


ls -lah ./pki/private/
ls -lah ./pki/certs/
ls -lah ./pki/cacerts/
echo 

echo "less /etc/ipsec.conf"
echo

echo "less /etc/ipsec.secrets"
echo

echo "less /etc/sysctl.conf"
echo


echo "Install iptables settings..."
echo
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -Z

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

iptables -A INPUT -i lo -j ACCEPT

iptables -A INPUT -p udp --dport  500 -j ACCEPT
iptables -A INPUT -p udp --dport 4500 -j ACCEPT

iptables -A FORWARD --match policy --pol ipsec --dir in  --proto esp -s 10.10.10.0/24 -j ACCEPT
iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT

iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $networkInterface -m policy --pol ipsec --dir out -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $networkInterface -j MASQUERADE

iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o $networkInterface -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360

iptables -A INPUT -j DROP
iptables -A FORWARD -j DROP

echo "Iptables settings done!"
echo 

netfilter-persistent save
echo 

netfilter-persistent reload
echo 


while [ "$configFileGeneratorConfirmation" != "Y" ]
do
  read -p "Please confirm, that file (mobileconfig.sh) is downloaded. Are you sure? (Y/n): " -r configFileGeneratorConfirmation
  echo
done

chmod u+x mobileconfig.sh

echo "Generate config file iphone.mobileconfig"
./mobileconfig.sh > iphone.mobileconfig
echo "Done!"
echo
echo


echo "================================"
echo "NEXT STEPS:"
echo "1.1. Save file iphone.mobileconfig."
echo "1.1. Upload file to devices."
echo "1.2.1. Iphone"
echo "Move iphone.mobileconfig via AirDrop and Install Profile"
echo "1.2.2. Mac"
echo "Got to Settings -> Profile -> Add Profile"
echo "2.1. Save certificate (/etc/ipsec.d/./pki/cacerts/ca-cert.pem) to file."
echo "2.2. Upload file to Windows / Routers / Android."
echo "2.3. Use it with username & password from /etc/ipsec.secrets"
echo "3. Reboot server for applying all settings"
echo "================================"
echo 


echo "cat /etc/ipsec.d/cacerts/ca-cert.pem"
echo

cat /etc/ipsec.d/cacerts/ca-cert.pem
echo
echo 


echo "================================"
echo "Script finished!"
echo "NEED TO BE REBOOTED"
echo "================================"
echo
echo "reboot"
echo