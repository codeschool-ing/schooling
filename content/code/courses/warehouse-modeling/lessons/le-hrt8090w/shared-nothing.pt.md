---
title: Shared nothing, e o coordenador
version: 1
---

O projeto comum para escalar um warehouse horizontalmente se chama **processamento massivamente
paralelo**, MPP, e quase todo produto que faz isso segue o mesmo plano, **shared nothing** (nada
compartilhado): cada máquina, ou **nó**, tem os seus processadores, a sua memória e a sua parte dos
dados, e nenhum nó lê o disco de outro.

Uma consulta num sistema assim passa por três passos:

1. **Um coordenador a planeja.** Um nó, ou um serviço à parte, recebe o SQL, descobre que dados moram
   onde, e manda a cada nó a sua parte do plano.
2. **Cada nó trabalha nas suas linhas.** Cada um varre a sua parte da tabela fato, filtra e calcula somas
   parciais, em paralelo e sem esperar os outros.
3. **Os resultados parciais são combinados.** Os nós mandam as somas parciais para serem juntadas, e o
   coordenador devolve a resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma consulta num sistema shared-nothing em três passos. O coordenador manda o plano para quatro nós. Cada nó varre só a sua parte das vendas e soma a receita por departamento, produzindo quatro resultados parciais. Os resultados parciais voltam ao coordenador, que os soma na resposta final. Só as somas parciais atravessam a rede, não as linhas.\"><defs><marker id=\"ah-mpp\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"20\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 · o coordenador planeja</text><line x1=\"360\" y1=\"60\" x2=\"105\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"30\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">nó 1</text><text x=\"105\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · varre as suas linhas</text><text x=\"105\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">soma por departamento</text><line x1=\"105\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><line x1=\"360\" y1=\"60\" x2=\"277\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"202\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">nó 2</text><text x=\"277\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · varre as suas linhas</text><text x=\"277\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">soma por departamento</text><line x1=\"277\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><line x1=\"360\" y1=\"60\" x2=\"449\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"374\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"449\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">nó 3</text><text x=\"449\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · varre as suas linhas</text><text x=\"449\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">soma por departamento</text><line x1=\"449\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><line x1=\"360\" y1=\"60\" x2=\"621\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"546\" y=\"100\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"621\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">nó 4</text><text x=\"621\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 · varre as suas linhas</text><text x=\"621\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">soma por departamento</text><line x1=\"621\" y1=\"170\" x2=\"360\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#ah-mpp)\"></line><rect x=\"240\" y=\"210\" width=\"240\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3 · somas parciais juntadas</text></svg>", "caption": "Shared nothing: cada nó trabalha nas suas linhas, e só as respostas se movem."}
```

Para uma consulta como "receita total por departamento", esse plano é quase perfeito. Cada nó soma as
suas vendas por departamento, devolve quatro números, e o coordenador soma quatro conjuntos de quatro
números. **Os dados nunca se movem; só as respostas.** Acrescente um nó e a parte de cada nó diminui, e
o tempo também.

Duas coisas estragam isso, e são o assunto das próximas três seções:

- **Partes desiguais.** A consulta é tão lenta quanto o nó mais lento, então um nó com o dobro de linhas
  faz a consulta inteira levar o dobro.
- **Linhas que precisam se mover.** Uma junção entre duas tabelas só funciona num nó que tenha as duas
  linhas correspondentes. Se elas estão em nós diferentes, uma delas precisa viajar pela rede antes.

As duas dependem de uma decisão tomada quando a tabela é criada: **que coluna decide onde cada linha
mora.**
