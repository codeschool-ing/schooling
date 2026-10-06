---
title: Os mesmos pedidos, duas políticas
version: 1
---

O portal do laboratório pode servir o manual da equipe sob uma de duas políticas, escolhida por um
arquivo no servidor. Esta seção roda os mesmos pedidos sob as duas. Todo o resto fica igual, inclusive
o firewall, que fica aberto para que a única coisa comparada seja a política do próprio portal.

### Confiança pela localização

A primeira política é aquela sobre a qual a aula 5 avisou: qualquer pedido da rede do escritório
recebe o manual, e nenhum outro recebe.

```
root@www:~# cat /srv/portal/mode
perimeter
ana@laptop:~$ curl -s http://www.example.com/handbook
staff handbook: page 1 of 40
ana@outside:~$ curl -s http://www.example.com/handbook
only from the office network
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/handbook
only from the office network
```

O notebook no escritório recebe o manual sem que lhe perguntem nada. A máquina na internet é recusada,
o que parece certo, até a última linha: **a ana, com a senha correta, também é recusada.** O portal nem
olhou a senha, porque a política não pergunta quem você é. Pergunta onde você está.

Leia os dois resultados juntos e o problema fica claro. Qualquer coisa na rede do escritório, o
celular de um visitante, um notebook infectado, uma impressora comprometida, recebe o que a ana recebe.
A ana em casa não recebe nada.

### Todo pedido prova quem é

Agora o administrador troca a política:

```
root@www:~# echo zerotrust > /srv/portal/mode
```

e os mesmos pedidos rodam de novo:

```
ana@laptop:~$ curl -s http://www.example.com/handbook
sign in first
ana@laptop:~$ curl -s -u ana:lab-ana-pass http://www.example.com/handbook
staff handbook: page 1 of 40
ana@outside:~$ curl -s -u ana:lab-ana-pass http://www.example.com/handbook
staff handbook: page 1 of 40
```

O notebook no escritório, pedindo sem nada, ouve que precisa fazer login, exatamente como um estranho
ouviria. Com a senha da ana, recebe o manual. Da internet, com a mesma senha, recebe o mesmo manual.
**A resposta agora depende de quem pede, e não de onde.**

O log do portal mostra a mudança do lado do defensor:

```
root@www:~# cat /var/log/lab/portal.log
192.168.10.20 - "GET /handbook HTTP/1.1" 200 -
203.0.113.50 - "GET /handbook HTTP/1.1" 403 -
203.0.113.50 - "GET /handbook HTTP/1.1" 403 -
192.168.10.20 - "GET /handbook HTTP/1.1" 401 -
192.168.10.20 ana "GET /handbook HTTP/1.1" 200 -
203.0.113.50 ana "GET /handbook HTTP/1.1" 200 -
```

Nas três primeiras linhas, o segundo campo é `-`: o portal serviu ou recusou o manual sem nunca saber
quem pediu. Nas duas últimas, todo pedido bem-sucedido traz um nome. Quando algo dá errado, o segundo
log diz de quem era a conta; o primeiro só consegue dizer qual era a rede.

### O que este laboratório não mostra

Isto é uma peça do Zero Trust, e não ele inteiro. O portal confere a identidade com uma senha e nada
mais: não confere o aparelho, não pede segundo fator e não pesa o contexto. Um projeto de verdade
recusaria a senha da ana vinda de um aparelho não gerenciado, pediria o segundo fator da aula 9 e
perceberia que a mesma conta foi usada de dois lugares ao mesmo tempo. A tabela da seção anterior
lista os sinais; o laboratório usa o primeiro.
