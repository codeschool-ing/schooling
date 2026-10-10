---
title: Movendo o estoque, um décimo de cada vez
version: 1
---

O serviço de estoque novo está rodando, e ninguém o usa. O primeiro tráfego de verdade que ele recebe
deveria ser uma parte pequena, para um erro machucar pouca gente: um **canário**, por causa dos pássaros
que os mineiros levavam para achar o ar ruim antes de ele chegar até eles. Mande dez por cento do
`/stock/` para ele reescrevendo o arquivo da divisão e recarregando a borda:

```sh
cat > stock-split.conf <<'EOF'
split_clients "${request_id}" $stock_backend {
    10% stock;
    * monolith;
}
EOF
docker compose exec edge nginx -s reload
```

Depois peça o estoque quarenta vezes e conte quem respondeu:

```
ana@vm:~/lab/strangler$ for i in $(seq 40); do curl -s localhost:8080/stock/coffee; done | sort | uniq -c
     35 monolith: coffee 12
      5 stock service: coffee 12
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A borda recebe quarenta requisições para /stock/coffee. Uma divisão manda noventa por cento para o monólito e dez por cento para o novo serviço de estoque; na execução do laboratório foram trinta e cinco e cinco. Mudar o arquivo e recarregar a borda move a parte, até tudo, ou de volta a nada.\"><defs><marker id=\"l15-split-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-split-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-split-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">40 requisições</text><rect x=\"250\" y=\"80\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">borda</text><path d=\"M172 105 L248 105\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-split-ah-wire)\"></path><rect x=\"500\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">monólito: 35</text><rect x=\"500\" y=\"130\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">serviço de estoque: 5</text><path d=\"M392 95 L498 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-split-ah-paper-dim)\"></path><path d=\"M392 115 L498 155\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-split-ah-amber)\"></path><text x=\"430\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90%</text><text x=\"430\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">10%</text></svg>", "caption": "Um canário: o serviço novo recebe primeiro uma parte pequena do tráfego real, e a parte só cresce enquanto ele se comporta."}
```

Cinco de quarenta foram para o serviço novo, perto dos dez por cento pedidos; cada requisição é atribuída
sozinha, então uma rodada curta cai perto da parte e não exatamente nela. As respostas têm o mesmo
número, que é a primeira coisa que um canário confere: **o serviço novo concorda com o velho**. Numa
migração de verdade a conferência é mais ampla, comparando taxas de erro e latência dos dois backends
lado a lado, e um painel que os mostre vale a pena construir antes de o primeiro por cento se mudar.

Escreva o arquivo com `cat >`, como acima, e não com um editor que salva num arquivo novo e o renomeia: o
contêiner da borda vê o arquivo por uma montagem, e um renomear o deixa olhando para o antigo.

Quando a parte tiver crescido sem problema, mande tudo:

```sh
cat > stock-split.conf <<'EOF'
split_clients "${request_id}" $stock_backend {
    * stock;
}
EOF
docker compose exec edge nginx -s reload
```

```
ana@vm:~/lab/strangler$ for i in $(seq 40); do curl -s localhost:8080/stock/coffee; done | sort | uniq -c
     40 stock service: coffee 12
```

**O caminho de volta são os mesmos dois comandos** com a divisão antiga. É isso que torna o strangler
seguro: um passo errado custa o tempo de editar um arquivo, não uma restauração de backup. Só quando o
serviço novo tiver carregado todo o tráfego por tempo suficiente para ninguém mais voltar atrás é que o
código de estoque do monólito é apagado, e com ele o último caminho de volta.
