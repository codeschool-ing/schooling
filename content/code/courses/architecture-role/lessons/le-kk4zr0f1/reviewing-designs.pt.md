---
title: Revisando um documento de design
version: 1
---

Uma revisão de design que começa na página um e comenta o que vai encontrando é uma revisão de
texto. Pega frases confusas, nomes estranhos e as preferências de quem revisa, e deixa passar o que
importa: se o design resolve o problema para o qual foi escrito, e o que ele faz quando alguma
coisa falha. **Leia primeiro o problema, depois os atributos de qualidade, depois percorra cada parte
perguntando o que acontece quando ela quebra, e marque cada comentário como bloqueante ou não.** Essa
ordem é o método inteiro.

## O primeiro design de Ícaro

Ícaro Nunes é desenvolvedor júnior em Payments, formado há dois anos. Mais ou menos um repasse Pix em
cinquenta falha na primeira tentativa, porque o banco de destino está indisponível por um instante ou
a requisição estoura o tempo. Uma pessoa do time de Payments percorre a lista de falhas toda manhã e
tenta de novo à mão, então um motorista cujo repasse falhou às 19:00 de uma sexta espera até segunda.
Bruno Farias, o tech lead, pediu a Ícaro um design de novas tentativas automáticas. Ícaro escreveu
um documento de quatro páginas cujo núcleo era um parágrafo:

> Quando um repasse falha, o worker de repasses o devolve à fila com um atraso de 5 minutos, depois
> 15, depois 60. Depois de três novas tentativas sem sucesso, marca o repasse como `failed` e avisa
> o engenheiro de plantão.

Bruno pediu a Renata que revisasse. Ela leu em três passadas, não em uma.

## Primeira passada: o problema e a sua medida

