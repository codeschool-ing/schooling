---
title: Quando uma resposta não é analisável
version: 1
---

Três respostas em quarenta ainda não foram analisáveis com o prompt mais rigoroso desta aula. Com
mil mensagens por dia, essa taxa dá umas setenta e cinco respostas por dia que o roteador não
consegue ler. **O programa consumidor precisa de uma decisão escrita para esse caso antes que ele
aconteça**, porque a alternativa é o que o código fizer por acidente.

Há três decisões razoáveis e uma ruim.

## Tentar de novo

Chamar o modelo outra vez com a mesma mensagem. Isso só funciona se a segunda chamada puder voltar
diferente, e no substituto ela não pode:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/retry.jsonl --samples 3
120 calls, prompt 651820d7, written to runs/retry.jsonl
ana@lab:~/triage$ pl check runs/retry.jsonl --failures | grep json
json        111     9
t08    json      not JSON
t08#1  json      not JSON
t08#2  json      not JSON
t19    json      not JSON
t19#1  json      not JSON
t19#2  json      not JSON
t22    json      not JSON
t22#1  json      not JSON
t22#2  json      not JSON
```

Três chamadas por mensagem, e as mesmas três mensagens falham todas as vezes. No substituto um
hábito é decidido pelo prompt e pela mensagem, então perguntar de novo é fazer a mesma pergunta e
receber a mesma resposta. Um modelo real amostrado com temperatura acima de 0 sorteia de novo em
cada chamada, e a aula 8 trata do que isso faz. De um jeito ou de outro, **uma nova tentativa só é
uma nova chance quando algo muda**: o sorteio, o prompt ou o modelo. Uma segunda chamada que inclui
a resposta que falhou e a queixa do analisador é outro prompt, e é a nova tentativa que vale a pena
fazer primeiro. O que quer que você escolha, ponha um limite no número de tentativas, e conte-as.

## Recorrer a um caminho alternativo

Tenha um caminho que não precise da resposta do modelo. Na triagem, é a fila de não classificados,
onde uma pessoa lê a mensagem. **Uma mensagem na fila errada é pior do que uma mensagem em fila
nenhuma**: a segunda está atrasada, e a primeira está atrasada e ainda perdida no meio das mensagens
que outra pessoa está tratando.

## Mandar para uma pessoa

Para uma resposta que é analisável mas falha em `labels` — uma categoria que ninguém conhece — o
destino certo é o mesmo. Mande a resposta crua junto com a mensagem, para a pessoa ver o que deu
errado e para o caso poder entrar no conjunto de teste depois.

## Nunca adivinhar

A decisão ruim é a que parece esperta: procurar `billing` ou `high` no texto não analisável e agir
com o que encontrar. Isso transforma toda falha de formato numa decisão de conteúdo que ninguém
verificou, e é o analisador tolerante da seção anterior levado para a produção, onde nada conta o
que ele faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O que o programa consumidor faz com uma resposta, da esquerda para a direita. A resposta passa por uma etapa de reparo que tira um bloco de código e conta quantas vezes faz isso, depois por uma análise rigorosa, depois pelas verificações fields e labels, e é encaminhada pela categoria. Uma resposta que falha na análise rigorosa, ou em fields ou labels, desce para a fila de não classificados, onde uma pessoa lê a mensagem. Nada adivinha.\"><defs><marker id=\"l03a-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Uma resposta, pelo programa consumidor</text><rect x=\"20\" y=\"44\" width=\"100\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resposta</text><path d=\"M122 70.0 L146 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"150\" y=\"44\" width=\"130\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">etapa de reparo</text><text x=\"215.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">contada</text><path d=\"M282 70.0 L306 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"310\" y=\"44\" width=\"120\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">análise rigorosa</text><path d=\"M432 70.0 L456 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"460\" y=\"44\" width=\"110\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fields, labels</text><path d=\"M572 70.0 L596 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><rect x=\"600\" y=\"44\" width=\"100\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">encaminhar</text><text x=\"650.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pela categoria</text><rect x=\"300\" y=\"160\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fila de não classificados: uma pessoa lê</text><path d=\"M370 98 L370 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><text x=\"378\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falha</text><path d=\"M515 98 L515 156\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03a-ah)\"></path><text x=\"523\" y=\"128.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">falha</text></svg>", "caption": "Todo caminho termina num lugar decidido. A etapa de reparo é parte do programa e é contada; a medição da bancada continua rigorosa e nunca a vê."}
```

## Modos do fornecedor

As APIs de vários fornecedores oferecem um modo JSON ou um modo de saída estruturada, em que a
decodificação do modelo é restringida para que a resposta seja JSON válido, ou siga um esquema que
você fornece. Onde você puder usar um, as falhas desta aula param na origem: nada de bloco de código,
nada de frase na frente. **Ele restringe o formato, não a resposta.** Uma resposta em JSON perfeito
com a categoria errada ainda passa em todas as verificações que o programa consegue rodar em
produção, e é por isso que o conjunto de teste e os rótulos dados por pessoas continuam. A aula 6
mostra o outro jeito de uma resposta não ser analisável, cortada no limite de saída, e nenhum modo
de formato completa um objeto que o modelo foi impedido de terminar.
