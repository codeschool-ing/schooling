---
title: Quando não há o que rodar
version: 1
---

Toda opção até aqui supôs um programa rodando numa máquina, esperando para montar uma página para
quem pedir. Um número enorme de sites não precisa de um.

Se a página é a mesma para todo mundo, ela pode ser construída uma vez, de antemão, e servida como um
arquivo. Isso é hospedagem estática, e é o arranjo mais barato, mais rápido e mais confiável desta
aula — para os sites em que serve.

## O que um servidor de arquivos não tem

A lista é a razão de ele ser melhor, então vale ler como um conjunto de ausências.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O que um site estático não tem: nenhuma aplicação para travar ou explorar, nenhum banco para copiar, trabalho nenhum por requisição, e nenhum runtime para manter atualizado. O arquivo já existe.\"> <rect x=\"20\" y=\"34\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"188\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">nenhuma aplicação para travar ou explorar</text> <rect x=\"20\" y=\"84\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"188\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">nenhum banco para copiar ou ficar lento</text> <rect x=\"20\" y=\"134\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"188\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">nenhum runtime para manter atualizado</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"142\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">um arquivo, que já existe</text> <text x=\"540\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">servi-lo é a coisa que</text> <text x=\"540\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">computadores fazem melhor</text> <text x=\"540\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">trabalho nenhum por requisição</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um site estático sob carga súbita custa um pouco mais de banda</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">que é uma relação com a popularidade diferente de tudo o mais nesta aula</text> </svg>", "caption": "As vantagens são todas ausências, e ausências não precisam ser operadas."}
```

Não há aplicação, então não há o que travar, não há o que explorar pelo seu código, e não há versão de
nada para manter atualizada. Não há banco de dados, então não há o que copiar e não há consulta para
ficar lenta. Não há trabalho por requisição: o arquivo já existe, e servi-lo é a coisa que computadores
fazem melhor.

A consequência é que os modos de falha das três leituras anteriores em boa parte deixam de valer. Um
site estático sob carga súbita não cai; ele custa um pouco mais de banda. Essa é uma relação com a
popularidade diferente de qualquer outra coisa nesta aula.

## Estático não quer dizer imutável

A objeção comum é que um site de verdade tem conteúdo, e conteúdo muda. Muda mesmo, e a distinção é
sobre **quando** a página é montada e não sobre se ela um dia muda.

Um **gerador** pega seu conteúdo — arquivos, ou um banco, ou uma interface de edição hospedada por
outra pessoa — e produz as páginas, uma vez, no momento da construção. Publique um artigo e o site é
reconstruído e reenviado, em segundos. O visitante continua recebendo um arquivo.

Este site é feito assim, e é por isso que ele carrega do jeito que carrega.

A parte que surpreende as pessoas é o quanto isso se estende. Documentação, sites institucionais,
blogs, cursos, catálogos de produto que mudam diariamente em vez de a cada segundo — todos podem ser
produzidos de antemão. Uma construção que leva um minuto e roda dez vezes por dia é invisível para todo
mundo e remove uma categoria inteira de trabalho operacional.

## E ele ainda faz coisas

Um site estático não é um site sem comportamento. A página é fixa; o que o navegador faz com ela não é.

Busca, um formulário de comentário, um pagamento, um login — cada um deles pode ser uma chamada da
página para outra coisa: um serviço que você aluga, uma função da leitura anterior, uma aplicaçãozinha
num servidor em algum lugar. O site continua sendo um conjunto de arquivos, e as poucas partes que
genuinamente precisam de um computador pensando são as únicas que têm um.

Esse arranjo tem nome no mercado e várias siglas concorrentes; o formato é o que importa. **O padrão é
um arquivo, e as exceções são chamadas.**

## Armazenamento de objetos, que é a mesma ideia por baixo

O serviço que guarda arquivos para esses sites em geral é **armazenamento de objetos**, e vale conhecê-lo
por si porque você vai usá-lo para muito mais do que sites.

Ele guarda objetos — arquivos com um nome e alguns metadados — em buckets, por gigabyte, barato, sem
máquina envolvida e sem limite prático de quanto você põe. É para onde vão os uploads, para onde vão as
cópias de segurança, para onde vai qualquer coisa grande que não seja um banco de dados.

Duas coisas para saber. Não é um disco: não há pastas, apesar das barras nos nomes, e não há renomear
que não seja uma cópia. E ele tem **permissões**, que são a origem do erro grave mais comum desta parte
do mercado: um bucket deixado legível por todo mundo, guardando coisas que não eram para estar assim.
Todo provedor avisa aos gritos, e continua acontecendo, porque o padrão que era conveniente um dia virou
hábito.

## Quando não serve

Quatro casos, e eles são reconhecíveis em vez de sutis.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro casos em que só arquivos não servem: uma página que difere por visitante, conteúdo que muda mais rápido que uma reconstrução, uma construção que passa da paciência, e algo que precisa acontecer quando uma requisição chega.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a página difere por visitante — um painel, um carrinho, um feed</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o conteúdo muda mais rápido do que dá para reconstruir</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a construção passa da paciência que se tem por ela</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">algo precisa acontecer ao receber — um pagamento, um e-mail</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">ponha o máximo possível de um site do outro lado desta linha</text> </svg>", "caption": "Quatro casos reconhecíveis. Tudo que não é um deles não custa nada para operar."}
```

**A página difere por visitante** — um painel com login, um carrinho, um feed personalizado. Algo tem
que montar isso, num servidor ou no navegador depois de uma chamada.

**O conteúdo muda mais rápido do que você consegue reconstruir.** Uma construção de um minuto serve para
um blog e não serve para um preço que se move a cada segundo.

**A construção passa da paciência.** Um gerador produzindo cem mil páginas leva tempo, e times batem
nisso, em geral no pior momento.

**Algo precisa acontecer ao receber** — um pagamento, um e-mail, um registro escrito. Isso é uma chamada
a outra coisa, e a outra coisa é um pedacinho de uma das leituras anteriores.

Nenhum desses argumenta contra o arranjo. Eles marcam a linha, e o instinto útil é pôr o máximo possível
de um site do lado dos arquivos, porque tudo daquele lado não custa nada para operar.
