---
title: Verificar continuamente, não uma vez só
version: 1
---

A aula 20 fez toda **nova conexão** provar sua identidade. A **verificação contínua** (continuous
verification) faz a pergunta mais difícil: e uma conexão, ou uma sessão, que foi permitida há um minuto
e não deveria ser agora?

O acesso muda enquanto as sessões estão abertas. Um funcionário sai, um dispositivo reprova na
verificação de integridade, descobre-se que um servidor foi comprometido, um chamado é encerrado. Uma decisão
tomada no início de uma sessão e nunca revista continua concedendo um acesso que suas razões já não
sustentam.

O laboratório mostra a lacuna com precisão. O substituto do banco de dados em `db` agora mantém uma
sessão aberta, como um banco de dados real mantém a conexão de um cliente. O `app` abre uma, envia uma
linha e, seis segundos depois, outra. As duas metades sobem como root, o novo substituto no `db` e o
cliente no `app`:

```sh
# on db: the one-line stand-in replaced by one that repeats what it is sent
kill $(ss -Hltnp "sport = :5432" | grep -o "pid=[0-9]*" | cut -d= -f2); sleep 0.3; setsid socat TCP-LISTEN:5432,bind=192.168.20.30,fork,reuseaddr EXEC:cat </dev/null >/dev/null 2>&1 &
# on app: the client, in the background, writing what comes back to client.out
rm -f /root/client.out; setsid bash -c "(echo first; sleep 6; echo second; sleep 1) | nc -N -w8 192.168.20.30 5432 > /root/client.out" </dev/null >/dev/null 2>&1 &
```

Enquanto ele espera, a sessão está na tabela de conexões de `db`:

```
root@db:~# conntrack -L -p tcp --dport 5432 2>/dev/null | grep ESTABLISHED | sed "s/ src=192.168.20.30.*//"
tcp      6 431997 ESTABLISHED src=192.168.20.10 dst=192.168.20.30 sport=52666 dport=5432
```

Então a política muda: `app` perde o acesso ao banco de dados, e as regras de `db` são geradas de novo
sem a linha de aceite dele:

```
root@db:~# sed -i 's/ip saddr { 192.168.20.10 } tcp dport 5432 accept.*/# app withdrawn from the database, ticket 6203/' segment.nft && nft -f segment.nft && nft list chain inet host input | grep -c 5432
0
```

Nenhuma regra em `db` menciona mais a porta 5432. Seis segundos depois, o que o cliente recebeu:

```
root@app:~# cat client.out
first
second
```

**As duas linhas.** A segunda passou depois que a regra já tinha sumido. A primeira regra do firewall
do host, a da aula 1, aceita tráfego `established`, e a sessão foi estabelecida antes da mudança. A nova política só vale para conexões **novas**.

É a mesma propriedade que torna os firewalls com estado eficientes; aqui ela é a lacuna que a
verificação contínua precisa fechar. A próxima seção a fecha.
