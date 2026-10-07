---
title: A controller that learns
version: 2
---

A controller is a server the switches connect to. OS-Ken listens on `ctl`'s management address and
runs the applications it is given:

```schooling-example
{
  "language": "python",
  "file": "controller.py",
  "parts": [
    {
      "code": "import logging\nimport sys\n\nfrom os_ken import cfg\nfrom os_ken.base.app_manager import AppManager\n"
    },
    {
      "code": "cfg.CONF(args=[\"--ofp-listen-host\", \"192.0.2.10\", \"--ofp-tcp-listen-port\", \"6653\"], project=\"os_ken\")\nlogging.basicConfig(level=logging.INFO, format=\"%(asctime)s %(message)s\", datefmt=\"%H:%M:%S\")\nAppManager.run_apps(sys.argv[1:])",
      "note": "**The controller is a program with an address.** It listens on ctl's management address for switches, on 6653, the port IANA assigned to OpenFlow, and runs the applications it is given."
    }
  ]
}
```

The first application does what an ordinary Ethernet switch does by itself, learning which MAC
address is behind which port, but in the controller, and by writing flows:

```schooling-example
{
  "language": "python",
  "file": "learning.py",
  "parts": [
    {
      "code": "from os_ken.base import app_manager\nfrom os_ken.controller import ofp_event\nfrom os_ken.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER, set_ev_cls\nfrom os_ken.lib.packet import ethernet, packet\nfrom os_ken.ofproto import ofproto_v1_3\n\n\nclass Learning(app_manager.OSKenApp):\n    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]\n\n    def __init__(self, *args, **kwargs):\n        super().__init__(*args, **kwargs)\n        self.where = {}  # MAC address -> switch port, learnt from traffic\n"
    },
    {
      "code": "    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)\n    def connected(self, ev):\n        dp = ev.msg.datapath\n        parser, ofp = dp.ofproto_parser, dp.ofproto\n        self.flow(dp, 0, parser.OFPMatch(), [parser.OFPActionOutput(ofp.OFPP_CONTROLLER, ofp.OFPCML_NO_BUFFER)])\n        self.logger.info(\"switch %016x connected\", dp.id)\n\n    def flow(self, dp, priority, match, actions, idle=0):\n        parser, ofp = dp.ofproto_parser, dp.ofproto\n        inst = [parser.OFPInstructionActions(ofp.OFPIT_APPLY_ACTIONS, actions)]\n        dp.send_msg(parser.OFPFlowMod(datapath=dp, priority=priority, match=match, instructions=inst,\n                                      idle_timeout=idle))\n",
      "note": "**When a switch connects, it gets one rule**: anything that matches nothing else goes to the controller. Priority 0 is the lowest, so every flow added later wins over it."
    },
    {
      "code": "    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)\n    def packet_in(self, ev):\n        msg = ev.msg\n        dp, parser, ofp = msg.datapath, msg.datapath.ofproto_parser, msg.datapath.ofproto\n        port = msg.match[\"in_port\"]\n        eth = packet.Packet(msg.data).get_protocol(ethernet.ethernet)\n        self.where[eth.src] = port\n        out = self.where.get(eth.dst, ofp.OFPP_FLOOD)\n        actions = [parser.OFPActionOutput(out)]\n        if out != ofp.OFPP_FLOOD:",
      "note": "**A packet the switch could not place.** The controller learns which port the sender is on, and if it already knows where the destination is, installs a flow so the switch forwards the next packets itself."
    },
    {
      "code": "            self.flow(dp, 10, parser.OFPMatch(in_port=port, eth_dst=eth.dst), actions, idle=30)\n            self.logger.info(\"flow: in_port %d to %s -> port %d\", port, eth.dst, out)\n        dp.send_msg(parser.OFPPacketOut(datapath=dp, buffer_id=ofp.OFP_NO_BUFFER, in_port=port,\n                                        actions=actions, data=msg.data))",
      "note": "**A learnt flow lasts while it is used.** Thirty seconds with no packet and the switch removes it, so a host that moves or leaves is forgotten."
    }
  ]
}
```

With the controller running in a terminal of its own on `ctl`, the switch is pointed at it:

```
ana@sw1:~$ ovs-vsctl set-controller br0 tcp:192.0.2.10:6653
ana@sw1:~$ ovs-vsctl list controller | grep -E "^(target|is_connected)"
is_connected        : true
target              : "tcp:192.0.2.10:6653"
```

```
ana@h1:~$ ping -c 3 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.
64 bytes from 203.0.113.130: icmp_seq=1 ttl=64 time=1.36 ms
64 bytes from 203.0.113.130: icmp_seq=2 ttl=64 time=0.317 ms
64 bytes from 203.0.113.130: icmp_seq=3 ttl=64 time=0.135 ms

--- 203.0.113.130 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2008ms
rtt min/avg/max/mdev = 0.135/0.603/1.358/0.538 ms
ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0
OFPST_FLOW reply (OF1.3) (xid=0x2):
 cookie=0x0, duration=5.041s, table=0, n_packets=2, n_bytes=196, idle_timeout=30, priority=10,in_port=1,dl_dst=52:54:00:00:71:82 actions=output:2
 cookie=0x0, duration=2.033s, table=0, n_packets=1, n_bytes=98, idle_timeout=30, priority=10,in_port=2,dl_dst=52:54:00:00:71:81 actions=output:1
 cookie=0x0, duration=5.078s, table=0, n_packets=3, n_bytes=182, priority=0 actions=CONTROLLER:65535
```

**The flows were written by the program**: a table-miss at priority 0 that sends unknown traffic to
the controller, and one flow for each direction it learnt, each with the thirty-second idle timeout.
The controller's terminal, stopped afterwards from another terminal on `ctl` with
`pkill -TERM -f "^python controller.py learning$"`, which is what printed `Terminated`:

```
ana@ctl:~$ cd sdn && python controller.py learning
19:58:08 loading app learning
19:58:08 loading app os_ken.controller.ofp_handler
19:58:08 instantiating app learning of Learning
19:58:08 instantiating app os_ken.controller.ofp_handler of OFPHandler
19:58:11 switch 0000000000000001 connected
19:58:11 flow: in_port 1 to 52:54:00:00:71:82 -> port 2
19:58:14 flow: in_port 2 to 52:54:00:00:71:81 -> port 1
Terminated
```

Two packet-ins became two flows, and from then on the switch forwarded h1 and h2's traffic without
asking. **That is the division of labour**: the controller sees the first packet of a conversation,
the switch forwards all the rest at its own speed. The `Terminated` at the end is the controller
being stopped.
