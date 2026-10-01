---
title: Uma regra que nomeia a aplicação
version: 1
---

Com o protocolo conhecido, uma regra pode perguntar por ele. Duas regras na linguagem do Suricata,
uma por linha:

```
root@fw:~# cat /etc/suricata/rules/local.rules
alert ssh $HOME_NET any -> $EXTERNAL_NET any (msg:"SSH leaving the LAN"; flow:to_server,established; ssh.proto; content:"2.0"; sid:1000001; rev:1;)
alert tls $HOME_NET any -> any !443 (msg:"TLS on a port other than 443"; flow:to_server,established; tls.sni; content:"."; sid:1000002; rev:1;)
root@fw:~# suricata -T -c /etc/suricata/suricata.yaml 2>&1 | tail -1
i: suricata: Configuration provided was successfully loaded. Exiting.
```

Leia a primeira parte por parte:

| parte | diz |
|---|---|
| `alert` | o que fazer quando casar; a aula 14 transforma isso em `drop` |
| `ssh` | o protocolo de aplicação, como o Suricata o reconheceu, em qualquer porta |
| `$HOME_NET any -> $EXTERNAL_NET any` | das redes da empresa, para qualquer lugar lá fora |
| `flow:to_server,established` | do lado do cliente, numa conexão que completou o *handshake* |
| `ssh.proto; content:"2.0"` | a versão do protocolo que o cliente anunciou |
| `sid:1000001; rev:1` | o número da regra e a revisão; regras locais usam números de um milhão para cima |

A segunda regra procura TLS indo para qualquer porta **que não seja** a 443. O `suricata -T` confere
que as duas carregam antes de qualquer coisa rodar. Depois, a tentativa de SSH e uma busca normal de
página de novo:

```
ana@laptop:~$ ssh -p 443 -o BatchMode=yes 203.0.113.50 true; echo "exit $?"
ana@203.0.113.50: Permission denied (publickey).
exit 255
ana@laptop:~$ curl -s -o /dev/null https://www.example.com/; echo "exit $?"
exit 0
```

```
root@fw:~# jq -c "select(.event_type==\"alert\") | [.src_ip, .dest_ip, .dest_port, .alert.signature_id, .alert.signature]" /var/log/suricata/eve.json
["192.168.10.20","203.0.113.50",443,1000001,"SSH leaving the LAN"]
root@fw:~# cat /var/log/suricata/fast.log
09/28/2026-15:17:47.539067  [**] [1:1000001:1] SSH leaving the LAN [**] [Classification: (null)] [Priority: 3] {TCP} 192.168.10.20:37562 -> 203.0.113.50:443
```

**Um alerta, para a sessão SSH, e nenhum para a página web.** A segunda regra ficou calada porque o
único TLS desta captura foi para a 443, e é isso que ela deve fazer: na maior parte do tempo, uma boa
regra de política não diz nada.

## Como é uma política de aplicação num produto

NGFWs comerciais escrevem a mesma ideia numa tabela em vez de numa linguagem de regras. A linha que
substitui "liberar a 443" diz mais ou menos "da zona dos funcionários, para a internet, aplicação
web-browsing, permitir", seguida de "da zona dos funcionários, para a internet, aplicação SSH,
negar". O mecanismo por baixo é o que esta seção executou: identificar o protocolo pela carga útil e
depois casar a regra.

**Uma regra de aplicação não substitui a regra de porta; ela a estreita.** O firewall continua
decidindo quais portas podem sequer abrir, e o que falha ali nunca chega à inspeção, que é mais
lenta.
