---
title: Os números por trás de uma chamada ruim
version: 1
---

Mais dois números, e entre os dois eles explicam quase toda reclamação sobre uma chamada, um
streaming ou um jogo que os três primeiros não conseguiram explicar.

**Jitter** é o quanto a latência *varia*. **Perda** é a fração de pacotes que nunca chega.

Nenhum dos dois aparece num plano, os dois são relatados por ferramentas que as pessoas raramente
abrem, e para tráfego ao vivo eles importam bem mais que largura de banda.

## Jitter: a média estava ótima

A latência costuma ser citada como um número só, o que esconde justamente o que importa. Dez
pacotes que levam 40 ms cada e dez pacotes que levam 10, 90, 15, 80, 20, 95, 12, 75, 30 e 73 têm a
mesma média e produzem experiências completamente diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Duas fileiras de dez chegadas de pacote. A de cima é espaçada por igual, a quarenta milissegundos cada. A de baixo é irregular, variando de dez a noventa e cinco milissegundos, com a mesma média. Uma nota diz que a segunda produz uma chamada quebrada.\"><text x=\"30\" y=\"38\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">constante — 40 ms cada</text><rect x=\"30\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"94\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"158\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"222\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"286\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"350\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"414\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"478\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"542\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"606\" y=\"52\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"360\" y=\"110\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">todo intervalo igual — o reprodutor sempre tem a próxima peça pronta</text><text x=\"30\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">com jitter — a mesma média</text><rect x=\"30\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"48\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"180\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"206\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"238\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"396\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"424\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"556\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"590\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"640\" y=\"166\" width=\"28\" height=\"36\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">amontoado e depois nada — o reprodutor seca, e então tem que correr atrás</text></svg>", "caption": "Latência média idêntica. A de cima é uma conversa; a de baixo é a chamada que todo mundo já teve."}
```

Áudio ao vivo tem que ser reproduzido a uma taxa constante — vinte milissegundos de fala a cada
vinte milissegundos, sem exceção. Se a próxima peça não chegou quando a hora dela vem, não há nada
para tocar, e silêncio ou um estalo é a única opção.

Então quem recebe mantém um pequeno **buffer de jitter**: segura alguns pacotes antes de começar,
para que um atrasado tenha margem de chegar. E agora dá para ver a troca, porque é a mesma da seção
anterior numa escala bem menor. Um buffer de jitter maior absorve mais variação e acrescenta o
próprio atraso a cada palavra. As aplicações o ajustam o tempo todo, crescendo quando a rede está
instável e encolhendo quando ela acalma — que é por que uma chamada às vezes desenvolve um atraso
que não estava lá no começo e nunca vai embora direito.

**De onde vem o jitter** é quase sempre a seção anterior. Uma fila que ora está vazia e ora está
cheia entrega exatamente esse padrão. O Wi-Fi acrescenta o seu, já que o rádio é compartilhado e um
quadro pode esperar a vez. E qualquer coisa que de vez em quando decida fazer outra coisa com o
enlace também.

## Perda: a fração que nunca chega

Perda é cotada em porcentagem, e as porcentagens que importam são bem menores do que as pessoas
esperam.

| perda | o que ela faz |
|---|---|
| 0% | nada a discutir |
| abaixo de 0,5% | invisível numa chamada, praticamente invisível num download |
| 1 – 2% | audível numa chamada; um download fica visivelmente mais lento enquanto o TCP recua |
| 2 – 5% | chamadas viram trabalho duro, páginas travam em rajadas |
| acima de 5% | a maior parte das coisas deixa de ser usável |

Dois por cento parece minúsculo e não é, e a razão são as duas metades da aula dois.

**Para o TCP, perda é um freio.** Perda é o único sinal que a rede dá, então o TCP trata cada
descarte como congestionamento e reduz a taxa. Um enlace perdendo 2% tem um remetente que passa a
vida desacelerando e acelerando com cautela, e a vazão desaba para uma fração da capacidade. **Uma
taxa de perda pequena custa uma quantidade grande de banda** — que é por que "a conexão está boa, só
está lenta" tantas vezes quer dizer um cabo descartando pacotes em silêncio.

**Para o UDP, perda é um buraco.** Nada é reenviado, então cada pacote perdido são vinte
milissegundos de fala que nunca vão existir. Os codecs disfarçam um pouco disso adivinhando, e a um
por cento você quase não ouve nada; a cinco você ouve uma conversa feita de fragmentos.

## De onde ela vem, em ordem de probabilidade

Vale saber a ordem, porque as duas primeiras são muito mais comuns que a última e muito mais fáceis
de conferir.

**Um buffer cheio.** Quando a fila da seção anterior de fato fica sem espaço, os pacotes seguintes
são descartados. Perda e inchaço são o mesmo evento em estágios diferentes.

**Alguma coisa física.** Um cabo danificado, um conector solto, interferência, um sinal de Wi-Fi
marginal — erros corrompem quadros, e um quadro corrompido é descartado em silêncio, exatamente como
a aula dois descreveu.

**Congestionamento em algum lugar no meio.** Um enlace entre provedores rodando no limite às nove da
noite, que você não consegue ver, não consegue consertar, e só consegue reconhecer pelo fato de
aparecer no mesmo horário todo dia.

## Juntando os cinco

Você agora tem todos os números desta aula, e o útil é saber qual reclamação cada um explica.

| a reclamação | o número |
|---|---|
| downloads grandes demoram demais | largura de banda |
| tudo parece arrastado, mas os arquivos chegam bem | latência |
| um download é mais lento do que o plano promete | vazão |
| a chamada só quebra quando alguém baixa algo | enfileiramento |
| a voz está picotada e fica cortando | jitter, e perda |
| a conexão está boa e o site está lento | latência, ou a outra ponta |

Essa tabela é a aula inteira. Alguém diz *está lento*, e o trabalho é descobrir em qual linha essa
pessoa está.

## Onde isto te deixa

Jitter é variação no atraso, e áudio ao vivo se importa mais com ele do que com a média, porque
precisa ser reproduzido a uma taxa constante. Perda é a fração que nunca chega — um freio para o
TCP, um buraco para o UDP — e importa em porcentagens bem menores do que parecem.

As três ferramentas que todo mundo abre medem parte disso e escondem o resto em silêncio, então a
última seção desta aula é lê-las com honestidade.
