---
title: Regras por conta
version: 1
---

**No Linux, uma regra pode casar a conta dona do socket de onde um pacote sai.** Esse é o jeito mais
simples de escrever uma regra por aplicação, porque num servidor bem administrado cada serviço roda
com uma conta própria: o portal como `portal`, os workers do nginx como `www-data`. Uma regra sobre
a conta é uma regra sobre o programa.

O trabalho do portal nunca precisa de uma conexão para fora da máquina. Ele responde ao nginx pela
interface de loopback, e só. Então a regra é: **a conta do portal pode falar pelo loopback e
responder a conversas de que fez parte, e nada mais.** Salve isto no `web` como `portal-out.nft`:

```schooling-example
{"language": "conf", "file": "portal-out.nft", "parts": [{"code": "table inet portal_out {\n\tchain output {\n\t\ttype filter hook output priority filter; policy accept;\n\t\tmeta skuid \"portal\" oif \"lo\" accept\n\t\tmeta skuid \"portal\" ct state established,related accept\n\t\tmeta skuid \"portal\" counter reject comment \"the portal starts no connection off the machine\"\n\t}\n}", "note": "`meta skuid` casa a conta dona do socket de onde um pacote sai, então esta tabela só julga o que a conta do portal envia. Conversar com o nginx pelo loopback é o trabalho do portal, e responder a uma conexão que outro começou também. Qualquer outra coisa que ele tente abrir é recusada e contada. A política continua `accept`: nenhuma outra conta do `web` é tocada por esta tabela."}]}
```

Carregue e tente a mesma conexão como o portal e como você:

```
ana@web:~$ sudo nft -f portal-out.nft
ana@web:~$ sudo -u portal nc -zv -w2 desk 22 2>&1; echo "exit $?"
nc: connect to desk (192.168.60.20) port 22 (tcp) failed: Connection refused
exit 1
ana@web:~$ nc -zv -w2 desk 22 2>&1
Connection to desk (192.168.60.20) 22 port [tcp/ssh] succeeded!
ana@desk:~$ curl -s http://web/
Jatobá Contabilidade: client portal
ana@web:~$ sudo nft list chain inet portal_out output | grep counter
		meta skuid 999 counter packets 1 bytes 60 reject comment "the portal starts no connection off the machine"
```

A conta do portal foi recusada na hora, `Connection refused`, porque `reject` responde em vez de
ficar calado; na própria máquina não há de quem se esconder, e uma resposta imediata poupa o
programa de esperar um tempo esgotar. A sua conta continua alcançando o `desk`, porque nada na
tabela fala dela. O portal continua servindo a página ao `desk`, porque essa conversa é do nginx na
porta 80 e do portal pelo loopback. E o contador mostra o único pacote que a regra recusou.

## O que a conta não consegue dizer

A regra casa a conta, então ela é tão boa quanto a separação entre contas. **Dois serviços dividindo
uma conta dividem uma regra**, o que é mais um motivo para a aula 1 insistir numa conta por serviço.
E um programa que consiga virar outra conta, por `sudo` ou por uma falha, deixa a regra para trás
junto com a conta que abandonou. A próxima seção amarra uma regra ao próprio serviço, de que nenhuma
troca de conta escapa.
