#!/usr/bin/env bash
# KALI: static SOC-LAB profile on eth1, never becomes the default route
sudo nmcli connection add type ethernet ifname eth1 con-name SOC-LAB \
  ipv4.method manual ipv4.addresses 10.10.10.30/24 ipv4.never-default yes \
  ipv6.method disabled
sudo nmcli connection up SOC-LAB
ip -br a && ip route
