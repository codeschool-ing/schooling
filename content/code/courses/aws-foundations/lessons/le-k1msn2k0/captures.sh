#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of aws-foundations (Site-to-Site VPN
# and Direct Connect), as a script that produces them. The student never sees
# this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Read out of the lessons: the setup is the ```sh fence of "site-to-site-vpn";
# ops.py is lesson 22's (le-56k30bbg, "zones-and-price", its ```python fence),
# which this lesson reuses.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types everything into ONE shell, where `cgw=...`, `vgw=...`,
#     `vpn=...` and `dx=...` stay set. Here each command runs in a shell of its
#     own, so an assignment is printed with its prompt, run once in this
#     script's shell and exported;
#   - the AWS CLI retries an answer of 500 before it gives up, so the commands
#     moto cannot answer take a few seconds; nothing else was done to them;
#   - ops.py is removed from ~/aws at the end.
#
# ONE COMMAND REACHES AWS, with no key: price.py downloads the public price
# list. There is no router: the office's side of every tunnel, BGP, a packet
# through either road, a failover and the LOA are described from AWS's
# documentation and not produced here.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
L22="$HERE/../le-56k30bbg/zones-and-price.md"
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
trap 'moto_stop; rm -f ~/aws/ops.py' EXIT

assign() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$1"; eval "export $1"; }

# ---- site-to-site-vpn --------------------------------------------------------
# shellcheck disable=SC1090
. <(sh_fences "$HERE/site-to-site-vpn.md" 1)
export vpc subnet rt
cd ~/aws || exit 1

block cgw
run 'aws ec2 create-customer-gateway --type ipsec.1 --public-ip 203.0.113.12 --bgp-asn 65000 --device-name office-router'

block cgw-var
assign 'cgw=$(aws ec2 describe-customer-gateways --query "CustomerGateways[0].CustomerGatewayId" --output text)'

block vgw
run 'aws ec2 create-vpn-gateway --type ipsec.1 --amazon-side-asn 64512 --query "VpnGateway.[VpnGatewayId,AmazonSideAsn,State]" --output text'

block attach
assign 'vgw=$(aws ec2 describe-vpn-gateways --query "VpnGateways[0].VpnGatewayId" --output text)'
run 'aws ec2 attach-vpn-gateway --vpn-gateway-id $vgw --vpc-id $vpc'

block vpn
run 'aws ec2 create-vpn-connection --type ipsec.1 --customer-gateway-id $cgw --vpn-gateway-id $vgw --query "VpnConnection.[VpnConnectionId,State,Type]" --output text'

block vpn-var
assign 'vpn=$(aws ec2 describe-vpn-connections --query "VpnConnections[0].VpnConnectionId" --output text)'

block tunnels
run 'aws ec2 describe-vpn-connections --vpn-connection-ids $vpn --query "VpnConnections[0].CustomerGatewayConfiguration" --output text | grep -E "ipsec_tunnel>|<ip_address>|<asn>"'

block telemetry
run 'aws ec2 describe-vpn-connections --vpn-connection-ids $vpn --query "VpnConnections[0].[Options.StaticRoutesOnly,VgwTelemetry]"'

block propagation
run 'aws ec2 enable-vgw-route-propagation --route-table-id $rt --gateway-id $vgw'

block static
run 'aws ec2 create-route --route-table-id $rt --destination-cidr-block 192.168.0.0/16 --gateway-id $vgw --query Return --output text'

block routes
run 'aws ec2 describe-route-tables --route-table-ids $rt --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId,Origin]" --output text'

# ---- direct-connect ----------------------------------------------------------
block locations
run 'aws directconnect describe-locations'

block connection
run 'aws directconnect create-connection --location TNDB --bandwidth 1Gbps --connection-name shop-dx-1 --query "[connectionId,connectionState,location,bandwidth,awsDevice]" --output text'

block dx-var
assign 'dx=$(aws directconnect describe-connections --query "connections[0].connectionId" --output text)'

block vif
run 'aws directconnect create-private-virtual-interface --connection-id $dx --new-private-virtual-interface virtualInterfaceName=shop-prod,vlan=101,asn=65000,virtualGatewayId=$vgw,addressFamily=ipv4'

# ---- resilience-and-price ----------------------------------------------------
block second
run 'aws directconnect create-connection --location TIVIT --bandwidth 1Gbps --connection-name shop-dx-2 --query "[connectionName,location,connectionState]" --output text'

block both
run 'aws directconnect describe-connections --query "connections[].[connectionName,location,bandwidth]" --output text'

rm -f ~/.cache/aws-prices/AWSDirectConnect-*
block price-vpn
run 'python3 price.py AmazonVPC 20260917190528 sa-east-1 SAE1-VPN-Usage-Hours:ipsec.1'

fences python "$L22" 1 > ~/aws/ops.py || exit 1
block ops-tgw
run 'python3 ops.py AmazonVPC 20260917190528 sa-east-1 SAE1-TransitGateway-Hours SAE1-TransitGateway-Bytes'

block price-dx
run 'python3 price.py AWSDirectConnect 20260917204010 sa-east-1 SAE1-TNDB-PortUsage:1G SAE1-TNDB-PortUsage:10G SAE1-TNDB-HCPortUsage:1G SAE1-TNDB-DataXfer-Out:dc.3'
