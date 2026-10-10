---
title: Dois jeitos de as pessoas chegarem
version: 1
---

Um teste de carga precisa dizer como as suas requisições chegam, e há duas respostas que se
comportam de jeitos muito diferentes quando o servidor fica lento. A maioria das ferramentas usa uma
delas por padrão, e a maioria das pessoas escolhe um número de "usuários" sem perceber que escolheu
um modelo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l03-models\" aria-label=\"Dois modelos lado a lado. À esquerda, o modelo fechado: um grupo fixo de usuários virtuais dá voltas num laço, enviando uma requisição ao servidor, esperando a resposta, pensando e enviando de novo; não pode haver mais requisições em voo do que usuários, e um servidor lento deixa os usuários lentos. À direita, o modelo aberto: as requisições chegam a uma taxa, tantas por segundo, de fora, tenham as anteriores sido respondidas ou não; um servidor lento forma uma fila na frente dele, e nada desacelera as chegadas.\"><defs><marker id=\"l03-models-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l03-models-nf-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><text x=\"180.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">fechado: N usuários virtuais</text><rect x=\"40.0\" y=\"70.0\" width=\"120.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><circle cx=\"70.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"100.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"130.0\" cy=\"100.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"70.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"100.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"130.0\" cy=\"130.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"70.0\" cy=\"160.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"100.0\" cy=\"160.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><circle cx=\"130.0\" cy=\"160.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"100.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os usuários</text><rect x=\"240.0\" y=\"95.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">servidor</text><path d=\"M160.0 105.0 L238.0 105.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"199.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">requisição</text><path d=\"M240.0 155.0 L162.0 155.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"201.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resposta</text><path d=\"M100 70 C100 40, 60 40, 60 58\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-amber)\"></path><text x=\"118.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pensa, e de novo</text><text x=\"180.0\" y=\"238.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um servidor lento desacelera os usuários:</text><text x=\"180.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nunca mais em voo do que N</text><path d=\"M360.0 30.0 L360.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">aberto: λ chegadas por segundo</text><circle cx=\"395.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"411.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"427.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"443.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"459.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><circle cx=\"475.0\" cy=\"130.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><path d=\"M390.0 110.0 L490.0 110.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"440.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">chegam no horário</text><rect x=\"500.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><rect x=\"514.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><rect x=\"528.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><rect x=\"542.0\" y=\"120.0\" width=\"10.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"528.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fila</text><rect x=\"570.0\" y=\"95.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">servidor</text><path d=\"M660.0 130.0 L705.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-models-nf-ah-paper)\"></path><text x=\"540.0\" y=\"238.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um servidor lento faz a fila crescer:</text><text x=\"540.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada desacelera as chegadas</text></svg>", "caption": "Um modelo fechado conta usuários; um modelo aberto conta chegadas. Eles concordam enquanto o servidor acompanha e se separam no momento em que ele não acompanha."}
```

## O modelo fechado: um número fixo de usuários

Num **modelo fechado** há uma população fixa de usuários virtuais, e cada um dá voltas num laço:
envia uma requisição, espera a resposta, pensa, envia a próxima. Uma requisição nova só pode vir de
um usuário que terminou a anterior. Então a carga é declarada como **um número de usuários
virtuais** e um tempo de pensamento, e a taxa de requisições é o que sair deles.

Isso tem uma consequência que surpreende as pessoas da primeira vez. **Quando o servidor fica
lento, um teste fechado fica lento junto com ele.** Todo usuário está preso esperando uma resposta,
ninguém envia nada novo, e o número de requisições em voo nunca passa do número de usuários. O
servidor nunca recebe mais do que consegue acabar terminando, então o teste relata tempos de
resposta longos e uma vazão que parou de crescer, e raramente o colapso que uma multidão de verdade
causaria.

Fechado é o modelo certo quando a população é de fato fixa: quarenta funcionários usando um sistema
interno, um pool de oito workers esvaziando uma fila, um aplicativo de celular que envia uma
requisição por vez e espera. Em cada um desses casos, ninguém novo chega enquanto o sistema está
lento.

## O modelo aberto: uma taxa de chegadas

Num **modelo aberto** as requisições chegam a uma taxa, tantas por segundo, tenham as anteriores
sido respondidas ou não. É assim que um site público recebe os seus visitantes: a pessoa que abre a
bilheteria às 10:00:03 não faz ideia de que o servidor ainda está ocupado com a pessoa que a abriu
às 10:00:02. O `hammer.py` da aula 2 é um gerador aberto, e foi isto o que ele fez com a bilheteria a
150 requisições por segundo, na mesma sessão das rodadas fechadas da próxima seção:

```
ana@nft:~/loadtest$ python3 hammer.py http://127.0.0.1:8000/shows/990 150:5
second  sent  done  errors  median ms  max ms
     0   150   109       0        134    2293
     1   150   145       0        120    4119
     2   150   112       0        257    4384
     3   150   119       0        184    2393
     4   150   131       0        196    2241
134 answers came back after second 4; the last at 7.0 s
```

A coluna `sent` não se mexeu: 150 em todos os segundos, enquanto `done` ficou abaixo disso em cada
um e 134 respostas ainda chegavam depois que o cronograma terminou. Nada num teste aberto espera o
servidor, então um servidor que não acompanha forma uma fila, e a fila é o que o teste mede. O pico
da aula 2, a 200 por segundo, mostrou onde isso termina: medianas na casa dos segundos, e erros.

## Por que a escolha importa

Rode um teste fechado com poucos usuários contra um site público e **o resultado elogia o sistema
exatamente na situação que o teste existe para encontrar**. A lentidão suprime justamente a carga
que a teria exposto. Quem estuda medição chama o erro relacionado de *coordinated omission*
(omissão coordenada): o gerador e o servidor se coordenam, sem querer, para deixar de fora as
requisições que teriam sido enviadas enquanto o servidor estava travado, e eram essas as lentas.

Então a pergunta a fazer antes de escolher é se os usuários deste sistema esperam uns pelos outros.
Na bilheteria, as pessoas que chegam numa venda não esperam, e o seu requisito está escrito como uma
taxa, 50 requisições por segundo na aula 1. Um modelo aberto expressa isso diretamente. Um modelo
fechado ainda consegue produzi-lo, desde que você dimensione os usuários e o tempo de pensamento
para a taxa que quer, e é para isso que serve a lei de Little, duas seções adiante. O k6 da aula 5
oferece os dois tipos de executor pelo nome, e o JMeter da aula 4 é fechado na essência.
