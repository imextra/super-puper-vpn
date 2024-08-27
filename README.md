# SUPER PUPER VPN

## Introduction

This is a fast way to run your own VPN server on Ubuntu / Debian with IPsec IKEv2 protocol connection. Easy to install: download script file and run it to install all components and configure VPS server.

For ios, macos devises you can connect to VPS server via certificates (super easy way), for others (android, windows, keenetic) - via login and password.


## Requirements

- Ubuntu 22.04 LTS or Debian 12
- strongSwan & plugins
- iptables
- zsh

## Installation

Download files (`vpn-setup.sh` and `mobileconfig.sh`) and run `vpn-setup.sh`.

    sudo apt install wget
    wget https://raw.githubusercontent.com/imextra/super-puper-vpn/main/vpn-setup.sh
    wget https://raw.githubusercontent.com/imextra/super-puper-vpn/main/mobileconfig.sh
    chmod u+x vpn-setup.sh
    sh vpn-setup.sh

What `vpn-setup.sh` do:
* update and upgrade system files
* install require packages 
* create certificates (root, server, device)
* configure ipsec for strongSwan
* configure iptables

What `mobileconfig.sh` do:
* create iphone.mobileconfig for you ios, macos devises.

Default `login:password`'s data:
* user1:pass1
* user2:pass2
* keenetic:keenetic

To add yours - edit file `/etc/ipsec.secrets` and restart ipsec by command `ipsec restart`


    
### More info
[[EN] How to create your personal VPN server to use on iPhone, iPad and Mac. Comprehensive tutorial.](https://medium.com/@olegborisov_45091/how-to-create-your-personal-vpn-server-to-use-on-iphone-ipad-and-mac-comprehensive-tutorial-734ede9d99e4)

[[EN] Tutorial: how to create a personal VPN server based on Linux Debian, strongSwan, certificates authentification and ready to use .mobileconfig profiles to use on iPhone, iPad and Mac](https://gist.github.com/borisovonline/955b7c583c049464c878bbe43329a521)

[[RU] Создаем свой VPN-сервер. Пошаговая инструкция](https://vc.ru/dev/66942-sozdaem-svoi-vpn-server-poshagovaya-instrukciya#8)

[[EN] How to Set Up an IKEv2 VPN Server with StrongSwan on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-20-04)

[[RU] Настраиваем собственный IKEv2/IPSec VPN-сервер в Европе с помощью strongSwan](https://www.youtube.com/watch?v=93oJ5fF1mE0)

[[RU] Подключение к VPN IKEv2/IPsec из Windows. (youtube)](https://www.youtube.com/watch?v=RiZqopVcd2k)

[[RU] Как подключится к ikev2/ipsec из Windows (text)](https://simplelinux.ru/kak-podklyuchitsya-k-ikev2-ipsec-iz-windows/)

[[RU] Настройка VPN на роутере для определённых сайтов (Маршрутизация по IP)](https://www.youtube.com/watch?v=8UZ8eA9FiIY)

[[RU] Диапазон IP-адресов Instagram, Netflix, ChatGPT, Youtube, Twitter](https://rockblack.su/vpn/dopolnitelno/diapazon-ip-adresov)
