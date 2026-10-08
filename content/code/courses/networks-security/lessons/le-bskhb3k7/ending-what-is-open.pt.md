---
title: Encerrar o que já está aberto
version: 1
---

Retirar um acesso tem duas metades: impedir novas conexões e **encerrar as que já estão abertas**. A
primeira é a regra; a segunda, no Linux, é remover as entradas do conntrack, depois do que o próximo
pacote da sessão não casa com nada e cai na política.

A sessão é aberta de novo, depois que a regra do banco de dados volta ao `db` com
`nft -f /dev/stdin <<<"$(sed "s/# app withdrawn from the database, ticket 6203/ip saddr { 192.168.20.10 } tcp dport 5432 accept/" /root/segment.nft)"`
e o cliente no `app` sobe como antes. Desta vez a retirada faz as duas coisas, carregando as regras e
apagando as entradas da aplicação para a porta 5432:

```
root@db:~# nft -f segment.nft && conntrack -D -p tcp --dport 5432 -s 192.168.20.10 -u ASSURED 2>&1 >/dev/null
conntrack v1.4.8 (conntrack-tools): 2 flow entries have been deleted.
```

Duas entradas apagadas: a sessão nova e a anterior, fechada e ainda cumprindo o seu `TIME_WAIT`. O que
o cliente recebeu desta vez:

```
root@app:~# cat client.out
first
```

**Só a primeira linha.** A segunda foi enviada para uma sessão que o banco de dados já não reconhecia,
e nunca chegou. A tabela confirma que não sobrou nada:

```
root@db:~# conntrack -L -p tcp --dport 5432 2>/dev/null | grep ESTABLISHED | sed "s/ src=192.168.20.30.*//"
```

Todo sistema de controle de acesso capaz de revogar precisa responder a essa pergunta em algum lugar, e
as respostas se parecem:

| camada | como uma sessão ativa é encerrada |
|---|---|
| um firewall de host Linux | apagar as entradas do conntrack, como aqui |
| um firewall de rede | limpar a sua tabela de sessões para o endereço |
| TLS com certificados de cliente | fechar as conexões; o próximo handshake verifica o certificado de novo (aula 20) |
| uma aplicação | invalidar a sessão do lado do servidor, como a aula 7 pediu para os cookies |
| login único (single sign-on) | revogar os tokens, e manter a validade deles curta para que o resto expire logo |

**Uma revogação que deixa sessões abertas funcionando é só um agendamento.** A última linha traz a
resposta geral: manter toda concessão curta, para que a nova verificação aconteça sozinha, com
frequência, e uma retirada tenha efeito dentro de uma validade mesmo onde nada corta a sessão
ativamente.
