---
title: O ciclo de BI, e onde ele quebra
version: 1
---

Um trabalho de BI dá uma volta. Começa com uma pergunta sobre a qual alguém precisa decidir, junta os
dados que dizem respeito a ela, analisa, mostra a resposta e então — a parte mais esquecida — observa
o que a decisão fez. **A medição do fim é a pergunta do começo da próxima volta.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Seis caixas em ciclo. Linha de cima, da esquerda para a direita: uma pergunta, os dados, a análise. Depois desce para a linha de baixo, da direita para a esquerda: a resposta, mostrada; uma decisão; uma ação. Uma seta da ação de volta à pergunta diz: medir, funcionou?\" data-fig=\"l01-cycle\"><rect x=\"20.0\" y=\"30.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">uma pergunta</text><text x=\"115.0\" y=\"82.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">que loja ampliamos?</text><rect x=\"265.0\" y=\"30.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">os dados</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vendas e área, 9 lojas</text><rect x=\"510.0\" y=\"30.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">a análise</text><text x=\"605.0\" y=\"82.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">vendas por metro quadrado</text><rect x=\"510.0\" y=\"200.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"230.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">a resposta, mostrada</text><text x=\"605.0\" y=\"252.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um ranking numa página</text><rect x=\"265.0\" y=\"200.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">uma decisão</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Helena escolhe a loja</text><rect x=\"20.0\" y=\"200.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"230.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">uma ação</text><text x=\"115.0\" y=\"252.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a obra, e as vendas depois</text><path d=\"M212.0 67.0 L263.0 67.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M263.0 67.0 L254.9 70.9 L254.9 63.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M457.0 67.0 L508.0 67.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 67.0 L499.9 70.9 L499.9 63.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M605.0 106.0 L605.0 198.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M605.0 198.0 L601.1 189.9 L608.9 189.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M508.0 237.0 L457.0 237.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M457.0 237.0 L465.1 233.1 L465.1 240.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M263.0 237.0 L212.0 237.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M212.0 237.0 L220.1 233.1 L220.1 240.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M115.0 198.0 L115.0 106.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M115.0 106.0 L118.9 114.1 L111.1 114.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"127.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">medir: funcionou?</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">e a medição é a próxima pergunta</text></svg>", "caption": "O ciclo de BI com o exemplo da aula 2. Começar pelos dados em vez da pergunta, e parar na resposta em vez da ação, são os dois jeitos mais comuns de quebrá-lo."}
```

Pegue o exemplo da figura, que a aula 2 percorre com números de verdade. Helena quer ampliar uma loja.
A pergunta é qual. Os dados são as vendas e a área de cada loja, que a Varanda já registra. A análise
divide um pelo outro. A resposta é um ranking numa página. A decisão é da Helena, e a ação é a obra. A
volta se fecha quando, um ano depois da obra, alguém compara as vendas daquela loja com o que eram e
com as lojas que não foram mexidas.

## Seis passos, seis lugares para errar

| passo | a pergunta que ele responde | como costuma dar errado |
|---|---|---|
| uma pergunta | o que precisa ser decidido, por quem, até quando? | é pulada: "temos muitos dados, o que dá para fazer com eles?" |
| os dados | que registros dizem respeito a ela, e dá para confiar neles? | o dado fácil de obter toma o lugar do dado que importa |
| a análise | o que os registros dizem sobre a pergunta? | o método é escolhido antes de a pergunta ser entendida |
| a resposta, mostrada | o que quem decide precisa ver? | tudo é mostrado, então nada é |
| uma decisão | qual opção, e quem é o dono dela? | ninguém é nomeado, então nada é decidido |
| uma ação | o que muda, e quando olhamos de novo? | ninguém olha de novo |

As duas falhas que mais importam estão nas pontas. **Começar pelos dados** produz análise que ninguém
pediu, e as conclusões costumam ser verdadeiras e inúteis: a Varanda vende mais guarda-chuvas quando
chove. **Parar na resposta** produz um painel que é construído, lançado e depois visitado só pelo
autor. As duas parecem trabalho e as duas são invisíveis em qualquer contagem de relatórios entregues.

## O ciclo também é o curso

As aulas seguem a volta. A aula 2 é sobre por que as decisões precisam dela. As aulas 3 e 4 são as
pessoas que a fazem girar e o que elas precisam saber; a aula 5 é a empresa cujas perguntas elas
respondem. As aulas 6 a 9 são os quatro tipos de análise, do que aconteceu ao que fazer a respeito. As
aulas 10 a 12 são os indicadores — escolher, definir e pegar os que enganam. A aula 13 é quem recebe a
resposta, e as aulas 14 a 16 são os três níveis em que uma empresa decide: hoje, este mês, este ano. As
aulas 17 a 21 levam a mesma volta para finanças, varejo, saúde, indústria e relatórios regulatórios.
