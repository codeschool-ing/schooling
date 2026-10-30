---
title: De onde vêm os preços deste curso
version: 1
---

**Todo preço deste curso foi lido nas páginas públicas de preços do Google em 30 de outubro de 2026,
em dólares americanos, para a região de São Paulo, `southamerica-east1`, a menos que a frase diga
outra coisa.** Cada um é citado com a página de onde veio e a unidade em que é cobrado, e todo total é
mostrado como uma conta que você pode rodar. Os preços mudam no ritmo do Google e não no deste curso,
então um número aqui é um fato sobre aquela data, e a página é onde conferir o de hoje.

## Por que não há um programa que os busque

O Google publica os preços em dois lugares. A **página de preços de cada produto**, como
`cloud.google.com/storage/pricing`, é um documento para pessoas, com uma tabela por região. A **Cloud
Billing Catalog API** é a mesma lista para programas: cada serviço, cada *SKU* (uma unidade de
estoque, a palavra do Google para uma coisa com preço, como "Standard Storage São Paulo") e cada
faixa. A API é a ferramenta certa, e ela precisa de uma chave de API, que precisa de um projeto, que
precisa de uma conta. Então este curso lê as páginas e anota a data, e nunca mostra um número que não
leu lá.

**Três coisas numa página de preços decidem quanto uma linha custa**, e cada uma é um jeito de
lê-la errado:

- **A região.** O mesmo armazenamento custa um valor diferente em São Paulo e em Iowa, e a página
  mostra uma região por vez.
- **A unidade.** O armazenamento é cobrado por **GiB-mês**, um gibibyte (2³⁰ bytes, não 10⁹) guardado
  por um mês, e calculado a partir do que está armazenado a cada momento. As operações são cobradas
  por milhar, as consultas do BigQuery por tebibyte, e uma máquina por hora ou por segundo.
- **A parte gratuita.** Algumas linhas têm uma franquia que não é cobrada, e algumas franquias valem
  só para algumas regiões. A linha de armazenamento Standard de Iowa vem marcada com uma; a de São
  Paulo, não.

## Os dois primeiros preços

De `cloud.google.com/storage/pricing`, lida em 2026-10-30: o armazenamento Standard numa única região
custa **US$ 0,035 por GiB-mês em São Paulo** e **US$ 0,02 em Iowa**, `us-central1`. Um tebibyte por
um mês em cada uma:

```
ana@laptop:~/gcp$ python3 -c 'print(round(1024 * 0.035, 2), round(1024 * 0.020, 2))'
35.84 20.48
```

**US$ 35,84 contra US$ 20,48, 75% a mais para guardar os mesmos bytes no Brasil.** Essa diferença é
a primeira decisão que este curso precifica. Manter os dados da Quitanda em São Paulo não sai de
graça, e levá-los para Iowa também não: a aula 5 mostra que tirar dados de uma região para fora custa
dinheiro, e a lei brasileira de proteção de dados, a LGPD, põe condições para mandar dados pessoais
de um cliente para fora do país. Ser o mais barato é uma propriedade de uma região, e as aulas a
tratam como uma entre várias.

A mesma página cobra pelas **operações**, por milhar de requisições, por classe. Para um bucket numa
região na classe Standard, uma operação de **Classe A** (uma que escreve ou lista, como um upload)
custa **US$ 0,005 por milhar**. Uma operação de **Classe B** (uma que lê, como um download ou a
leitura de metadados) custa **US$ 0,0004 por milhar**. Um upload por minuto durante trinta dias, e um
milhão de leituras:

```
ana@laptop:~/gcp$ python3 -c 'print(round(30 * 24 * 60 * 0.005 / 1000, 2), round(1_000_000 * 0.0004 / 1000, 2))'
0.22 0.4
```

**Vinte e dois centavos e quarenta centavos**, e é por isso que as operações somem numa fatura cheia
de arquivos grandes e são a fatura inteira numa cheia de arquivos pequenos. A aula 5 é sobre o
segundo caso.

## A fatura, sem fatura

**Toda aula que faz uma escolha a precifica**, porque no Google Cloud um desenho e a fatura dele são
a mesma decisão. Uma tabela particionada pela coluna errada é uma tabela que toda consulta lê
inteira, e uma instância do Spanner dimensionada para o pico é uma instância paga pelo pico o mês
inteiro. O custo é a única coisa deste assunto que se aprende sentindo, e este curso não tem como
fazer você sentir, porque nada nele encosta numa conta real. Ele faz o melhor seguinte: o preço é
lido na página, a conta é mostrada, e o número é verificável em vez de afirmado.

O dinheiro neste curso é, portanto, sempre um cálculo e nunca uma fatura. Isso é mais seguro e
honesto sobre o que é, e não é o mesmo que ver um total real subir durante a noite.
