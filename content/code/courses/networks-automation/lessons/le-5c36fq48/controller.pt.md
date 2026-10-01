---
title: Um controlador que aprende
version: 1
---

Um controlador é um servidor ao qual os switches se conectam. O OS-Ken escuta no endereço de
gerência do `ctl` e roda as aplicações que recebe:

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
      "note": "**O controlador é um programa com um endereço.** Ele escuta switches no endereço de gerência do ctl, na 6653, a porta que a IANA reservou para o OpenFlow, e roda as aplicações que recebe."
    }
  ]
}
```

A primeira aplicação faz o que um switch Ethernet comum faz sozinho, aprender qual endereço MAC
está atrás de qual porta, só que no controlador, e escrevendo flows:

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
      "note": "**Quando um switch conecta, ele recebe uma regra**: o que não casa com mais nada vai para o controlador. A prioridade 0 é a mais baixa, então todo fluxo acrescentado depois ganha dela."
    },
    {
      "code": "    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)\n    def packet_in(self, ev):\n        msg = ev.msg\n        dp, parser, ofp = msg.datapath, msg.datapath.ofproto_parser, msg.datapath.ofproto\n        port = msg.match[\"in_port\"]\n        eth = packet.Packet(msg.data).get_protocol(ethernet.ethernet)\n        self.where[eth.src] = port\n        out = self.where.get(eth.dst, ofp.OFPP_FLOOD)\n        actions = [parser.OFPActionOutput(out)]\n        if out != ofp.OFPP_FLOOD:",
      "note": "**Um pacote que o switch não soube onde pôr.** O controlador aprende em que porta está quem enviou e, se já sabe onde está o destino, instala um fluxo para o switch encaminhar os próximos pacotes sozinho."
    },
    {
      "code": "            self.flow(dp, 10, parser.OFPMatch(in_port=port, eth_dst=eth.dst), actions, idle=30)\n            self.logger.info(\"flow: in_port %d to %s -> port %d\", port, eth.dst, out)\n        dp.send_msg(parser.OFPPacketOut(datapath=dp, buffer_id=ofp.OFP_NO_BUFFER, in_port=port,\n                                        actions=actions, data=msg.data))",
      "note": "**Um fluxo aprendido dura enquanto é usado.** Trinta segundos sem pacote e o switch o remove, então um host que muda de lugar ou sai é esquecido."
    }
  ]
}
```

Com o controlador rodando num terminal próprio no `ctl`, o switch é apontado para ele:

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

**Os flows foram escritos pelo programa**: um table-miss com prioridade 0 que manda o tráfego
desconhecido para o controlador, e um flow para cada direção que ele aprendeu, cada um com o idle
timeout de trinta segundos. O terminal do controlador, parado depois:

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

Dois packet-ins viraram dois flows, e dali em diante o switch encaminhou o tráfego de h1 e h2 sem
perguntar. **Essa é a divisão do trabalho**: o controlador vê o primeiro pacote de uma conversa, e
o switch encaminha todo o resto na sua própria velocidade. O `Terminated` no fim é o controlador
sendo parado.
