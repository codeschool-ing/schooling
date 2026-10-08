---
title: Quantos guardar, e quando não guardar nenhum
version: 2
---

Toda busca deste curso devolveu três pedaços. Três é uma escolha, e também é uma escolha devolver alguma
coisa quando nada presta. Esta seção olha para as duas.

## O k

Mais pedaços acham mais respostas e custam mais tokens. A aula 4 contou as duas coisas, e o `measure.py`
mostrou a forma de novo: a busca vetorial acha a resposta em primeiro para 19 das 26 perguntas de
cliente e entre os três primeiros para as 26. Além de três, neste conjunto de teste, não há mais nada a
achar, e cada pedaço a mais é pago no prompt. Num conjunto mais difícil a curva continua subindo mais
adiante; o lugar de parar é onde ela se achata, medido, não onde um tutorial parou.

Há também o gerador a considerar. Um modelo que recebe dez pedaços para achar uma resposta tem nove
chances de citar o errado, e a aula 1 viu isso com três. A aula 12 trata do que fazer quando vários
pedaços são necessários e alguns são ruído.

## Uma nota abaixo da qual nada é devolvido

A busca sempre devolve k pedaços, mesmo para uma pergunta que os documentos não respondem. A aula 1 viu
três seções fracas voltarem para *Can I place an order by phone?*, e o modelo, diante
delas, inventou uma regra sobre pedidos por telefone. Um pipeline que conta com o gerador para perceber está contando com o componente
menos capaz disso. A busca pode conferir antes.

O `scores.py` imprime a melhor nota que cada uma das 30 perguntas de teste recebe, ordenadas, com as
quatro que não têm resposta nos documentos marcadas:

```schooling-example
{
  "language": "python",
  "file": "scores.py",
  "parts": [
    {
      "code": "import json\n\nfrom search import vector\n\nfor line in open(\"data/eval.jsonl\"):\n    q = json.loads(line)\n    best = vector(q[\"question\"], 1)[0][3]\n    print(f\"{best:.3f}  {'answerable  ' if q['facts'] else 'unanswerable'}  {q['question']}\")",
      "note": "A melhor nota que a busca vetorial dá a cada uma das trinta perguntas, e se a pergunta tem resposta nos documentos."
    }
  ]
}
```

