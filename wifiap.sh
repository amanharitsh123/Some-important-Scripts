#!/bin/sh
#Script Made By : Aman Sharma (amanharitsh123@gmail.com)
#Reference : https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md
if [ "$(id -u)" -ne "0" ] ; then
  echo "error: this script must be executed with root privileges!"
  exit 1
fi

#Stopping the Service
systemctl stop dnsmasq
systemctl stop hostapd

#Configuring Static IP

echo -e "interface wlan0\nstatic ip_address=192.168.4.1/24" >> /etc/dhcpcd.conf
service dhcpcd restart

#Configuring the DHCP server

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

echo -e  "interface=wlan0\ndhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h" >> /etc/dnsmasq.conf

#Configuring the access point host software(hostapd)

echo -e "interface=wlan0
bridge=br0
ssid=NameOfNetwork
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=AardvarkBadgerHedgehog
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf

echo DAEMON_CONF="/etc/hostapd/hostapd.conf" >> /etc/default/hostapd

#ADD ROUTING AND MASQUERADE

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"

sed '/exit 0/d'  /etc/rc.local
echo -e "iptables-restore < /etc/iptables.ipv4.nat\nexit 0" >> /etc/rc.local

#Bridge Connection with ethernet 

echo -e "denyinterfaces wlan0\ndenyinterfaces eth0" >> /etc/dhcpcd.conf

#adding a new bridge
brctl addbr br0
 
#connect ports
brctl addif br0 eth0

# Bridge setup
echo -e "auto br0\niface br0 inet manual\nbridge_ports eth0 wlan0" >> /etc/network/interfaces
