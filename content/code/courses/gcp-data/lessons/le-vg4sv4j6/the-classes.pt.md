---
title: O que uma classe de armazenamento troca
version: 1
---

**Uma classe de armazenamento é um preço para guardar um gibibyte junto com um preço para lê-lo de
volta**, e toda classe abaixo do Standard compra um primeiro preço menor com um segundo maior. Os nomes
sugerem um depósito com uma câmara fria no fundo, onde as prateleiras baratas são lentas e um arquivo
guardado precisa ser buscado antes que alguém o abra. O Cloud Storage não funciona assim. As quatro
classes entregam o primeiro byte em milissegundos, pela mesma API, com os mesmos comandos. O que muda é
a conta: para guardar, para ler e para sair antes de um número mínimo de dias.

A classe é escolhida por objeto, não por bucket. Um bucket pode ter os pedidos de hoje em Standard, os
do ano passado em Coldline e as exportações de auditoria de 2019 em Archive, lado a lado sob os mesmos
prefixos. Um bucket tem uma classe padrão, que a próxima seção mostra, e ela é só o que um objeto recebe
quando ninguém pede outra coisa.

Esta aula, como toda aula do curso, supõe o fake-gcs-server rodando no terminal dele e as linhas de
"Every time you open a terminal" da aula 1 digitadas neste.

## Os preços

A página de preços do Cloud Storage, cloud.google.com/storage/pricing, lida em 2026-10-30, dá estes
números para um bucket numa única região, em USD. O preço de armazenamento é o de São Paulo,
`southamerica-east1`; as taxas de recuperação e os preços de operação dessa página são os mesmos para
qualquer região única.

| classe | guardar, por GiB-mês | ler de volta, por GiB | estadia mínima | Class A, por 1.000 | Class B, por 1.000 |
|---|---|---|---|---|---|
| Standard | 0,035 | nenhuma | nenhuma | 0,005 | 0,0004 |
| Nearline | 0,020 | 0,01 | 30 dias | 0,01 | 0,001 |
| Coldline | 0,007 | 0,02 | 90 dias | 0,02 | 0,01 |
| Archive | 0,003 | 0,05 | 365 dias | 0,05 | 0,05 |

**O Standard custa 0,035 por GiB-mês e o Archive 0,003**, então o arquivo guarda um gibibyte por menos
de um décimo do preço. A coluna de recuperação é a outra metade: ler um gibibyte de volta não custa
nada a mais no Standard e custa 0,05 no Archive, mais do que um ano inteiro guardando-o ali.

As operações Class A são as que escrevem ou listam: um upload, uma cópia, uma reescrita, uma listagem.
As Class B são as que leem: um download, um `describe`. As duas têm preço por mil requisições e pela
classe do objeto em que mexem, então um milhão de arquivos pequenos em Archive custa 50 USD para
escrever e outros 50 para ler uma vez, qualquer que seja o tamanho. A aula 5 é onde requisições e rede
recebem preço por inteiro.

```
ana@laptop:~/gcp$ python3 -c 'print(round(0.035 / 0.003, 1), round(1024 * 0.003 * 365 / 30, 2), round(1024 * 0.003 * 10 / 30, 2))'
11.7 37.38 1.02
```

O primeiro número é a razão, Standard sobre Archive, 11,7. Os outros dois são a estadia mínima em
ação, e são o próximo parágrafo.

**A estadia mínima é uma conta por sair cedo.** Um objeto apagado, substituído ou reescrito em outra
classe antes do mínimo é cobrado como se tivesse ficado o mínimo inteiro. Um tebibyte, 1.024 GiB,
guardado em Archive por dez dias custaria 1.024 × 0,003 × 10 / 30 = 1,02 USD; apagado no décimo dia,
é cobrado pelos 365 inteiros, que, contando um mês como 30 dias, dá 1.024 × 0,003 × 365 / 30 = 37,38. A página de preços cita três casos em que a
cobrança não se aplica: um objeto em Standard, uma classe mudada por uma regra de ciclo de vida, e um
objeto num bucket com Autoclass ligado. A aula 3 escreve a regra, e a seção sobre Autoclass desta aula
mostra o bucket.

