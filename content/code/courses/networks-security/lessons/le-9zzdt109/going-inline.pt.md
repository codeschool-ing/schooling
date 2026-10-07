---
title: Entrar em linha, e bloquear
version: 1
---

Mais um script refaz os cabos do laboratório: tira do switch da DMZ o cabo da DMZ do `fw`, liga-o no
`ips` e conecta a outra interface do `ips` ao switch. Salve-o ao lado do `nslab.sh` e rode-o num
laboratório de pé, com `sudo bash inline.sh`. Antes, pare o Suricata do sensor, com
`kill -INT $(cat /var/log/suricata/suricata.pid)` no `sensor`; daqui em diante o motor roda no `ips`:

```schooling-example
{"language": "sh", "file": "inline.sh", "parts": [{"code": "#!/bin/bash\n# inline.sh: run after nslab.sh up, from the same directory.\n#   sudo bash inline.sh\nset -euo pipefail\nLAB=/lab\n[ -e /run/netns/wire ] || { echo \"the lab is not up: sudo bash nslab.sh up\" >&2; exit 1; }\n[ -e /run/netns/ips ] && { echo \"ips is already inline: sudo bash nslab.sh reset, then run this again\" >&2; exit 1; }\nfwport=$(ip -n wire -o link show master br-dmz | awk -F': ' '{print $2}' | grep -- '-fw@' | cut -d@ -f1)\nip netns add ips\nip -n ips link set lo up\nip -n wire link set \"$fwport\" nomaster\nip -n wire link set \"$fwport\" netns ips\nip -n ips link set \"$fwport\" name eth0\nip link add i-ips type veth peer name lab-ips\nip link set lab-ips netns ips\nip -n ips link set lab-ips name eth1\nip link set i-ips netns wire\nip -n wire link set i-ips master br-dmz\nip -n wire link set i-ips up", "note": "A prevenção de intrusão da aula 14: uma máquina chamada `ips` posta **em linha** no cabo entre o `fw` e a DMZ. O cabo da DMZ do `fw` sai do switch da DMZ e vai para a primeira placa do `ips`; a segunda placa vai para o switch. A partir daí, nada passa entre o `fw` e a DMZ sem atravessar o `ips`."}, {"code": "for i in eth0 eth1; do\n  ip -n ips link set \"$i\" up\n  ip netns exec ips ethtool -K \"$i\" gro off gso off tso off >/dev/null 2>&1 || true\ndone\nip netns exec fw ethtool -K eth1 tx off >/dev/null 2>&1 || true\nfor h in www dns; do ip netns exec \"$h\" ethtool -K eth0 tx off >/dev/null 2>&1 || true; done\nmkdir -p \"/etc/netns/ips\" \"$LAB/ips/root\" \"$LAB/ips/home\" \"$LAB/ips/var/log/suricata\" \"$LAB/ips/var/lib/suricata\"\nprintf 'ips\\n' > /etc/netns/ips/hostname\nmkdir -p \"$LAB/ips/etc\"\ncp -a \"$LAB/sensor/etc/suricata\" \"$LAB/ips/etc/\"", "note": "Cabos virtuais deixam o checksum de cada pacote TCP para o hardware de rede preencher, e não há hardware nenhum. Um pacote que o Suricata copia de uma placa para a outra sairia com o checksum incompleto e seria descartado, então as máquinas dos dois lados são instruídas a calcular o seu próprio."}, {"code": "cat > \"$LAB/ips/etc/suricata/inline.yaml\" <<'Y'\n%YAML 1.1\n---\naf-packet:\n  - interface: eth0\n    copy-mode: ips\n    copy-iface: eth1\n    cluster-id: 98\n    cluster-type: cluster_flow\n    defrag: no\n  - interface: eth1\n    copy-mode: ips\n    copy-iface: eth0\n    cluster-id: 97\n    cluster-type: cluster_flow\n    defrag: no\nlivedev:\n  use-for-tracking: false\nY", "note": "O `ips` recebe uma cópia da configuração do Suricata do sensor e o `inline.yaml`, que junta as suas duas placas: o que chega por uma sai pela outra, a menos que uma regra o descarte. Com `use-for-tracking` desligado, uma conexão é um fluxo só nas duas placas; ligado, o Suricata 7 mantém um fluxo por placa, vê toda resposta como uma estranha e a descarta."}]}
```

Agora o `ips` tem duas interfaces e nenhum endereço, como um pedaço de cabo
com um cérebro no meio:

```
root@ips:~# ip -br link
lo               UNKNOWN        00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP> 
eth0@if801       UP             5e:8c:67:f7:30:7f <BROADCAST,MULTICAST,UP,LOWER_UP> 
eth1@if830       UP             32:9b:ad:de:b6:95 <BROADCAST,MULTICAST,UP,LOWER_UP> 
```

**Sem nada rodando nele, nada passa**:

```
ana@remote:~$ curl -s -m3 http://www.example.com/; echo "exit $?"
exit 28
```

A loja fica inalcançável, porque um cabo que termina numa máquina que não encaminha nada é um cabo
cortado. O Suricata é o que une os dois lados: no modo IPS, ele lê cada pacote numa interface, decide
e o escreve na outra. A mesma regra do sensor, com uma palavra trocada e a revisão aumentada:

```
root@ips:~# cat /etc/suricata/rules/local.rules
drop http $EXTERNAL_NET any -> $HOME_NET any (msg:"admin path requested from outside"; flow:to_server,established; http.uri; content:"/admin"; startswith; classtype:policy-violation; sid:1000101; rev:2;)
root@ips:~# suricata -c /etc/suricata/suricata.yaml --include /etc/suricata/inline.yaml --af-packet -D --pidfile /var/log/suricata/suricata.pid
Info: conf-yaml-loader: Configuration node 'af-packet' redefined.
Info: conf-yaml-loader: Configuration node 'livedev' redefined.
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

`drop` no lugar de `alert`. O `inline.yaml` ao lado da configuração principal emparelha `eth0` com
`eth1` nos dois sentidos. Agora a loja, e depois o caminho de administração:

```
ana@remote:~$ curl -s -m3 http://www.example.com/; echo "exit $?"
orders service: ok
exit 0
ana@remote:~$ curl -s -m3 http://www.example.com/admin/; echo "exit $?"
exit 28
```

A loja responde; **o pedido de administração expira**. O Suricata viu o caminho no primeiro pacote do
pedido, descartou-o e descartou o resto daquela conexão. O log registra isso com outra palavra:

```
root@ips:~# jq -c "select(.event_type==\"alert\") | [.alert.action, .alert.signature_id, .src_ip, .http.url]" /var/log/suricata/eve.json
["blocked",1000101,"203.0.113.50","/admin/"]
```

`blocked`. A mesma regra, o mesmo tráfego, e desta vez o pedido nunca chegou ao `www`. Uma palavra na
regra e um cabo na ligação fazem toda a diferença entre os dois sistemas.
