---
title: Dois eixos, e por que evitá-los
version: 1
---

Um **gráfico de eixo duplo** desenha duas séries num mesmo gráfico com duas escalas verticais: uma à
esquerda, uma à direita. Parece um jeito eficiente de mostrar duas coisas relacionadas. É a forma
mais perigosa do gráfico de linhas, porque dá a quem desenha o controle da primeira coisa para a qual
o leitor vai olhar: **onde e se as linhas se cruzam.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 300\" role=\"img\" data-fig=\"l04-dual\" aria-label=\"Dois gráficos de eixo duplo das mesmas duas séries, os pedidos mensais do Sudeste e do Norte. À esquerda, o eixo do Sudeste vai de 0 a 9.000 e o do Norte também de 0 a 9.000, e o Norte é uma linha fina perto do chão. À direita, o eixo do Sudeste vai de 4.000 a 9.000 e o do Norte de 400 a 1.500, e a linha do Norte sobe íngreme passando a do Sudeste, cruzando-a no meio de 2025. Nada no dado mudou.\"><text x=\"170.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uma escolha honesta</text><path d=\"M60.0 40.0 L60.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M280.0 40.0 L280.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 220.0 L280.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"54.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">0</text><text x=\"54.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">4.500</text><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">9.000</text><text x=\"286.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">0</text><text x=\"286.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">4.500</text><text x=\"286.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">9.000</text><path d=\"M60.0 116.6 L69.6 115.4 L79.1 114.7 L88.7 111.6 L98.3 110.7 L107.8 116.4 L117.4 104.5 L127.0 105.8 L136.5 109.1 L146.1 103.8 L155.7 113.3 L165.2 64.8 L174.8 93.8 L184.3 103.4 L193.9 93.9 L203.5 100.8 L213.0 99.8 L222.6 89.0 L232.2 95.0 L241.7 90.5 L251.3 90.6 L260.9 88.4 L270.4 87.5 L280.0 56.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M60.0 211.1 L69.6 210.0 L79.1 209.3 L88.7 209.1 L98.3 208.4 L107.8 208.5 L117.4 208.0 L127.0 207.7 L136.5 206.9 L146.1 207.2 L155.7 204.9 L165.2 201.2 L174.8 204.5 L184.3 204.7 L193.9 203.7 L203.5 202.3 L213.0 202.1 L222.6 200.7 L232.2 201.0 L241.7 199.3 L251.3 198.4 L260.9 196.9 L270.4 198.2 L280.0 191.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\" stroke-linejoin=\"round\"></path><text x=\"500.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">outra escolha, mesmo dado</text><path d=\"M390.0 40.0 L390.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M610.0 40.0 L610.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390.0 220.0 L610.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"384.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">4.000</text><text x=\"384.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">6.500</text><text x=\"384.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">9.000</text><text x=\"616.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">400</text><text x=\"616.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">950</text><text x=\"616.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">1.500</text><path d=\"M390.0 178.0 L399.6 175.6 L409.1 174.5 L418.7 169.0 L428.3 167.3 L437.8 177.4 L447.4 156.1 L457.0 158.4 L466.5 164.4 L476.1 154.8 L485.7 171.9 L495.2 84.6 L504.8 136.9 L514.3 154.2 L523.9 137.0 L533.5 149.4 L543.0 147.6 L552.6 128.3 L562.2 139.0 L571.7 130.8 L581.3 131.0 L590.9 127.1 L600.4 125.5 L610.0 68.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M390.0 212.6 L399.6 203.8 L409.1 198.1 L418.7 196.1 L428.3 190.7 L437.8 191.5 L447.4 187.1 L457.0 185.0 L466.5 177.9 L476.1 180.7 L485.7 161.9 L495.2 131.6 L504.8 158.6 L514.3 160.3 L523.9 152.1 L533.5 140.5 L543.0 138.8 L552.6 127.9 L562.2 130.3 L571.7 116.1 L581.3 108.4 L590.9 96.6 L600.4 107.4 L610.0 49.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\" stroke-linejoin=\"round\"></path><path d=\"M60.0 270.0 L80.0 270.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"86.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Sudeste (eixo esquerdo)</text><path d=\"M260.0 270.0 L280.0 270.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"286.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Norte (eixo direito)</text></svg>", "caption": "Com dois eixos, quem desenha o gráfico decide onde as linhas se cruzam e quão íngreme cada uma parece. O cruzamento da direita não significa nada."}
```

Os dois gráficos mostram o mesmo dado: os pedidos mensais do Sudeste, entre 5.168 e 8.202, e os do
Norte, entre 445 e 1.445. À esquerda, os dois eixos vão de 0 a 9.000, e o Norte é uma linha fina perto
do chão, que é a verdade sobre o tamanho das duas regiões. À direita, o eixo do Sudeste vai de 4.000
a 9.000 e o do Norte de 400 a 1.500. Agora o Norte **sobe e passa o Sudeste** em 2025.

Esse cruzamento não está no dado. **Ele é consequência de duas faixas de eixo que alguém escolheu**,
e outro par o moveria para antes, para depois, ou o tiraria. O mesmo vale para as inclinações:
qualquer linha fica íngreme ou plana pelo próprio eixo.

## O que o programa faz por padrão

O matplotlib, quando se pede um segundo eixo com `twinx`, ajusta cada eixo à sua série. As duas
linhas passam então a ocupar a altura inteira do gráfico:

```
ana@vm:~/viz$ .venv/bin/python dual.py
left axis:  [5016, 8354]
right axis: [395, 1495]
```

A linha do Norte vai de 395 a 1.495 e a do Sudeste de 5.016 a 8.354, e na página as duas cobrem a
mesma altura. **Uma região com entre um doze avos e um sexto dos pedidos é desenhada tão alta quanto
a maior.** As planilhas fazem o mesmo. O eixo duplo padrão é um gráfico que diz que duas séries têm o
mesmo tamanho.

## O que fazer em vez disso

- **Indexe as duas a um começo comum.** Ponha o primeiro mês em 100 para cada série e desenhe as
  duas num eixo só. Isso compara o crescimento com honestidade, e é a próxima seção.
- **Desenhe dois gráficos**, um em cima do outro, dividindo o eixo horizontal do tempo. Cada um tem a
  sua escala vertical, bem rotulada, e ninguém lê um cruzamento em dois painéis separados.
- **Desenhe uma contra a outra.** Se a pergunta é se duas quantidades andam juntas, ponha uma em cada
  eixo de um gráfico de dispersão (aula 6).

## O caso que as pessoas defendem

Duas séries em **unidades diferentes**, como pedidos e tempo médio de entrega, não podem dividir um
eixo, e às vezes um eixo duplo é desenhado por isso. Mesmo assim dois painéis empilhados fazem o
trabalho melhor, porque o leitor continua sem conseguir deixar de ler os cruzamentos, e em unidades
diferentes um cruzamento não tem sentido por definição.
