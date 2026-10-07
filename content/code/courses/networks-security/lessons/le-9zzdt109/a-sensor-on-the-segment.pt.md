---
title: Um sensor que vê e não toca
version: 1
---

A empresa não quer que as páginas de administração da loja sejam pedidas a partir da internet. A aula 3
mostrou como recusar isso no proxy; esta aula faz outra pergunta: **alguém perceberia a tentativa?**
No seu laboratório esta aula começa com `sudo bash nslab.sh reset`, com a política da empresa
carregada no `fw` por `nft -f baseline.nft`. Uma regra no `sensor`, escrita no seu arquivo de regras
vazio:

```
root@sensor:~# cat /etc/suricata/rules/local.rules
alert http $EXTERNAL_NET any -> $HOME_NET any (msg:"admin path requested from outside"; flow:to_server,established; http.uri; content:"/admin"; startswith; classtype:policy-violation; sid:1000101; rev:1;)
```

Ela se lê como as regras da aula 2: `alert` em HTTP vindo de fora para as redes da empresa, do lado do
cliente de uma conexão estabelecida, quando o caminho pedido **começa com** `/admin`. O `classtype`
a arquiva numa categoria, e é isso que decide a prioridade do alerta. O Suricata começa a escutar na
DMZ:

```
root@sensor:~# suricata -c /etc/suricata/suricata.yaml --af-packet=eth0 -D --pidfile /var/log/suricata/suricata.pid
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

Depois, um pedido vindo da internet:

```
ana@remote:~$ curl -s http://www.example.com/admin/
admin console
```

**O pedido deu certo.** O console de administração respondeu a `remote`, porque um IDS não fica no
caminho de nada; o proxy deste laboratório ficou sem as restrições da aula 3. O que o IDS fez foi
anotar:

```
root@sensor:~# cat /var/log/suricata/fast.log
09/28/2026-17:59:18.623794  [**] [1:1000101:1] admin path requested from outside [**] [Classification: Potential Corporate Privacy Violation] [Priority: 1] {TCP} 203.0.113.50:39498 -> 192.0.2.80:80
```

Uma linha por alerta no `fast.log`: quando, qual regra e revisão (`1:1000101:1`), a mensagem, a
classificação e a prioridade, e a conexão que ele viu. É isso que vê quem acompanha um console. A
próxima seção lê o registro completo por trás dessa linha.
