---
title: Uma resposta adulterada, recusada
version: 1
---

Para ver a validação funcionar, a resposta precisa estar errada. No `dns`, a zona assinada é editada à
mão: o endereço da loja passa a ser `203.0.113.66`, **sem assinar de novo**. É assim que uma resposta
forjada aparece para o resolvedor: o nome certo, um endereço errado e uma assinatura que foi feita para
outra coisa.

```
root@dns:~# sed -i "s/^\(www\.example\.com\.[[:space:]]*300[[:space:]]*IN A[[:space:]]*\)192.0.2.80/\1203.0.113.66/" /etc/bind/db.example.com.signed; grep -n "IN A" /etc/bind/db.example.com.signed
47:dns.example.com.	300	IN A	192.0.2.53
59:www.example.com.	300	IN A	203.0.113.66
```

O servidor é reiniciado para servir o arquivo editado, a resposta que o resolvedor guardou em cache
para o nome é descartada, e o `laptop` pergunta de novo:

```
root@laptop:~# unbound-control flush www.example.com
ok
ana@laptop:~$ dig @127.0.0.1 www.example.com | grep -E "status|^www"
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 8727
root@laptop:~# grep "validation failure" /var/lib/unbound/unbound.log | cut -d" " -f3-
info: validation failure <www.example.com. A IN>: signature crypto failed from 192.0.2.53
```

**`SERVFAIL`, e endereço nenhum.** O resolvedor buscou a resposta, conferiu a assinatura, viu que ela
não batia e se recusou a entregar qualquer coisa ao cliente. O log dele diz exatamente por quê:
`signature crypto failed`. Um cliente deste resolvedor não pode ser mandado para `203.0.113.66`,
porque nunca fica sabendo do endereço.

A flag `+cd`, *checking disabled*, pede ao resolvedor que pule a validação, o que mostra o que teria
acontecido sem ela:

```
ana@laptop:~$ dig +cd +short @127.0.0.1 www.example.com
203.0.113.66
```

O endereço forjado, entregue como se fosse verdadeiro.

## Onde o DNSSEC ajuda, e onde ele para

| DNSSEC | faz | não faz |
|---|---|---|
| na resposta | prova que ela veio do dono da zona, sem alteração | esconder a pergunta ou a resposta de quem estiver no caminho |
| na zona | protege todo nome nela, depois de assinada | proteger uma zona cujo dono nunca a assinou |
| no cliente | dá um veredito em que ele pode confiar, se o resolvedor valida | ajudar um cliente cujo resolvedor não valida |

**`SERVFAIL` também é a cara de um erro.** Uma assinatura vencida ou uma chave trocada sem cuidado
tira uma zona assinada da internet para todo resolvedor que valida, com o mesmo erro. Assinar uma zona
é um compromisso de reassiná-la no prazo, e as assinaturas do laboratório trazem a própria data de
validade, 31 de dezembro de 2026, exatamente por isso.
