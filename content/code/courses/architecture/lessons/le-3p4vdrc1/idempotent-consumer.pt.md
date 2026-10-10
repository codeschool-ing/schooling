---
title: O consumidor idempotente
version: 1
---

Uma operação é **idempotente** quando fazê-la duas vezes tem o mesmo efeito que fazê-la uma. Definir um
preço como 3.290 é idempotente; somar 3.290 a um saldo não é; cobrar um cartão não é, a não ser que a
cobrança carregue algo que deixe a segunda tentativa ser reconhecida.

A correção comum é tornar duplicatas impossíveis lá antes. Isso não dá para fazer, como a primeira seção
mostrou, então **o consumidor é feito para reconhecer uma mensagem que já tratou**, usando o id que a
mensagem carrega.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O consumidor idempotente. Chega uma mensagem com id q-2. Numa transação do banco o consumidor insere q-2 na tabela processed e insere a cobrança. A primeira entrega confirma as duas coisas. Uma segunda entrega de q-2 falha na chave primária da tabela processed, a transação é desfeita, e o consumidor confirma a mensagem sem cobrar de novo.\"><defs><marker id=\"l7-dedup-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7-dedup-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mensagem</text><text x=\"90\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">id q-2</text><rect x=\"200\" y=\"40\" width=\"300\" height=\"150\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"214\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">uma transação</text><rect x=\"220\" y=\"72\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO processed ('q-2')</text><rect x=\"220\" y=\"128\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT INTO charges …</text><path d=\"M152 115 L198 115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-dedup-ah-amber)\"></path><rect x=\"550\" y=\"50\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">primeira entrega</text><text x=\"625\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as duas gravadas</text><rect x=\"550\" y=\"130\" width=\"150\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">segunda entrega</text><text x=\"625\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chave existe: pula</text><path d=\"M502 92 L548 77\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-dedup-ah-phosphor)\"></path><path d=\"M502 148 L548 157\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-dedup-ah-amber)\"></path><text x=\"350\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois confirma, nos dois casos</text></svg>", "caption": "O registro de ter tratado uma mensagem e o efeito de tratá-la são gravados numa transação, então nunca podem discordar."}
```

O `pay.py` sem `--naive` faz exatamente isso: na mesma transação da cobrança, insere o id da mensagem em
`processed`, cuja chave primária recusa uma segunda inserção do mesmo id. Peça o pagamento `q-2` e caia
depois de cobrar mais uma vez:

```
ana@vm:~/lab/delivery$ $R publish.py q-2 2450
confirmed by the broker: q-2
ana@vm:~/lab/delivery$ $R pay.py --crash-after-charge
charged q-2: 2450 cents (redelivered: False)
crashing before the acknowledgement
```

A mesma queda de antes, e a mensagem de novo sem confirmação. Rode o consumidor normalmente:

```
ana@vm:~/lab/delivery$ $R pay.py
skipped q-2: already charged (redelivered: True)
ana@vm:~/lab/delivery$ $R pay.py --list
charged q-1 3290
charged q-1 3290
charged q-2 2450
```

A mensagem voltou, `redelivered: True`, e desta vez a inserção em `processed` falhou na chave primária, a
transação foi desfeita, e o consumidor confirmou a mensagem **sem cobrar**. A lista mostra `q-2` uma vez,
ao lado das duas cobranças de `q-1` que o consumidor ingênuo deixou para trás.

## Por que a mesma transação importa

O registro de ter tratado a mensagem e o efeito de tratá-la **precisam ser gravados juntos**. Se o
consumidor gravasse `processed` primeiro, confirmasse, e depois cobrasse, uma queda entre os dois
deixaria a mensagem marcada como feita e o cliente nunca cobrado, o que é no máximo uma vez de novo, só
que mudado de lugar. Se cobrasse primeiro e registrasse depois, uma queda entre os dois é a duplicata
que esta seção existe para impedir. Uma transação transforma os dois num único fato.

Quando o efeito não está no banco do próprio consumidor, uma chamada a uma operadora de cartão de
verdade por exemplo, não há transação compartilhada para usar. O consumidor então repassa o id da
mensagem como **chave de idempotência**, e conta com o outro lado para reconhecê-la, que é a próxima
seção.

## Por quanto tempo lembrar

`processed` cresce uma linha por mensagem, para sempre. Um consumidor de verdade guarda os ids por mais
tempo do que o máximo que uma duplicata poderia chegar atrasada, o que é limitado pela reentrega do
broker e por quão para trás alguém poderia reler, e apaga as linhas mais antigas. O limite é uma decisão;
deixá-la sem tomar é uma tabela que enche um disco em um ano.
