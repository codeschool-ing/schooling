---
title: Três formas, e a pergunta que as separa
version: 1
---

**Estruturado, semiestruturado e não estruturado não são três tipos de arquivo. São três respostas a
uma pergunta só: onde mora o esquema?** Esquema é a descrição do dado: como os campos se chamam, que
tipo cada um guarda, quais precisam estar lá. Alguém sempre precisa saber disso. As três formas
diferem em quem sabe, e quando.

A imagem comum separa pela extensão: um `.csv` ou um banco de dados é estruturado, um `.json` é
semiestruturado, um `.jpg` ou um `.txt` é não estruturado. Ela funciona vezes suficientes para
sobreviver, e quebra no primeiro caso que importa. Um arquivo CSV tem os nomes das colunas na primeira
linha e nenhum tipo em lugar nenhum, então `12` e `12 min` convivem na mesma coluna sem reclamação. Um
arquivo JSON conferido na entrada contra uma descrição rígida se comporta como uma tabela. A extensão
diz como os bytes estão dispostos. Não diz se alguém os conferiu.

## Uma viagem, anotada três vezes

Esta é a mesma viagem na Roda Livre, do jeito que três sistemas a registram.

**No banco de dados do aplicativo**, ela é uma linha numa tabela cujas colunas foram declaradas antes
de a primeira viagem ser guardada:

| ride_id | start_station | started_at | minutes |
|---|---|---|---|
| R000001 | ST02 | 2025-09-14 07:52 | 12 |

Os nomes e os tipos moram na tabela. Uma linha não chega sem eles, e um valor do tipo errado é recusado
no momento em que é escrito.

**No evento que o aplicativo envia** quando a viagem termina, ela é um documento JSON:

```json
{"ride_id": "R000001", "bike": {"id": "B017", "battery": 82},
 "start": {"station": "ST02", "at": "2025-09-14T07:52:00-03:00"}, "minutes": 12}
```

Os nomes viajam com cada registro, ao lado dos valores. Nada os declarou antes, então o próximo evento
pode trazer um campo que este não tem, ou o mesmo campo com outro tipo. Quem lê os eventos decide o que
esperar.

**No e-mail que o cliente escreveu** depois, ela é uma frase: *"Saí da Rua XV hoje de manhã, doze
minutos, e a doca não queria soltar a bicicleta."* Não há nome de campo nenhum. A estação, a duração e
a reclamação estão nas palavras, e tirá-las de lá significa ler as palavras.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Três painéis. Estruturado: uma tabela cujo cabeçalho declara ride_id, station e minutes com seus tipos, e uma linha embaixo. Semiestruturado: um evento JSON em que os nomes ficam ao lado dos valores e bike está aninhado. Não estruturado: um e-mail cujo corpo é uma frase, com metadados estruturados acima: cliente, hora e um anexo.\" data-fig=\"three-shapes\"><defs><marker id=\"three-shapes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"14\" width=\"222\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">estruturado</text><rect x=\"249\" y=\"14\" width=\"222\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">semiestruturado</text><rect x=\"484\" y=\"14\" width=\"222\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">não estruturado</text><rect x=\"26\" y=\"56\" width=\"198\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"59\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">ride_id</text><text x=\"59\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">string</text><text x=\"59\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">R000001</text><text x=\"125\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">station</text><text x=\"125\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">string</text><text x=\"125\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ST02</text><text x=\"191\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">minutes</text><text x=\"191\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">int32</text><text x=\"191\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">12</text><line x1=\"26\" y1=\"94\" x2=\"224\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"125\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nomes e tipos:</text><text x=\"125\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">na tabela, declarados</text><text x=\"125\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">antes de qualquer linha</text><text x=\"125\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um valor errado é</text><text x=\"125\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">recusado na escrita</text><rect x=\"261\" y=\"56\" width=\"198\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"273.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{\"ride_id\": \"R000001\",</text><text x=\"279.0\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"bike\": {</text><text x=\"291.0\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"id\": \"B017\",</text><text x=\"291.0\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"battery\": 82},</text><text x=\"279.0\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"minutes\": 12}</text><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nomes: em cada registro,</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ao lado dos valores</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada leitor decide</text><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que esperar</text><rect x=\"496\" y=\"56\" width=\"198\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">C0042 · 08:12 · 1 photo</text><rect x=\"496\" y=\"88\" width=\"198\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"595\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">“Saí da Rua XV hoje de</text><text x=\"595\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">manhã, doze minutos, e a</text><text x=\"595\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">doca não queria soltar</text><text x=\"595\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a bicicleta.”</text><text x=\"595\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nomes: nenhum; o sentido</text><text x=\"595\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">está nas palavras</text><text x=\"595\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">alguém precisa</text><text x=\"595\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">interpretar o corpo</text></svg>", "caption": "A mesma viagem três vezes. O que muda é onde ficam os nomes e os tipos: na tabela, em cada registro, ou em lugar nenhum."}
```

## O que muda com a forma

| forma | onde mora o esquema | quando um valor errado é pego | na Roda Livre |
|---|---|---|---|
| **estruturado** | na tabela, declarado uma vez, antes do dado | quando é escrito | viagens, pagamentos, a lista de estações |
| **semiestruturado** | em cada registro, como os nomes ao lado dos valores | quando alguém lê, se conferir | eventos do aplicativo, respostas de API, mensagens dos sensores |
| **não estruturado** | em lugar nenhum; o significado está no conteúdo | quando uma pessoa ou um programa interpreta | e-mails de suporte, fotos de bicicletas danificadas, gravações de ligações |

O resto desta aula pega as três, uma de cada vez, e faz algo com cada uma na sua máquina: uma tabela
que recusa um valor ruim, eventos aninhados transformados em linhas, um lote cuja forma mudou de um dia
para o outro, e um padrão que tira nomes de estações de e-mails. **A pergunta para levar por tudo isso
é a da segunda coluna**, porque ela decide quem paga por um erro, e com quanto atraso.