**Não existe tamanho mínimo cobrado.** Um objeto de 10 KB em Archive é cobrado como 10 KB. O que torna
objetos pequenos caros nas classes mais frias é o preço da requisição, porque a requisição custa o
mesmo para 10 KB e para 10 GB.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Quatro classes do Cloud Storage em dois eixos, com preços de São Paulo. Na horizontal, o preço de guardar um GiB por um mês; para cima, a taxa para ler um GiB de volta. Standard a 0,035 sem taxa e sem mínimo; Nearline a 0,020, 0,01 por GiB lido, mínimo de 30 dias; Coldline a 0,007, 0,02 por GiB, 90 dias; Archive a 0,003, 0,05 por GiB, 365 dias. Toda classe responde em milissegundos: quanto mais barata a prateleira, mais cara a leitura e mais longa a estadia cobrada.\" data-fig=\"l02-classes\"><path d=\"M150.0 270.0 L690.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 270.0 L150.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"150.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M280.0 270.0 L280.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"280.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M410.0 270.0 L410.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"410.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M540.0 270.0 L540.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"540.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.03</text><path d=\"M670.0 270.0 L670.0 275.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"670.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.04</text><text x=\"690.0\" y=\"306.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">guardar, USD por GiB-mês</text><path d=\"M150.0 50.0 L150.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M145.0 270.0 L150.0 270.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"270.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.00</text><path d=\"M145.0 228.0 L150.0 228.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"228.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.01</text><path d=\"M150.0 228.0 L690.0 228.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 186.0 L150.0 186.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.02</text><path d=\"M150.0 186.0 L690.0 186.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 144.0 L150.0 144.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.03</text><path d=\"M150.0 144.0 L690.0 144.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 102.0 L150.0 102.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.04</text><path d=\"M150.0 102.0 L690.0 102.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M145.0 60.0 L150.0 60.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"140.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.05</text><path d=\"M150.0 60.0 L690.0 60.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">ler de volta, USD por GiB</text><circle cx=\"605.0\" cy=\"270.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"605.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard</text><text x=\"605.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sem mínimo</text><circle cx=\"410.0\" cy=\"228.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"418.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Nearline</text><text x=\"418.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mínimo de 30 dias</text><circle cx=\"241.0\" cy=\"186.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"249.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Coldline</text><text x=\"249.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mínimo de 90 dias</text><circle cx=\"189.0\" cy=\"60.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"197.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Archive</text><text x=\"197.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mínimo de 365 dias</text></svg>", "caption": "O que um GiB custa para ficar em São Paulo, contra o que custa para ser lido de volta, e a estadia mínima que cada classe cobra. O primeiro byte chega em milissegundos nas quatro.", "same": ["Standard", "Nearline", "Coldline", "Archive"]}
```

## Escolhendo pela pergunta que os dados respondem

A documentação do Google põe a escolha como uma frequência, e é um bom primeiro corte. **Nearline é
para dados lidos menos de uma vez por mês, Coldline para menos de uma vez por trimestre, Archive para
menos de uma vez por ano**, e Standard para tudo o que é lido com mais frequência, ou guardado por
tempo curto demais para pagar qualquer mínimo. As frequências combinam com as estadias mínimas de
propósito: uma classe cujos dados são lidos uma vez por trimestre também não costuma ver esses dados
apagados dentro dos seus 90 dias.

A frequência é uma regra prática e a conta é aritmética, e as duas podem discordar. Um tebibyte lido
por inteiro todo mês é "lido uma vez por mês", o que a regra põe em Nearline, e a última seção desta
aula mostra o Coldline custando menos para ele em São Paulo. O que a regra acerta é a ordem das
perguntas: com que frequência isto é lido, quanto dele é lido de cada vez, e por quanto tempo é
guardado. As duas primeiras decidem as taxas de recuperação e as requisições, e a terceira decide se
uma estadia mínima vai ser paga por nada.

## O que mais difere, e o que não difere

A página do Google sobre classes de armazenamento, cloud.google.com/storage/docs/storage-classes, diz o
resto, e nada disso é algo que o fake-gcs-server consiga mostrar, porque o emulador guarda todo objeto
na mesma memória, diga a classe o que disser:

- **a durabilidade é a mesma nas quatro**, onze noves por ano por projeto. Uma classe mais fria não
  guarda menos cópias;
- **a disponibilidade é menor nas três mais frias**: a página dá 99,99% de disponibilidade mensal
  típica para o Standard numa região e 99,9% para Nearline, Coldline e Archive, e o acordo de nível de
  serviço também promete menos para elas;
- **a latência e a vazão são as mesmas**. Um objeto em Archive é transmitido na mesma velocidade que
  um em Standard.

Mais dois nomes aparecem na documentação e na API, e este curso não os usa. **Rapid storage** é uma
classe para buckets zonais, feita para latência muito baixa ao lado de um cluster de computação, e
aparece na página de preços ao lado das quatro. `MULTI_REGIONAL`, `REGIONAL` e
`DURABLE_REDUCED_AVAILABILITY` são nomes antigos que a API ainda aceita e que o Google não recomenda
mais; um bucket antigo pode mostrar um deles.