```
ana@vm:~/rag$ python scores.py | sort -r
0.902  answerable    When can an audiobook be refunded?
0.836  answerable    How many days do I have to return a printed book?
0.835  answerable    How long is a gift card valid?
0.806  answerable    Who pays for the return postage?
0.779  answerable    On how many devices can I read my e-books?
0.772  answerable    How long does a pickup point keep my parcel?
0.765  answerable    What commission does Marginalia take from a marketplace seller?
0.758  answerable    How long after my return arrives will I get the refund?
0.754  answerable    My e-book was downloaded yesterday, can I still get my money back?
0.745  answerable    Can express orders go to a post office box?
0.731  answerable    What does error E-4102 mean in the affiliate API?
0.726  answerable    What commission do affiliates earn on e-books?
0.692  answerable    How long is the statutory right of withdrawal?
0.690  answerable    Will my e-books open on a Kindle?
0.658  answerable    How much is express delivery?
0.657  answerable    Can I get an invoice in my company's name after the order has shipped?
0.646  answerable    How long do you keep my order history?
0.646  answerable    Can I return a signed copy?
0.639  answerable    How often are sellers paid?
0.637  answerable    Above what order value is standard delivery free?
0.623  answerable    When is a standard parcel considered lost?
0.592  answerable    Do you store my IP address?
0.583  answerable    When is the contract of sale formed?
0.565  answerable    What must I check before changing a customer's order?
0.542  answerable    What is the most a support agent can refund without approval?
0.476  unanswerable  Can I place an order by phone?
0.445  answerable    Can I pay in instalments?
0.391  unanswerable  Do you have a shop in Porto Alegre where I can pick up books?
0.376  unanswerable  Which carrier do you use in Portugal?
0.354  unanswerable  Is there a student discount?
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas linhas de pontos num eixo de similaridade de 0,3 a 0,9. As 26 perguntas com resposta têm melhor nota de 0,445 a 0,902; as quatro sem resposta, de 0,354 a 0,476. Um corte em 0,5 mantém 25 perguntas com resposta e recusa as quatro sem resposta e uma com resposta, com 0,445.\"><path d=\"M60 150 L680 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60.0 150 L60.0 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"60.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,3</text><path d=\"M155.38461538461542 150 L155.38461538461542 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"155.38461538461542\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,4</text><path d=\"M250.76923076923077 150 L250.76923076923077 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"250.76923076923077\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,5</text><path d=\"M346.15384615384613 150 L346.15384615384613 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"346.15384615384613\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,6</text><path d=\"M441.5384615384615 150 L441.5384615384615 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"441.5384615384615\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,7</text><path d=\"M536.9230769230769 150 L536.9230769230769 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"536.9230769230769\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,8</text><path d=\"M632.3076923076924 150 L632.3076923076924 155\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"632.3076923076924\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,9</text><text x=\"370.0\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">similaridade do melhor pedaço com a pergunta</text><text x=\"60\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">26 perguntas com resposta</text><text x=\"60\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4 sem resposta nos documentos</text><circle cx=\"634.2\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"571.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"570.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"542.6\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"517.8\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"510.2\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"503.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"496.9\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"493.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"485.4\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"472.1\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"466.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"433.9\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"432.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"401.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"400.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"390.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"390.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"383.4\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"381.4\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"369.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"338.5\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"329.9\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"312.8\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"291.8\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"227.9\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><circle cx=\"198.3\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" fill-opacity=\"0.85\"></circle><circle cx=\"146.8\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><circle cx=\"132.5\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><circle cx=\"111.5\" cy=\"130\" r=\"5\" fill=\"var(--amber)\" fill-opacity=\"0.85\"></circle><path d=\"M250.76923076923077 30 L250.76923076923077 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"256.7692307692308\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um corte em 0,5</text></svg>", "caption": "A melhor nota que cada pergunta de teste recebeu, do scores.py. Os dois grupos se sobrepõem: nenhum corte os separa perfeitamente, e o de 0,5 recusa uma pergunta que poderia ter respondido."}
```

**As quatro perguntas sem resposta estão no fim, abaixo de 0,48, e uma pergunta com resposta também**,
*Can I pay in instalments?*, com 0,445. A resposta está no documento de pagamentos, *A card payment can
be split into up to three instalments*, mas as palavras do pedaço não são as da pergunta, e a nota dele
cai entre as das perguntas que não têm resposta nenhuma.

Então um limiar é uma troca, não uma solução. Um corte em 0,5 recusa as quatro perguntas sem resposta e,
junto com elas, a das parcelas: 25 de 26 respondidas, quatro de quatro recusadas. Um corte em 0,44
responde às 26 e deixa a pergunta do telefone passar para o gerador. Qual erro é pior é uma decisão de
produto, e a tabela da aula 2 diz como ela varia: para um assistente jurídico uma recusa custa pouco e
uma cláusula errada custa muito; para uma central de ajuda, recusar uma pergunta que os documentos
respondem manda um cliente a uma pessoa à toa.

## Tornando o limiar honesto

Três hábitos impedem um limiar de virar superstição.

**Defina-o a partir das notas das suas próprias perguntas**, como aqui, e guarde a lista. O número
depende do modelo de embeddings, do corte e do tipo de pergunta, e está errado no dia em que qualquer um
deles muda.

**Aja sobre ele antes de o gerador ver qualquer coisa.** Abaixo do limiar, não devolva fontes, e deixe o
prompt dizer o que fazer então; a aula 7 escreve esse prompt.

**Registre a nota em cada consulta.** Um limiar definido em trinta perguntas de teste encontra milhares
de perguntas reais, e o registro das notas ao lado das respostas que as pessoas avaliaram é como ele é
ajustado; a aula 9 escreve esse registro.
