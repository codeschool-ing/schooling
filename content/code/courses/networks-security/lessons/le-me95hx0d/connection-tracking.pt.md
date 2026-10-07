---
title: Rastreamento de conexões, a memória de um firewall com estado
version: 1
---

**Um firewall com estado guarda uma tabela das conversas que já viu**, e julga um pacote pelo lugar
que ele ocupa em uma delas. O Linux chama isso de rastreamento de conexões, `conntrack`. Todo pacote
é primeiro comparado com a tabela, e uma regra pode então perguntar pelo seu **estado**:

| estado | o pacote é |
|---|---|
| `new` | o primeiro de uma conversa que a tabela ainda não conhece |
| `established` | parte de uma conversa que já está na tabela, em qualquer sentido |
| `related` | um novo fluxo que pertence a um conhecido, como um erro ICMP sobre ele |
| `invalid` | nenhum desses: uma resposta a nada, flags sem sentido |

A mesma política de antes, escrita com estado:

```
root@fw:~# cat stateful.nft
flush ruleset
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept
  }
}
```

**A primeira regra faz o trabalho de todas as regras de retorno de uma vez.** Tudo o que pertence a
uma conversa já permitida passa, nos dois sentidos. A terceira regra decide quais conversas podem
começar: da LAN, para `app`, na 8080. Nada mais consegue iniciar uma.

```
root@fw:~# nft -f stateful.nft
ana@laptop:~$ curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"
status: ok
exit 0
ana@db:~$ nc -w2 -p 8080 192.168.10.20 9999 </dev/null; echo "exit $?"
exit 1
```

A aplicação responde ao `laptop`, e o truque de `db` com porta de origem 8080 agora falha. O
primeiro pacote dele é `new`, veio do segmento de servidores, e nenhuma regra deixa uma conversa
começar ali.

## A tabela em si

O `conntrack -L` imprime o que o `fw` lembra. O `laptop` manteve uma conexão aberta com `app` por
três segundos, com `setsid bash -c "exec 3<>/dev/tcp/192.168.20.10/8080; sleep 3" </dev/null >/dev/null 2>&1 &`,
e tinha acabado de fechar outra, o `curl` acima:

```
root@fw:~# conntrack -L 2>/dev/null
tcp      6 431999 ESTABLISHED src=192.168.10.20 dst=192.168.20.10 sport=46140 dport=8080 src=192.168.20.10 dst=192.168.10.20 sport=8080 dport=46140 [ASSURED] mark=0 use=1
tcp      6 117 TIME_WAIT src=192.168.10.20 dst=192.168.20.10 sport=49590 dport=8080 src=192.168.20.10 dst=192.168.10.20 sport=8080 dport=49590 [ASSURED] mark=0 use=1
```

Cada entrada carrega **os dois sentidos da conversa**. O primeiro `src=… dst=…` é o pacote como foi
visto pela primeira vez; o segundo é como uma resposta tem de ser. `ESTABLISHED` e `TIME_WAIT` são
estados do próprio TCP, e o número antes deles é quantos segundos restam à entrada: 431.999 para a
conexão aberta, menos de dois minutos para a fechada. `[ASSURED]` quer dizer que houve tráfego nos
dois sentidos, o que protege a entrada quando a tabela enche.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma entrada do conntrack desenhada como duas linhas. A direção original: de laptop, 192.168.10.20, porta P, para app, 192.168.20.10, porta 8080. A direção da resposta: de app porta 8080 de volta para laptop porta P. Um pacote que casa com qualquer das linhas pertence à conversa e é established; um pacote que não casa com nenhuma é new ou invalid.\"><defs></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp  6  431999  ESTABLISHED   [ASSURED]</text><text x=\"36\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">original</text><text x=\"130\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src=192.168.10.20  sport=P      dst=192.168.20.10  dport=8080</text><text x=\"36\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">resposta</text><text x=\"130\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">src=192.168.20.10  sport=8080   dst=192.168.10.20  dport=P</text><text x=\"36\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundos restantes, estado TCP, visto nos dois sentidos</text><text x=\"360\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Um pacote que casa com uma das linhas é established. Um que não casa com nenhuma é new, ou invalid.</text></svg>", "caption": "Uma entrada, as duas direções. P é a porta que laptop escolheu para esta conexão.", "same": ["original"]}
```

Uma entrada só é criada quando uma regra aceita o pacote `new`. **Descartar um pacote também
significa não guardar memória dele**, então uma conversa negada não deixa nada na tabela para as
respostas casarem.
