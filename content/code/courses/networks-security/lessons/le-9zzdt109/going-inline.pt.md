---
title: Entrar em linha, e bloquear
version: 1
---

O `lab.sh inline` desliga o cabo da DMZ do `fw` do switch da DMZ, liga-o no `ips` e conecta a outra
interface do `ips` ao switch. O `ips` tem duas interfaces e nenhum endereço, como um pedaço de cabo
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

`blocked`. A mesma regra, o mesmo tráfego, e desta vez o pedido nunca chegou ao `www`. Essa é toda a
diferença entre os dois sistemas, e ela é decidida por uma palavra na regra e um cabo na ligação.
