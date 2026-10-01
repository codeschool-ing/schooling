#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of networks-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Open vSwitch 3.3 with the userspace datapath, on sw1, and OS-Ken 4.2.2 as the
# controller, on ctl, speaking OpenFlow 1.3. Each controller is stopped with
# SIGTERM, the way a service manager stops one: OS-Ken 4.2.2's own handler for
# Ctrl-C raises an AttributeError in run_apps and leaves the process running.
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# itself, built by lab.sh reset; the files ana wrote (put below), whose
# contents the lesson shows; the waits for the switch to connect to each
# controller; stopping each controller; and the 35 seconds waited after the last one stops,
# which the lesson says.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat SYSTEMD_PAGER=cat COLUMNS=100
LAB_SH=${LAB_SH:-/var/tmp/lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on HOST 'command': what ana typed at her prompt on one machine, and what it printed.
on() {
  local h=$1; shift
  printf 'ana@%s:~$ %s\n' "$h" "$*"
  lab exec "$h" ana "$*" 2>&1 || true
}
# The same, run as root and not shown: the lab's own housekeeping.
quiet() { local h=$1; shift; lab exec "$h" root "$*" >/dev/null 2>&1 || true; }
# put PATH: a file ana wrote on ctl, from stdin. Its content is shown in the lesson.
put() { lab exec ctl ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
# typed ROUTER 'line' ...: an interactive SSH session from ctl to a router's CLI,
# each line typed at the prompt, and the terminal as it looked afterwards.
typed() {
  local h=$1; shift
  printf 'ana@ctl:~$ ssh netops@%s\n' "$h"
  local script='sleep 1.2;' l
  for l in "$@"; do script+=" printf '%s\\n' '$l'; sleep 0.5;"; done
  lab exec ctl ana "( $script ) | ssh -tt netops@$h 2>&1 | tr -d '\\r'" || true
}
block() { printf '##### %s\n' "$1"; }
# A command left running on one machine while others are typed, the way a
# second terminal would be: its prompt and output are printed when it ends.
bgon() {
  printf 'ana@%s:~$ %s\n' "$1" "$2" > /tmp/bg.out
  lab exec "$1" ana "$2" >> /tmp/bg.out 2>&1 &
  BG=$!
  sleep "${3:-1.5}"
}
fgon() { wait "$BG"; cat /tmp/bg.out; rm -f /tmp/bg.out; }

lab reset
lab exec ctl ana 'mkdir -p sdn'
put sdn/learning.py <<'CODE'
from os_ken.base import app_manager
from os_ken.controller import ofp_event
from os_ken.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER, set_ev_cls
from os_ken.lib.packet import ethernet, packet
from os_ken.ofproto import ofproto_v1_3


class Learning(app_manager.OSKenApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.where = {}  # MAC address -> switch port, learnt from traffic

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def connected(self, ev):
        dp = ev.msg.datapath
        parser, ofp = dp.ofproto_parser, dp.ofproto
        self.flow(dp, 0, parser.OFPMatch(), [parser.OFPActionOutput(ofp.OFPP_CONTROLLER, ofp.OFPCML_NO_BUFFER)])
        self.logger.info("switch %016x connected", dp.id)

    def flow(self, dp, priority, match, actions, idle=0):
        parser, ofp = dp.ofproto_parser, dp.ofproto
        inst = [parser.OFPInstructionActions(ofp.OFPIT_APPLY_ACTIONS, actions)]
        dp.send_msg(parser.OFPFlowMod(datapath=dp, priority=priority, match=match, instructions=inst,
                                      idle_timeout=idle))

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def packet_in(self, ev):
        msg = ev.msg
        dp, parser, ofp = msg.datapath, msg.datapath.ofproto_parser, msg.datapath.ofproto
        port = msg.match["in_port"]
        eth = packet.Packet(msg.data).get_protocol(ethernet.ethernet)
        self.where[eth.src] = port
        out = self.where.get(eth.dst, ofp.OFPP_FLOOD)
        actions = [parser.OFPActionOutput(out)]
        if out != ofp.OFPP_FLOOD:
            self.flow(dp, 10, parser.OFPMatch(in_port=port, eth_dst=eth.dst), actions, idle=30)
            self.logger.info("flow: in_port %d to %s -> port %d", port, eth.dst, out)
        dp.send_msg(parser.OFPPacketOut(datapath=dp, buffer_id=ofp.OFP_NO_BUFFER, in_port=port,
                                        actions=actions, data=msg.data))
CODE
put sdn/policy.py <<'CODE'
from os_ken.base import app_manager
from os_ken.controller import ofp_event
from os_ken.controller.handler import CONFIG_DISPATCHER, set_ev_cls
from os_ken.ofproto import ofproto_v1_3

BLOCKED = [("203.0.113.131", "203.0.113.129")]  # h3 may not reach h1


class Policy(app_manager.OSKenApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def connected(self, ev):
        dp = ev.msg.datapath
        parser = dp.ofproto_parser
        for src, dst in BLOCKED:
            match = parser.OFPMatch(eth_type=0x0800, ipv4_src=src, ipv4_dst=dst)
            dp.send_msg(parser.OFPFlowMod(datapath=dp, priority=100, match=match, instructions=[]))
            self.logger.info("policy: drop %s -> %s", src, dst)
CODE
put sdn/controller.py <<'CODE'
import logging
import sys

from os_ken import cfg
from os_ken.base.app_manager import AppManager

cfg.CONF(args=["--ofp-listen-host", "192.0.2.10", "--ofp-tcp-listen-port", "6653"], project="os_ken")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s", datefmt="%H:%M:%S")
AppManager.run_apps(sys.argv[1:])
CODE

block empty
on sw1 'ovs-vsctl show'
on sw1 'ovs-ofctl -O OpenFlow13 dump-flows br0'
on h1 'ping -c 2 -W 1 203.0.113.130'
block manual
on sw1 'ovs-ofctl -O OpenFlow13 add-flow br0 "priority=10,in_port=1,actions=output:2" && ovs-ofctl -O OpenFlow13 add-flow br0 "priority=10,in_port=2,actions=output:1"'
on h1 'ping -c 2 203.0.113.130'
on h1 'ping -c 2 -W 1 203.0.113.131'
on sw1 'ovs-ofctl -O OpenFlow13 dump-flows br0'
on sw1 'ovs-ofctl -O OpenFlow13 del-flows br0'
block controller
bgon ctl 'cd sdn && python controller.py learning' 3
on sw1 'ovs-vsctl set-controller br0 tcp:192.0.2.10:6653'
sleep 3
on sw1 'ovs-vsctl list controller | grep -E "^(target|is_connected)"'
on h1 'ping -c 3 203.0.113.130'
on sw1 'ovs-ofctl -O OpenFlow13 dump-flows br0'
quiet ctl 'pkill -TERM -f "^python controller.py learning$"'
block controller-log
fgon
block policy
bgon ctl 'cd sdn && python controller.py learning policy' 12
on h3 'ping -c 2 -W 1 203.0.113.129'
on h3 'ping -c 2 203.0.113.130'
on sw1 'ovs-ofctl -O OpenFlow13 dump-flows br0 | grep -E "priority=(100|0)"'
quiet ctl 'pkill -TERM -f "^python controller.py learning policy$"'
block policy-log
fgon
block down
sleep 2
on sw1 'ovs-vsctl list controller | grep -E "^(target|is_connected)"'
on h1 'ping -c 2 203.0.113.130'
sleep 35
block down-later
on h1 'ping -c 2 -W 1 203.0.113.130'
on sw1 'ovs-ofctl -O OpenFlow13 dump-flows br0'
