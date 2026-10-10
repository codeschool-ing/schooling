---
title: "XPath: andando pela árvore em qualquer direção"
version: 1
---

**XPath é uma linguagem de caminhos por uma árvore**, escrita para XML e entendida por todo
navegador também para HTML. Ela se lê como o caminho de um arquivo: passos separados por barras,
cada passo uma tag, e condições entre colchetes. Ela anda de qualquer nó até o pai, os ancestrais
ou os irmãos, nas duas direções, e compara **texto**. O texto é a única coisa que ela faz e que o
CSS não faz de jeito nenhum, e é também de onde vem a maior parte das suas quebras.

## As peças

| expressão | quer dizer |
|---|---|
| `//li` | todo `li`, a qualquer profundidade |
| `/html/body/main` | a partir da raiz, um filho de cada vez |
| `//li[h2="Mango"]` | um `li` com um filho `h2` cujo texto é `Mango` |
| `.` | o texto inteiro do nó, incluindo o dos descendentes |
| `text()` | só os nós de texto do próprio nó, um de cada vez |
| `contains(., "Man")` | verdadeiro quando o primeiro texto contém o segundo |
| `..` ou `parent::*` | um passo acima |
| `ancestor::li` | qualquer `li` acima, a qualquer altura |
| `following-sibling::button` | um `button` depois deste nó, sob o mesmo pai |
| `[2]` | o segundo, contado entre os irmãos que o passo selecionou |

O Playwright, e portanto o `count.mjs`, trata um texto que começa com `//` como XPath. Um que
começa com uma barra só ou com um parêntese precisa dizer isso com `xpath=` na frente, senão o
Playwright o lê como CSS e para no primeiro caractere que não consegue analisar.

## Para cima, para o lado e pelo texto

```
%%CAP count-xpath%%
```

As quatro acham um elemento, e cada uma o acha pela palavra *Mango*. A primeira é o próprio
título. `//li[h2="Mango"]//button` é a frase que o CSS não conseguia escrever: o botão dentro do
cartão cujo título diz Mango. As duas últimas chegam ao mesmo lugar por outros caminhos, do título
**para o lado**, até o botão irmão, e dos botões **para cima**, até o único cartão em volta deles
que tem aquele título.

Esse é o argumento a favor do XPath, e ele é mais estreito do que já foi. No Playwright você
raramente precisa dele, porque os localizadores do próprio Playwright filtram por texto e se
encadeiam, como mostra a última seção de leitura desta aula. No Selenium, que a aula 8 acrescenta
ao projeto, o XPath ainda é o jeito comum de achar um elemento pelo texto.

## Por que ele quebra

O mesmo poder faz expressões que quebram, ou que acham a coisa errada, por motivos que ninguém
adivinharia lendo a expressão:

```
%%CAP count-xpath-brittle%%
```

- **`//p[text()="R$ 5,90"]` não acha nada**, e a tela mostra esse preço. Dois motivos, ambos
  invisíveis: o espaço depois de `R$` é o inseparável, e o nó de texto do próprio preço é `R$ 5,90`
  seguido de um espaço comum, porque o `small` começa depois dele. O `text()` compara esse texto
  exatamente, caractere por caractere;
- **`//p[contains(., "5,90")]` acha dois.** O `R$ 5,90` da banana e o `R$ 15,90` do caju, que também
  contém `5,90`. Afrouxar a comparação resolveu o primeiro problema e comprou um pior: a expressão
  agora só está certa enquanto nenhum outro preço contiver esses quatro caracteres, e isso não é
  algo que alguém confere quando os preços mudam;
- **`/html/body/main/ul/li[1]/button` acha o botão da banana**, e nomeia cada tag desde a raiz, e
  uma posição. Ponha a lista dentro de uma `div` e ela não acha nada. Esse é o formato que o
  **Copy full XPath** do Chrome entrega, no menu do botão direito do elemento no painel Elements, e
  é o formato a reescrever antes que chegue a um teste;
- **`(//li)[2]//h2` acha Mango porque Mango é o segundo.** Não diz nada sobre mangas.

**Uma expressão XPath que compara texto é tão estável quanto o texto**, e ela compara mais do texto
do que quem lê a expressão enxerga. Quando usar uma, compare o `.` inteiro em vez do `text()`,
prefira uma palavra que só um elemento tem, e conte os resultados antes de confiar nela.