Antes de olhar a solução, Renata procurou duas coisas: o problema numa frase e o número que diria se
o design funcionou. O documento tinha a primeira ("os motoristas esperam demais quando um repasse
falha") e não a segunda. O primeiro comentário dela pedia esse número. A resposta que Ícaro e Bruno
escreveram foi a promessa da Carreto da aula 4: o motorista é pago em até 24 horas depois de uma
entrega comprovada. A mesma conversa trouxe mais dois números: 2% dos repasses falham na primeira
tentativa, cerca de 160 por dia num total de uns 8.000.

**Um design sem medida declarada não pode ser revisado, só aprovado ou reprovado no gosto.** Com a
promessa das 24 horas no documento, todo comentário seguinte tinha contra o que ser testado. Novas
tentativas aos 5, 15 e 60 minutos terminam 80 minutos depois da primeira falha, com folga dentro das
24 horas, então o calendário em si não precisou de discussão nenhuma.

Depois vieram os atributos de qualidade, na forma que a aula 6 deu a eles: qual importa mais aqui, e
do que o time abriria mão por ele? Para repasses a resposta veio na hora. **Um motorista nunca pode
ser pago duas vezes**; um pagamento atrasado é ruim e tem conserto, um duplicado é dinheiro que pode
não voltar. Correção vem antes de velocidade. O documento de Ícaro não dizia isso, e isso estava
prestes a importar.

## Segunda passada: percorrer cada parte e perguntar como ela falha

A aula 1 disse que os conectores importam tanto quanto as caixas. Um passeio pelas falhas leva isso
ao pé da letra: para cada caixa e cada seta do design, pergunte o que acontece se ela falhar, se
ficar lenta ou se fizer o trabalho duas vezes.

Renata desenhou o design de Ícaro em quatro partes, o worker de repasses, a fila, a API Pix do banco
e a tabela de repasses no banco de dados do monólito, e percorreu uma a uma.

- **A fila perde uma mensagem.** O repasse fica em `retrying` para sempre. O alerta de Ícaro só
  disparava depois de três novas tentativas sem sucesso, então uma mensagem perdida não levantava
  nada.
- **O worker cai entre chamar o banco e atualizar a tabela.** O repasse saiu, a tabela ainda diz
  `pending`, e a próxima execução manda de novo.
- **A API do banco estoura o tempo.** Era essa. Um timeout quer dizer "não ouvi resposta", não "não
  aconteceu". O banco pode ter feito a transferência e falhado só em responder a tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Uma sequência entre três participantes: o worker de repasses, a API Pix do banco e a conta do motorista. Um, o worker pede ao banco para pagar o repasse 7731, R$ 1.850. Dois, o banco faz a transferência. Três, a resposta do banco se perde e o worker vê um timeout. Quatro, cinco minutos depois o worker pede ao banco para pagar 7731 de novo. Cinco, o banco transfere de novo e o motorista recebe duas vezes. Uma nota: com uma chave de idempotência por repasse, o passo quatro recebe já pago e nenhum dinheiro se move uma segunda vez.\"><defs><marker id=\"retrywalk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"16\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Worker de repasses</text><path d=\"M110 52 L110 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><rect x=\"265\" y=\"16\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">API Pix do banco</text><path d=\"M360 52 L360 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><rect x=\"515\" y=\"16\" width=\"190\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Conta do motorista</text><path d=\"M610 52 L610 290\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></path><path d=\"M112 94 L356 94\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"235\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1  pagar o repasse 7731, R$ 1.850</text><path d=\"M362 132 L606 132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"485\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2  transferência feita</text><path d=\"M358 170 L114 170\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"235\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">3  resposta perdida: timeout</text><path d=\"M112 216 L356 216\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"235\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4  cinco minutos depois: pagar 7731 de novo</text><path d=\"M362 256 L606 256\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#retrywalk-ah)\"></path><text x=\"485\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">5  transferência feita de novo: pago duas vezes</text><rect x=\"40\" y=\"298\" width=\"640\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"315\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Com uma chave de idempotência por repasse, o passo 4 recebe</text><text x=\"360\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">“já pago”, e nenhum dinheiro se move uma segunda vez.</text></svg>", "caption": "O passeio pelas falhas no desenho de Ícaro. Um timeout não diz se a transferência aconteceu, então uma nova tentativa simples pode pagar o motorista duas vezes; uma chave de idempotência por repasse transforma a repetição numa pergunta que o banco sabe responder."}
```

**Uma nova tentativa depois de um timeout é o jeito mais comum de um sistema de pagamentos pagar
alguém duas vezes.** O remédio é antigo e bem conhecido, e o curso `architecture` tratou dele como
idempotência na aula 7: mandar a mesma chave de idempotência em toda tentativa do mesmo repasse,
para que o banco reconheça a repetição e não pague uma segunda vez, e perguntar ao banco o status do
repasse antes de tentar de novo depois de um timeout. Ícaro conhecia a ideia. Não a tinha ligado ao
próprio design, e é exatamente para isso que serve um passeio pelas falhas.

Para um design deste tamanho, o passeio leva uns vinte minutos. É onde quem revisa com experiência
mais acrescenta, porque se apoia em já ter visto coisas falharem, e é também a parte mais fácil de
ensinar: as perguntas são sempre as mesmas.

## Terceira passada: escrever os comentários e rotular cada um

Renata escreveu sete comentários, e cada um começava com um rótulo dizendo que tipo de comentário
era. Alguns times tiram seus rótulos de uma convenção publicada chamada Conventional Comments; outros
inventam os seus. Estes são os quatro em que a Carreto se fixou.

| rótulo | o que quer dizer | o autor precisa agir? |
|---|---|---|
| **bloqueante** | o design não pode seguir como está escrito | sim, antes de ser aceito |
| **pergunta** | quem revisa não entendeu alguma coisa | responda; a resposta pode virar um comentário bloqueante, ou nada |
| **sugestão** | uma melhoria que quem revisa faria | o autor decide |
| **detalhe** | uma questão de gosto ou de redação | pode ignorar à vontade |

Três dos comentários dela, como ela escreveu:

> **bloqueante:** um timeout do banco não quer dizer que o repasse falhou. Do jeito que está, uma
> nova tentativa depois de um timeout pode pagar um motorista duas vezes. Por favor, mande uma chave
> de idempotência por repasse e confira com o banco o status do repasse antes de tentar de novo
> depois de um timeout.
>
> **pergunta:** o que acontece com um repasse cuja mensagem se perde da fila? Não vejo nada que
> perceberia isso.
>
> **detalhe:** eu chamaria o estado de `awaiting_retry` em vez de `retrying`, já que nada acontece
> enquanto ele espera. A decisão é sua.

**Um comentário bloqueante, uma pergunta e cinco que não pediam nada.** Sem os rótulos, Ícaro teria
diante de si sete comentários de peso aparentemente igual, vindos da arquiteta da empresa. Um
desenvolvedor júnior nessa posição tende a fazer os sete, o detalhe sobre um nome incluído, e a ler a
revisão inteira como um veredito sobre ele mesmo. Com os rótulos, ele sabia exatamente o que estava
entre o design dele e a aceitação.

## O que torna uma revisão útil para quem escreveu

Alguns hábitos importam tanto quanto o método.

- **Revise o design, não o autor.** "Isto tenta de novo depois de um timeout" em vez de "você
  esqueceu dos timeouts". A primeira frase descreve o documento; a segunda descreve Ícaro.
- **Mantenha poucos comentários bloqueantes, e de verdade.** Bloqueante quer dizer que o design é
  inseguro ou não atinge a sua medida. "Eu teria usado outra fila" não bloqueia, a não ser que a fila
  falhe num requisito declarado.
- **Diga o que está bom, com precisão.** O diagrama de estados de um repasse que Ícaro fez era claro
  e completo, e Renata disse isso numa linha. Isso também é informação: diz ao autor o que continuar
  fazendo.
- **Não reescreva o design.** Quem revisa encontra os problemas e os explica. Se Renata tivesse
  reescrito a seção das novas tentativas, o design teria virado dela, e Ícaro teria aprendido que os
  rascunhos dele são substituídos.
- **Converse quando os comentários se acumulam.** Passando de um punhado de comentários sérios,
  trinta minutos num quadro branco valem mais que uma discussão longa por escrito.

A segunda versão de Ícaro acrescentou a chave de idempotência, a consulta de status antes de uma
nova tentativa e uma varredura noturna dos repasses parados em `retrying` há mais de duas horas.
Renata aprovou com um comentário. A aula 11 de `architect-communication` leva os mesmos hábitos à
revisão de código, onde eles valem linha a linha e todos os dias.
