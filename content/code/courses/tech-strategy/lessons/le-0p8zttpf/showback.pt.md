---
title: Showback: a parte de cada time, e a parte sem nome
version: 1
---

A segunda tradução divide a fatura por time. Duas ideias erradas atrapalham o começo. Uma é achar
que a divisão precisa ser exata antes de alguém vê-la, e o trabalho fica esperando uma etiquetagem
perfeita que nunca chega. A outra é dividir a fatura em partes iguais, o que é rápido e dá a todos
os times o mesmo número inútil. **Um primeiro showback é aproximado, publicado e corrigido em
público**, e isso basta para mudar o que os times fazem.

## Etiquetas, e o que não tem nenhuma

Uma etiqueta (tag) é um rótulo num recurso de nuvem dizendo quem é o dono. O time de Plataforma da
Rafaela pediu a cada time que etiquetasse os próprios recursos com o seu nome, e depois de um mês a
fatura se dividiu assim:

| time | custo etiquetado, um mês |
|---|---|
| Checkout | R$ 58.000 |
| Catálogo | R$ 41.000 |
| Bilheteria | R$ 27.000 |
| Dados | R$ 35.000 |
| Plataforma | R$ 22.000 |
| sem etiqueta | R$ 29.000 |
| **total** | **R$ 212.000** |

Pagamentos e Mobile não têm linha própria. O Mobile não roda servidores, e os serviços de Pagamentos
estão entre os recursos sem etiqueta, o que explica em parte por que essa linha existe: **o dinheiro
sem etiqueta é dinheiro que alguém tem e ninguém reclamou.**

Ponha numa planilha. As linhas 2 a 6 são os times, a linha 7 fica vazia e a linha 8 tem o valor sem
etiqueta:

| | A | B | C |
|---|---|---|---|
| 1 | Time | Etiquetado | Com parcela |
| 2 | Checkout | 58000 | |
| 3 | Catálogo | 41000 | |
| 4 | Bilheteria | 27000 | |
| 5 | Dados | 35000 | |
| 6 | Plataforma | 22000 | |
| 7 | | | |
| 8 | Sem etiqueta | 29000 | |

A parcela da fatura sem etiqueta, numa célula vazia:

```localised
=ARRED(B8/SOMA(B2:B8)*100;1)      13,7
```

**13,7% da fatura não tem dono.** Esse número vai no topo de todo relatório de showback, porque diz
quanto confiar em tudo o que está abaixo dele.

## Repartir o que não tem etiqueta

A Coreto reparte os R$ 29.000 sem etiqueta na proporção do que cada time já tem etiquetado: um time
com uma fatura etiquetada maior recebe uma parte maior da que ninguém reclamou. Em C2:

```localised
=ARRED(B2+$B$8*B2/SOMA($B$2:$B$6);0)      67191
```

