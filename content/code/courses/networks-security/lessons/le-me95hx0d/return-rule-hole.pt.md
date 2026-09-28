---
title: O que uma regra de retorno deixa entrar
version: 1
---

A regra de retorno diz: do segmento de servidores para a LAN, **qualquer pacote TCP cuja porta de
origem seja 8080** pode passar. Ela foi escrita para deixar as respostas passarem. Não tem como
distinguir uma resposta de qualquer outra coisa que carregue esse número.

A porta de origem é escolhida por quem envia. O servidor web em `app` usa 8080 porque escuta ali, e
qualquer programa em qualquer servidor pode escolher 8080 também. O `laptop` por acaso roda um
serviço na porta 9999, e as regras nunca tiveram a intenção de deixar um servidor alcançá-lo. A
partir de `db`, primeiro com uma porta escolhida pelo sistema e depois com 8080:

```
ana@db:~$ nc -w2 192.168.10.20 9999 </dev/null; echo "exit $?"
exit 1
ana@db:~$ nc -w2 -p 8080 192.168.10.20 9999 </dev/null; echo "exit $?"
laptop answered
exit 0
```

**A primeira tentativa foi descartada, e a segunda foi atendida.** O `nc -p 8080` só pede ao
sistema que use 8080 como porta de origem. Nada foi contornado e nenhuma regra foi quebrada. O
conjunto de regras disse o que diz.

Isto não é uma fraqueza exótica. O mesmo formato já mordeu redes reais em duas formas conhecidas:

| regra de retorno | o que ela também deixa entrar |
|---|---|
| `tcp sport 80 accept` | qualquer conexão *a partir* da porta 80, para qualquer porta de dentro |
| `udp sport 53 accept` | qualquer datagrama que alegue vir da porta de um servidor DNS |

Um filtro sem estado pode estreitar isso exigindo também as flags TCP que uma resposta carrega, que
é a palavra `established` de uma ACL da Cisco (aula 17). Ainda assim ele confere só as flags do
pacote que tem na frente. **O que um firewall precisa saber é se este pacote pertence a uma conversa
que ele já permitiu**, e isso significa lembrar das conversas.
