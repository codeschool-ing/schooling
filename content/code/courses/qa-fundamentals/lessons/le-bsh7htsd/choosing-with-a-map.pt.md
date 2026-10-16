---
title: Escolhendo testes com um mapa
version: 1
---

**O outro uso da caixa cinza é escolher o que testar.** Saber como um sistema está montado diz por onde os
defeitos tendem a viajar, e que testes valem mais que os outros.

## Defeitos viajam pelas setas

O `orders.py` não calcula preços. Ele pede cada um ao `tickets.py`. Esse único fato, o tipo de coisa que um
desenho de caixas e setas mostra, diz que **todo defeito do `tickets.py` também é um defeito num pedido**,
sem ninguém precisar achar cada um duas vezes. Quem tem sessenta paga inteira num pedido. Uma criança numa
quarta é cobrada em um quarto.

```
lia@lab:~/aurora$ python orders.py wed 20:00 35 8
order 5: 2 tickets, R$ 27,00
```

R$ 27,00 para um adulto e uma criança numa sessão de quarta à noite: R$ 18,00 para o adulto, o que está
certo, e R$ 9,00 para a criança, um quarto do preço cheio. O defeito da soma de descontos da aula 6 chegou
ao pedido sem mudança. Quem testa como caixa cinza e conhece a seta não precisa rodar de novo todos os casos
de preço pelo `orders.py`; precisa de um ou dois para confirmar que a seta existe, e depois pode dizer com
confiança que corrigir o `tickets.py` corrige os dois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 300\" role=\"img\" data-fig=\"l08-map\" aria-label=\"Um mapa de caixas e setas. Um cliente ou a bilheteria manda dia, horário e idades para o orders.py. O orders.py manda idade, dia e horário para o tickets.py e recebe um preço de volta. O orders.py grava uma linha na tabela orders do aurora.db. O relatório de assentos da noite soma a coluna tickets e é lido pela Célia. Três perguntas estão presas: na seta, mesmo formato dos dois lados; no armazém, só quando deve; no leitor, mesmo sentido.\"><defs><marker id=\"qa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente ou bilheteria</text><rect x=\"250.0\" y=\"40.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders.py</text><rect x=\"500.0\" y=\"40.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">tickets.py</text><path d=\"M171.0 62.0 L249.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"210.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">dia, horário, idades</text><path d=\"M401.0 56.0 L499.0 56.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"450.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">idade, dia, horário</text><path d=\"M499.0 72.0 L401.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"450.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">preço</text><rect x=\"250.0\" y=\"150.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aurora.db · orders</text><path d=\"M325.0 85.0 L325.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><text x=\"332.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">grava uma linha</text><rect x=\"500.0\" y=\"150.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">relatório de assentos da noite</text><path d=\"M401.0 172.0 L499.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-amber)\"></path><text x=\"450.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">soma os ingressos</text><text x=\"575.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Célia</text><text x=\"20.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 · seta: mesmo formato dos dois lados?</text><text x=\"20.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 · armazém: só quando deve?</text><text x=\"20.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 · leitor: mesmo sentido?</text></svg>", "caption": "Tudo o que quem testa como caixa cinza precisa saber sobre o programa de pedidos, e nada disso é código. O defeito desta aula ficava entre o armazém e o leitor.", "same": ["Célia"]}
```

## Para onde o mapa aponta

Leia o desenho e pergunte, de cada caixa e de cada seta, o que pode dar errado ali:

- **numa seta**, informação passa de uma parte para outra. O pedido passa o horário no mesmo formato que a
  regra de preço espera? Uma sessão digitada como `9:30` no pedido chega à regra de preço como `9:30`, e a
  aula 4 já sabe o que acontece aí;
- **num armazém**, algo fica guardado depois de o programa terminar. Fica guardado só quando deve? Esta aula
  descobriu que não;
- **num leitor**, outra coisa depende do que foi guardado. O relatório lê a coluna do jeito que o programa de
  pedidos quis dizer? Aqui leu, e é exatamente por isso que as linhas recusadas foram contadas.

Essas três perguntas acham os defeitos que moram **entre** as partes, que nem um teste da regra de preço nem
um teste da tela de pedidos alcançaria sozinho. Conforme os sistemas crescem, cada vez mais defeitos moram
nesses vãos: o código de cada caixa funciona, e as caixas discordam sobre o que entregam umas às outras.

## As três abordagens juntas

| | caixa preta | caixa cinza | caixa branca |
|---|---|---|---|
| **sabe** | a regra | a regra e a arquitetura | o código |
| **confere** | o que o usuário vê | o que o usuário vê e o que foi guardado | o que o código faz, linha por linha |
| **achou aqui** | a sessão das 9:30, a soma de descontos da quarta, entradas ruins | pedidos recusados guardados e contados | a linha não testada dos maiores de sessenta, os caminhos não percorridos |
| **não enxerga** | nada a que nenhuma regra aponte | detalhes de cada linha | código que falta |

Nenhuma abordagem achou tudo, e cada uma achou algo que as outras perderam. Essa é a conclusão prática
destas três aulas: **escolha a abordagem pela pergunta que você está fazendo**, e espere usar as três em
qualquer sistema que valha a pena testar. As próximas aulas se afastam do ângulo de quem testa para o
processo do time, começando pelo mais antigo, em que o teste vinha bem no fim.
