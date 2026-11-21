# WIN-ENDPOINT-01 (Administrator PowerShell)
# Static SOC-LAB address on Ethernet1: no gateway, no DNS
Set-NetIPInterface -InterfaceAlias "Ethernet1" -Dhcp Disabled
New-NetIPAddress -InterfaceAlias "Ethernet1" -IPAddress 10.10.10.20 -PrefixLength 24

# Allow ping only from the lab subnet (firewall stays ON)
New-NetFirewallRule -DisplayName "SOC-LAB Allow ICMPv4" `
  -Direction Inbound -Protocol ICMPv4 -IcmpType 8 `
  -RemoteAddress 10.10.10.0/24 -Action Allow

Get-NetIPConfiguration -InterfaceAlias "Ethernet1"
