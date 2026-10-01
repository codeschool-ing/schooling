---
title: Nomes que a empresa se recusa a resolver
version: 1
---

Quase toda etapa do padrão começa com um nome. A página de phishing está num endereço que alguém
precisa consultar, e o servidor para o qual o software liga de volta também. **Um resolvedor que se
recusa a responder por nomes sabidamente maliciosos corta a cadeia no ponto mais barato**, e um
resolvedor que registra quem os pediu diz ao defensor quem clicou.

Isso é **DNS protetivo** (*protective DNS*). O servidor de nomes da empresa recebe uma lista de nomes
que não vai resolver: aqui, dois imitadores do próprio domínio da empresa que foram denunciados em
mensagens de phishing. Nomes sob `.test` são reservados e nunca podem pertencer a ninguém real:

```
root@dns:~# grep -A3 "^# names the company" /etc/dnsmasq.d/lab.conf
# names the company refuses to resolve for its staff: reported phishing and
# lookalikes of its own domain
address=/example-support.test/
address=/example.com.login-verify.test/
```

Então duas máquinas da equipe perguntam: `laptop` pela loja e por um imitador, `desk` pelo outro:

```
ana@laptop:~$ dig +short www.example.com; dig www.example-support.test | grep status
192.0.2.80
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 41812
ana@desk:~$ dig example.com.login-verify.test | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 56159
```

A loja resolve; os imitadores voltam como **`NXDOMAIN`**, *esse nome não existe*, e o navegador não
tem para onde ir. O log de consultas do servidor de nomes diz quem perguntou:

```
root@dns:~# grep -E "example-support|login-verify" /var/log/lab/dnsmasq.log | cut -d" " -f5-
using only locally-known addresses for example.com.login-verify.test
using only locally-known addresses for example-support.test
query[A] www.example-support.test from 192.168.10.20
config www.example-support.test is NXDOMAIN
query[A] example.com.login-verify.test from 192.168.10.21
config example.com.login-verify.test is NXDOMAIN
```

`192.168.10.20` pediu `www.example-support.test` e `192.168.10.21`, o outro. **Esse log é a primeira
lista de pessoas com quem conversar**: elas receberam a mensagem e clicaram, e uma delas pode ter
digitado uma senha na página antes de o nome ser bloqueado.

Dois limites, ditos com clareza. Uma lista de bloqueio só conhece os nomes que alguém já denunciou, e
imitadores são baratos de registrar, então ela pega a campanha conhecida e deixa passar a nova. Feeds
comerciais de nomes recém-registrados e denunciados fecham parte dessa lacuna, e o mesmo fazem os
filtros por categoria dos NGFW (aula 2), que bloqueiam classes inteiras de sites. E uma máquina que
usa outro resolvedor ignora a política por completo, e é por isso que a matriz da aula 4 só deixa a
equipe alcançar o DNS no servidor da própria empresa.
