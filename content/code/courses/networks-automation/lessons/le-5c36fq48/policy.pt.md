---
title: Uma regra para a rede inteira, num lugar só
version: 2
---

Uma segunda aplicação roda ao lado da primeira. Ela não sabe nada de aprendizado; guarda uma única
política, a de que o h3 não pode alcançar o h1:

```schooling-example
{
  "language": "python",
  "file": "policy.py",
  "parts": [
    {
      "code": "from os_ken.base import app_manager\nfrom os_ken.controller import ofp_event\nfrom os_ken.controller.handler import CONFIG_DISPATCHER, set_ev_cls\nfrom os_ken.ofproto import ofproto_v1_3\n"
    },
    {
      "code": "BLOCKED = [(\"203.0.113.131\", \"203.0.113.129\")]  # h3 may not reach h1\n\n\nclass Policy(app_manager.OSKenApp):\n    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]\n",
      "note": "**A política é dado num programa**: que origem não pode alcançar que destino, escrita uma vez para todo switch que conecta."
    },
    {
      "code": "    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)\n    def connected(self, ev):\n        dp = ev.msg.datapath\n        parser = dp.ofproto_parser\n        for src, dst in BLOCKED:\n            match = parser.OFPMatch(eth_type=0x0800, ipv4_src=src, ipv4_dst=dst)\n            dp.send_msg(parser.OFPFlowMod(datapath=dp, priority=100, match=match, instructions=[]))\n            self.logger.info(\"policy: drop %s -> %s\", src, dst)",
      "note": "**Um descarte é um fluxo sem ações**, na prioridade 100, acima de tudo que a aplicação de aprendizado instala. Ele casa só IPv4, então o ARP continua funcionando e o bloqueio é sobre tráfego, não sobre saber que o h1 existe."
    }
  ]
}
```

O controlador é iniciado de novo com as duas aplicações, e o switch se reconecta a ele sozinho:

```
ana@h3:~$ ping -c 2 -W 1 203.0.113.129
PING 203.0.113.129 (203.0.113.129) 56(84) bytes of data.

--- 203.0.113.129 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1012ms

ana@h3:~$ ping -c 2 203.0.113.130
PING 203.0.113.130 (203.0.113.130) 56(84) bytes of data.
64 bytes from 203.0.113.130: icmp_seq=1 ttl=64 time=5.87 ms
64 bytes from 203.0.113.130: icmp_seq=2 ttl=64 time=0.383 ms

--- 203.0.113.130 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.383/3.127/5.871/2.744 ms
```

**O h3 não alcança o h1 e alcança o h2.** O flow de descarte fica acima de todo o resto, e o seu
contador mostra os dois echo requests que ele descartou:

```
ana@sw1:~$ ovs-ofctl -O OpenFlow13 dump-flows br0 | grep -E "priority=(100|0)"
 cookie=0x0, duration=13.604s, table=0, n_packets=2, n_bytes=196, priority=100,ip,nw_src=203.0.113.131,nw_dst=203.0.113.129 actions=drop
 cookie=0x0, duration=13.604s, table=0, n_packets=8, n_bytes=448, priority=0 actions=CONTROLLER:65535
```

O terminal do controlador, parado com
`pkill -TERM -f "^python controller.py learning policy$"` depois de os flows serem lidos:

```
ana@ctl:~$ cd sdn && python controller.py learning policy
19:58:16 loading app learning
19:58:16 loading app policy
19:58:16 loading app os_ken.controller.ofp_handler
19:58:16 instantiating app learning of Learning
19:58:16 instantiating app policy of Policy
19:58:16 instantiating app os_ken.controller.ofp_handler of OFPHandler
19:58:18 switch 0000000000000001 connected
19:58:18 policy: drop 203.0.113.131 -> 203.0.113.129
19:58:28 flow: in_port 1 to 52:54:00:00:71:83 -> port 3
19:58:30 flow: in_port 2 to 52:54:00:00:71:83 -> port 3
19:58:30 flow: in_port 3 to 52:54:00:00:71:82 -> port 2
Terminated
```

Com um switch, isto é uma regra de firewall. Com cem, é o sentido do projeto: a regra é escrita
uma vez, no controlador, e todo switch que se conecta a recebe, inclusive os novos. **Mudá-la é
mudar um programa**, revisado e testado como os playbooks e templates das aulas anteriores, em vez
de mudar cem configurações.
