---
title: Anomalias, que nenhuma regra nomeou
version: 1
---

Uma assinatura encontra o que alguém soube descrever. A **detecção de anomalias** (*anomaly detection*)
encontra o que se afasta do normal, o que pega coisas para as quais ninguém escreveu regra, ao preço de
mais alarmes falsos. O Suricata faz isso em dois níveis.

**Anomalias de protocolo.** O Suricata interpreta cada pedido HTTP, e um pedido que quebra as regras do
protocolo gera um evento. O `http-events.rules`, carregado antes, transforma esses eventos em alertas. Um
pedido de `remote` sem o cabeçalho `Host`, que todo pedido HTTP/1.1 precisa carregar:

```
ana@remote:~$ printf "GET / HTTP/1.1\r\n\r\n" | nc -w2 www.example.com 80 | head -1
HTTP/1.1 400 Bad Request
```

O proxy o recusou com `400`, e o sensor percebeu:

```
root@sensor:~# jq -c "select(.event_type==\"alert\" and .alert.signature_id!=1000201) | [.alert.signature_id, .alert.signature, .src_ip]" /var/log/suricata/eve.json
[2221014,"SURICATA HTTP missing Host header","203.0.113.50"]
```

Regra 2221014, *SURICATA HTTP missing Host header*. Ninguém escreveu uma regra sobre este pedido; o
interpretador do protocolo sabia como é um pedido válido. Tráfego malformado é um sinal útil porque
clientes comuns não o produzem: scanners, ferramentas feitas à mão e software quebrado, sim.

**Anomalias de comportamento** precisam de uma linha de base (*baseline*): o que cada máquina faz
normalmente, para que um desvio se destaque. A matéria-prima são os registros que o Suricata grava tendo
ou não havido casamento com alguma regra. Duas máquinas fazem perguntas ao servidor de nomes, uma delas
bastante:

```
ana@remote:~$ for n in www shop mail vpn ftp dev test admin intranet portal; do dig +short @192.0.2.53 $n.example.com >/dev/null; done
ana@laptop:~$ dig +short @192.0.2.53 www.example.com >/dev/null
```

Contando perguntas por origem, só a partir dos registros de DNS:

```
root@sensor:~# jq -r "select(.event_type==\"dns\" and .dns.type==\"query\") | .src_ip" /var/log/suricata/eve.json | sort | uniq -c | sort -rn
     10 203.0.113.50
      1 192.168.10.20
```

**Dez perguntas de `203.0.113.50`, uma de `laptop`.** E o que as dez pediram:

```
root@sensor:~# jq -r "select(.event_type==\"dns\" and .dns.type==\"query\" and .src_ip==\"203.0.113.50\") | .dns.rrname" /var/log/suricata/eve.json | tr "\n" " "; echo
www.example.com shop.example.com mail.example.com vpn.example.com ftp.example.com dev.example.com test.example.com admin.example.com intranet.example.com portal.example.com 
```

Uma lista de nomes de host prováveis, tentados um depois do outro, é alguém **mapeando os nomes da
empresa** para descobrir o que existe. Cada pergunta era inofensiva e legítima; nenhuma assinatura
dispararia com qualquer uma delas. O padrão só aparece quando os registros são contados, e uma linha de
base diz se dez é muito: para um resolvedor que atende um escritório, dez nomes de uma origem podem ser
uma terça-feira qualquer; para o servidor de nomes público, dez nomes de um desconhecido são um
levantamento. A aula 23 volta a guardar esses registros por tempo suficiente para construir uma linha de
base com eles.