Copiada até C6, a coluna mostra 47497, 31279, 40546 e 25486. Os R$ 58.000 do Checkout viram
R$ 67.191 com a parcela somada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l12-showback\" aria-label=\"Cinco barras horizontais, uma por time. Cada barra tem uma parte cheia para o custo marcado com a etiqueta do time e uma parte contornada para sua parcela dos R$ 29.000 sem etiqueta. Checkout R$ 58.000 vira R$ 67.191; Catálogo R$ 41.000 vira R$ 47.497; Bilheteria R$ 27.000 vira R$ 31.279; Dados R$ 35.000 vira R$ 40.546; Plataforma R$ 22.000 vira R$ 25.486.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Um mês de showback: R$ 212.000, dos quais R$ 29.000 (13,7%) sem etiqueta</text><text x=\"20.0\" y=\"58.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Checkout</text><rect x=\"130.0\" y=\"40.0\" width=\"293.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"423.5\" y=\"40.0\" width=\"46.5\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"58.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 58.000 → R$ 67.191</text><text x=\"20.0\" y=\"96.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Catálogo</text><rect x=\"130.0\" y=\"78.0\" width=\"207.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"337.5\" y=\"78.0\" width=\"32.9\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.3\" y=\"96.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 41.000 → R$ 47.497</text><text x=\"20.0\" y=\"134.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Bilheteria</text><rect x=\"130.0\" y=\"116.0\" width=\"136.6\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"266.6\" y=\"116.0\" width=\"21.7\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"298.3\" y=\"134.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 27.000 → R$ 31.279</text><text x=\"20.0\" y=\"172.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Dados</text><rect x=\"130.0\" y=\"154.0\" width=\"177.1\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"307.1\" y=\"154.0\" width=\"28.1\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345.2\" y=\"172.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 35.000 → R$ 40.546</text><text x=\"20.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Plataforma</text><rect x=\"130.0\" y=\"192.0\" width=\"111.3\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"241.3\" y=\"192.0\" width=\"17.6\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"269.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 22.000 → R$ 25.486</text><rect x=\"20.0\" y=\"235.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"42.0\" y=\"246.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">com a etiqueta do time</text><rect x=\"250.0\" y=\"235.0\" width=\"14.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"246.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sua parcela dos R$ 29.000 sem etiqueta</text></svg>", "caption": "Rateio proporcional. A parcela de cada time no custo sem etiqueta é proporcional ao que ele já tem etiquetado, então a parte contornada cresce junto com a cheia. Um time que deixa os próprios recursos sem etiqueta paga menos do que gasta, e os times que etiquetam bem cobrem a diferença.", "same": ["Checkout"]}
```

Agora some a coluna:

```localised
=SOMA(C2:C6)      211999
```

**Falta um real.** A parcela de cada time foi arredondada para reais inteiros, e cinco
arredondamentos não se anularam: as parcelas somam R$ 28.999 em vez de R$ 29.000. Não há nada de
errado com o método, e um real não vale uma reunião. O relatório é outra história. Um total que não
bate com a fatura é a primeira coisa que um leitor desconfiado encontra, e depois de encontrá-la ele
discute a aritmética em vez de ler a linha do próprio time. Ou diga isso no relatório — uma linha
com "arredondamento: R$ 1" — ou dê o real que falta à maior parcela, para a coluna fechar. Seja qual
for a escolha, decida antes de o relatório sair, e não depois que alguém perguntar.

## O que o rateio proporcional erra

O rateio proporcional é simples e defensável, e tem uma propriedade ruim: **não recompensa ninguém
por etiquetar.** Um time que etiqueta todos os recursos continua pagando sua parcela dos recursos que
outros times deixaram sem etiqueta, e um time que deixa os próprios recursos sem etiqueta paga menos
do que gasta, porque a parte sem etiqueta é repartida pelo que cada time etiquetou. A linha sem
etiqueta não encolhe sozinha.

Então o Davi publica os dois números todo mês: o total de cada time com a parcela, e o percentual sem
etiqueta, que ele e a Rafaela assumem até cair. Cada time vê quanto custam as próprias decisões, e
todo mundo vê se a parte sem dono está diminuindo.

## Showback, não chargeback

O showback mostra a cada time o seu custo. **O chargeback vai além e move o dinheiro**: o custo é
lançado no orçamento do próprio time, que encolhe quando a fatura de nuvem dele cresce.

O chargeback parece mais sério, e na maioria das empresas é prematuro. Ele precisa de um rateio que
todos os times aceitem, porque agora uma regra de arredondamento ou uma parcela do que não tem
etiqueta é dinheiro saindo do orçamento de alguém. Transforma todo custo compartilhado numa
negociação, e dá aos times um motivo para evitar serviços compartilhados — inclusive os do time de
Plataforma — sempre que rodar o próprio parecer mais barato na própria linha. E exige que os times
tenham orçamento, para começo de conversa. Os da Coreto não têm: o orçamento da aula 11 são quatro
linhas da empresa inteira, então um chargeback ali moveria dinheiro entre orçamentos que não
existem.

O showback entrega a maior parte do efeito por uma fração do custo. Os times mudam de comportamento
quando veem o seu número ao lado do seu nome; não precisam que o número seja descontado de nada. A
próxima seção é o que eles encontram quando olham.
