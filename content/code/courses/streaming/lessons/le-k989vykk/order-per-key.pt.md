---
title: Ordem por chave basta, e é ela que escala
version: 1
---

**Só eventos sobre a mesma coisa precisam ficar em ordem entre si.** A contagem do Recife precisa
vir antes das vendas do Recife. Se a contagem do Recife vem antes ou depois de uma venda de Olinda
não muda nada, porque nenhum evento sobre Olinda toca a linha do Recife. Aquilo de que um evento
trata é a sua **chave**, e manter a ordem *por chave* é uma promessa muito mais fraca do que mantê-la
no log inteiro.

Teste. Rearranje o `stock.log` para que todo evento de Olinda venha primeiro e todos os outros
depois, cada grupo ainda na sua própria ordem. Isso move sete das oito linhas e muda completamente a
ordem entre as lojas:

```
ubuntu@stream:~/work$ (grep olinda stock.log; grep -v olinda stock.log) > by-shop.log
ubuntu@stream:~/work$ python balance.py by-shop.log
olinda  bk-03    3
recife  bk-03    6
```

A mesma resposta do original, 3 e 6. A ordem total do log foi destruída e o resultado não se mexeu,
porque **a ordem dentro de cada chave foi mantida**. Compare com a seção anterior, em que uma única
linha se moveu, dentro de uma chave, e a resposta ficou errada.

## Quanto custa uma ordem total

Uma ordem única para todos os eventos exige um lugar único onde os eventos são postos em ordem: um
arquivo, um processo, uma máquina por onde todo escritor tem de passar. É isso que o `minilog.py` é,
e ele tem um teto: o log só aceita tantos eventos por segundo quanto esse lugar consegue anexar. Pôr
uma segunda máquina não ajuda, a menos que as duas concordem, para cada evento, sobre qual veio
primeiro, e esse acordo é uma ida e volta entre elas a cada escrita.

A ordem por chave tira o teto. Se todo evento sobre o Recife vai para um log e todo evento sobre
Olinda para outro, cada log só precisa manter a própria ordem, e os dois logs podem morar em duas
máquinas que nunca conversam. Cinco lojas podem usar cinco logs; quinhentas lojas podem dividir
cinquenta, desde que **uma loja nunca use mais de um**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"À esquerda: um log com todos os eventos numa ordem total, recife e olinda intercalados, com um único escritor na frente. À direita: os mesmos eventos divididos por chave em dois logs. Um hash da chave escolhe o log, então todo evento de recife vai para o log 0 e todo evento de olinda para o log 1. Cada log mantém a própria ordem, e nada ordena o log 0 em relação ao log 1.\" data-fig=\"l2-per-key\"><text x=\"175\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um log: ordem total</text><rect x=\"20\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"37\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec0</text><rect x=\"60\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"77\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli1</text><rect x=\"100\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"117\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec2</text><rect x=\"140\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"157\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli3</text><rect x=\"180\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"197\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec4</text><rect x=\"220\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"237\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec5</text><rect x=\"260\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli6</text><rect x=\"300\" y=\"110\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"317\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec7</text><text x=\"175\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toda escrita passa por um lugar só</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"250\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><text x=\"545\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">por chave: ordem por chave</text><text x=\"545\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hash(chave) % 2</text><text x=\"400\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">log 0</text><text x=\"400\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">log 1</text><rect x=\"425\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec0</text><rect x=\"465\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec2</text><rect x=\"505\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec4</text><rect x=\"545\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"562\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec5</text><rect x=\"585\" y=\"85\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rec7</text><rect x=\"425\" y=\"155\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"442\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli1</text><rect x=\"465\" y=\"155\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli3</text><rect x=\"505\" y=\"155\" width=\"34\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">oli6</text><text x=\"545\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhuma ordem entre os dois logs</text></svg>", "caption": "Uma ordem total precisa de um lugar por onde passa todo evento; ordem por chave precisa de um lugar por chave.", "same": ["log 0", "log 1"]}
```

## Do hash da chave a um lugar

A regra que manda cada chave para um log tem de dar sempre a mesma resposta, em toda máquina, sem
tabela para consultar. A regra de costume é um hash: calcular um número a partir dos bytes da chave
e tirar o resto da divisão pelo número de logs. `recife` sempre dá o mesmo hash, então cai sempre no
mesmo log, e o mesmo vale para toda outra chave, cada uma no seu log ou dividindo um com outras.

O Kafka chama esses logs de **partições**. Um tópico é um conjunto de partições, o produtor faz o
hash da chave de cada mensagem para escolher uma, e a promessa do Kafka sobre ordem é exatamente a
desta seção: **dentro de uma partição, na ordem em que foi escrito; entre partições, nenhuma**. A
lição 3 mostra o hash funcionando, e uma surpresa nele: dois clientes do Kafka podem mandar a mesma
chave para partições diferentes.

## A chave é uma decisão

Escolher a chave é escolher quais eventos mantêm a ordem entre si, e não existe chave que mantenha
toda ordem que alguém possa querer:

| chave | mantidos em ordem | sem ordem entre si |
|---|---|---|
| loja | todos os eventos de uma loja, seja qual for o livro | duas lojas vendendo o mesmo livro |
| livro | toda venda de um livro, em todas as lojas | as vendas de livros diferentes numa loja |
| nenhuma (sem chave) | nada | tudo; o produtor espalha as mensagens pelas partições |

Os caixas usam a loja, o que serve a um estoque mantido por loja. O caso difícil é um evento sobre
**duas** chaves: uma transferência de cinco exemplares do Recife para Olinda tira de uma linha e põe
em outra, e com a loja como chave ela só fica em ordem com uma das duas. A resposta de costume são
dois eventos, um por loja, cada um com a chave da sua loja, e a lição 8 deixa isso seguro quando um
dos dois chega duas vezes.
