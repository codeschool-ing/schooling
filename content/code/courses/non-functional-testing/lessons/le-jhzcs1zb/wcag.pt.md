---
title: O que é a WCAG
version: 1
---

Acessibilidade tem o mesmo problema que velocidade: "tem que ser acessível" é um desejo, e nenhum
teste consegue reprová-lo. **As Diretrizes de Acessibilidade para Conteúdo Web, a WCAG, são o que
transforma o desejo numa lista que alguém consegue conferir.** Elas são publicadas pelo W3C, o
órgão que também padroniza o HTML e o CSS, e a versão atual é a WCAG 2.2, Recomendação do W3C
desde 5 de outubro de 2023. A aula 1 escreveu o requisito deste terço como "está conforme à WCAG
2.2 no nível AA no fluxo de reserva", e esta seção diz o que cada palavra dessa frase quer dizer.

O erro comum é imaginar uma lista de dicas: ponha texto alternativo, faça os botões grandes. A
WCAG está mais perto de uma especificação. Cada item dela é uma afirmação sobre uma página que é
verdadeira ou falsa, escrita para que dois testadores olhando a mesma página cheguem ao mesmo
veredito. É isso que permite que ela entre num contrato.

## Quatro princípios, treze diretrizes, critérios de sucesso

A WCAG é construída em três camadas, e só a última é testada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l12-layers\" aria-label=\"A WCAG 2.2 em três camadas. Quatro princípios: perceptível, com 4 diretrizes e 29 critérios de sucesso; operável, com 5 diretrizes e 34; compreensível, com 3 diretrizes e 21; robusto, com 1 diretriz e 2. Só os critérios de sucesso são testados, por exemplo 1.4.3 Contraste (mínimo), nível AA. Embaixo, os níveis se encaixam: 31 critérios no A, mais 24 no AA, 55 ao todo, e mais 31 no AAA, 86.\"><defs><marker id=\"l12-layers-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">princípio</text><text x=\"330.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">diretrizes</text><text x=\"560.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">critérios de sucesso</text><rect x=\"40.0\" y=\"52.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">perceptível</text><path d=\"M184.0 69.0 L246.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"52.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.1 – 1.4</text><text x=\"372.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 diretrizes</text><path d=\"M414.0 69.0 L466.0 69.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"52.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">29</text><text x=\"590.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.4.3 · AA</text><rect x=\"40.0\" y=\"98.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">operável</text><path d=\"M184.0 115.0 L246.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"98.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.1 – 2.5</text><text x=\"372.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 diretrizes</text><path d=\"M414.0 115.0 L466.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"98.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">34</text><text x=\"590.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.1.1 · A</text><rect x=\"40.0\" y=\"144.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">compreensível</text><path d=\"M184.0 161.0 L246.0 161.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"144.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3.1 – 3.3</text><text x=\"372.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 diretrizes</text><path d=\"M414.0 161.0 L466.0 161.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"144.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">21</text><text x=\"590.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3.3.1 · A</text><rect x=\"40.0\" y=\"190.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">robusto</text><path d=\"M184.0 207.0 L246.0 207.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"190.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.1</text><text x=\"372.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 diretriz</text><path d=\"M414.0 207.0 L466.0 207.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-layers-nf-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"190.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"590.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.1.2 · A</text><text x=\"560.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">só estes são testados</text><rect x=\"40.0\" y=\"266.0\" width=\"640.0\" height=\"80.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"50.0\" y=\"276.0\" width=\"400.0\" height=\"60.0\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"60.0\" y=\"286.0\" width=\"170.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A · 31 critérios</text><text x=\"340.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AA · mais 24, 55 ao todo</text><text x=\"565.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AAA · mais 31, 86</text></svg>", "caption": "Princípios contêm diretrizes, diretrizes contêm critérios de sucesso, e só um critério passa ou reprova. Estar conforme no AA é atender a todo critério das duas caixas de dentro."}
```

**Os princípios** são quatro, conhecidos pelas iniciais em inglês como POUR. O conteúdo tem que ser:

| princípio | a pergunta | um exemplo na página de reserva |
|---|---|---|
| **perceptível** | todo usuário consegue captar o que está ali, seja qual for o sentido que usa? | o logo precisa de uma alternativa em texto que um leitor de tela consiga dizer |
| **operável** | todo usuário consegue acionar todo controle? | o controle Book tem que responder ao teclado, não só ao mouse |
| **compreensível** | todo usuário consegue acompanhar e se recuperar de um erro? | um campo de nome vazio precisa de um erro que diga o que fazer |
| **robusto** | funciona com os navegadores e as tecnologias assistivas que as pessoas usam de fato? | um controle tem que expor a eles seu nome e seu papel |

**As diretrizes** ficam abaixo dos princípios, treze delas: 1.1 Alternativas em texto, 1.4
Distinguível, 2.1 Acessível por teclado, 2.4 Navegável, 3.3 Assistência de entrada e assim por
diante. Uma diretriz é um objetivo, e não tem nível nem aprovação ou reprovação própria.

**Os critérios de sucesso** são o que um teste confere. Cada um tem um número, um nome curto, um
nível e uma frase que a página atende ou não. O *1.4.3 Contraste (mínimo)*, nível AA, diz que o
texto tem razão de contraste de pelo menos 4.5:1 contra o fundo, com exceções para texto grande,
logotipos e texto puramente decorativo. **O número é o endereço que você escreve num relatório de
defeito**: "reprova no 1.4.3" aponta uma frase de uma norma, e ninguém precisa discutir o que se
quis dizer. A WCAG 2.2 tem 86 deles.

## Os níveis A, AA e AAA

Todo critério de sucesso tem um de três níveis, e os níveis se encaixam:

- **A** é o piso. Sem ele, algumas pessoas não conseguem usar a página de jeito nenhum: uma imagem
  sem alternativa em texto (1.1.1), um controle que exige mouse (2.1.1), uma página que não declara
  o idioma (3.1.1).
- **AA** acrescenta o que remove as barreiras graves mais comuns: o contraste de 4.5:1 (1.4.3), um
  indicador de foco visível (2.4.7), texto que pode ser ampliado a 200% (1.4.4).
- **AAA** é o mais rígido: contraste de 7:1 (1.4.6), língua de sinais para vídeo gravado (1.2.6).

A conformidade é declarada por página, e num nível. Uma página está conforme no AA quando atende
a todo critério A e a todo critério AA, 55 na WCAG 2.2. Não há nota parcial nem média: uma
página de reserva que atende a 54 deles não está conforme, que é a mesma regra das cinco partes de
um requisito de desempenho na aula 1. Uma regra a mais passa despercebida com facilidade: um
processo só está conforme quando todas as páginas dele estão, então um fluxo de reserva com um
passo ruim reprova inteiro.

**O próprio W3C não recomenda o AAA como meta para sites inteiros**, porque algum conteúdo não
consegue atender a certos critérios AAA de jeito nenhum. O AAA é um conjunto para buscar onde
couber: um serviço público com usuários mais velhos, por exemplo, pode escolher de propósito o
contraste de 7:1.

## O que mudou na 2.2

As versões da WCAG são compatíveis para trás: uma página que atende à 2.2 atende à 2.1 e à 2.0 no
mesmo nível. A 2.1, de 2018, acrescentou critérios para celulares e para baixa visão, como o
*1.4.10 Refluxo* e o *1.4.11 Contraste sem texto*. **A 2.2 acrescentou nove critérios e removeu
um.** Os que um testador encontra numa página de reserva:

| critério | nível | o que pede |
|---|---|---|
| 2.4.11 Foco não encoberto (mínimo) | AA | o controle com o foco não fica totalmente escondido por algo que a página desenhou, como uma faixa fixa |
| 2.5.7 Movimentos de arrastar | AA | tudo que se faz arrastando também se faz com cliques ou toques simples |
| 2.5.8 Tamanho do alvo (mínimo) | AA | um alvo tem pelo menos 24 por 24 pixels CSS, ou esse espaço em volta |
| 3.3.8 Autenticação acessível (mínimo) | AA | entrar não depende de lembrar ou transcrever algo, como um enigma, a menos que haja outro caminho ou uma ajuda, como deixar o navegador colar a senha |
| 3.3.7 Entrada redundante | A | o que o usuário já digitou neste processo não é pedido de novo |
| 3.2.6 Ajuda consistente | A | a ajuda, onde o site oferece, fica no mesmo lugar em toda página |

Os outros três são o 2.4.12 e o 2.4.13, duas versões AAA mais rígidas dos critérios de foco, e o
3.3.9, a versão AAA da autenticação acessível. **O 4.1.1 Análise sintática saiu**: ele pedia
marcação válida, e os navegadores hoje consertam marcação quebrada do mesmo jeito em toda parte,
então ele não protegia mais ninguém. Um relatório de auditoria escrito contra a 2.1 que lista uma
falha no 4.1.1 está relatando algo que a 2.2 não testa.

A aula 13 roda uma auditoria automática contra esses critérios, e a aula 14 testa os operáveis à
mão, com o teclado. Esta aula escreve a página que elas testam.
