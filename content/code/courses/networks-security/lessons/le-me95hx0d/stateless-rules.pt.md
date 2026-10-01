---
title: Um filtro sem estado, e a regra que ele obriga a escrever
version: 1
---

**Um filtro sem estado julga cada pacote sozinho.** Ele não se lembra de nada: um pacote passa ou é
descartado pelo que dizem os próprios cabeçalhos, e o pacote anterior não faz diferença. Os filtros
da maioria dos roteadores funcionam assim, e a aula 17 os escreve nessa sintaxe.

A equipe na LAN precisa da aplicação em `app`, porta 8080, e de mais nada no segmento de servidores.
Escrito como um conjunto de regras sem estado no nftables, no `fw`:

```
root@fw:~# cat stateless.nft
table ip filter {
  chain forward {
    type filter hook forward priority filter; policy drop;
    iifname "eth2" oifname "eth3" tcp dport 8080 accept
  }
}
root@fw:~# nft -f stateless.nft
```

Leia de cima para baixo. Uma **table** guarda chains; `ip` diz que ela trata IPv4. A **chain** se
prende ao hook `forward`, e assim vê o tráfego que atravessa o `fw`, e `policy drop` é o veredito
dela para qualquer pacote que nenhuma regra aceitou. A única regra aceita o que chega da LAN
(`eth2`) e sai em direção aos servidores (`eth3`) na porta 8080.

Então o `laptop` pede a página de saúde da aplicação:

```
ana@laptop:~$ curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"
exit 28
```

Exit 28 é o `curl` desistindo depois dos seus três segundos. O pedido chegou a `app`. **A resposta
não voltou**, porque a resposta também é um pacote, indo de `app` para `laptop`, e nada o aceita. Um
filtro que não se lembra de nada não tem como saber que a resposta pertence a um pedido que ele
deixou passar.

Então um conjunto de regras sem estado precisa de uma segunda regra para cada conversa que permite,
escrita para o sentido contrário:

```
root@fw:~# nft -f stateless.nft
ana@laptop:~$ curl -s -m3 http://192.168.20.10:8080/health; echo "exit $?"
status: ok
exit 0
```

Funciona. E também abre uma porta que ninguém quis abrir, e a próxima seção passa por ela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três máquinas: laptop à esquerda, fw no meio, e à direita app e db. A regra 1 deixa passar o pedido de laptop para app na porta de destino 8080. A regra 2 deixa voltar a resposta de app porque sua porta de origem é 8080. Uma linha tracejada mostra db abrindo uma conexão para laptop também com porta de origem 8080, e a regra 2 a deixa passar, porque uma regra sem estado só vê o número no pacote.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.10.20</text><rect x=\"300\" y=\"90\" width=\"120\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fw</text><text x=\"310\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem memória</text><rect x=\"570\" y=\"40\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"580\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.10</text><rect x=\"570\" y=\"164\" width=\"130\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"580\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.20.30</text><path d=\"M150 100 L300 100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M420 100 L570 66\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"160\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">regra 1: dport 8080</text><path d=\"M570 76 L420 116\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M300 116 L150 116\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"160\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">regra 2: sport 8080, a resposta</text><path d=\"M570 186 L360 186 L360 136\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-amber)\" stroke-dasharray=\"4 3\"></path><path d=\"M330 136 L330 170\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><path d=\"M330 170 L85 170 L85 136\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#st-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"430\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">db, porta de origem 8080: também a regra 2</text></svg>", "caption": "A regra 2 foi escrita para as respostas. Ela aceita qualquer coisa com o mesmo número."}
```
