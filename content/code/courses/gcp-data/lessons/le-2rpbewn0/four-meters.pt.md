---
title: Quatro medidores em todo bucket
version: 1
---

**A conta do Cloud Storage tem quatro medidores, e o armazenamento é só um deles.** Os outros três
correm quando os dados são usados: um conta operações, um cobra pela leitura das classes mais frias,
e um conta os bytes que saem. As pessoas calculam um bucket pelo tamanho, multiplicam pelo preço por
GiB-mês, e acertam o bucket e erram a conta, porque um bucket muito lido é pago principalmente pela
leitura.

Os quatro, para um bucket em `southamerica-east1`, de cloud.google.com/storage/pricing, lidos em
2026-10-30, em USD:

| medidor | unidade | Standard | Nearline | Coldline | Archive |
|---|---|---|---|---|---|
| armazenamento | GiB-mês | 0,035 | 0,020 | 0,007 | 0,003 |
| operações Classe A | 1.000 operações | 0,005 | 0,01 | 0,02 | 0,05 |
| operações Classe B | 1.000 operações | 0,0004 | 0,001 | 0,01 | 0,05 |
| recuperação | GiB lido | 0 | 0,01 | 0,02 | 0,05 |

O quarto medidor, a **rede**, tem tabela própria, porque o preço dela depende de para onde os bytes
vão, e não da classe em que estavam guardados. Duas linhas dela importam desde o início: dados
escritos num bucket são de graça, e dados lidos dele para a internet custam 0,12 o GiB nos primeiros
10 TiB do mês. As duas próximas seções são esse medidor.

**Os preços de armazenamento são os de São Paulo; os de operação e de recuperação não são
regionais.** A página imprime o armazenamento por região, e uma tabela só de operações para todo
bucket que fica numa região, com outra para birregiões e multirregiões. Então o lado das requisições
na aritmética desta aula é o mesmo onde quer que o bucket esteja, e só o armazenamento muda.

## Classe A e Classe B

**Uma operação é uma requisição à API, seja o que for que ela carregue.** Uma requisição que envia
4 KiB e uma que envia 4 GiB são, cada uma, uma operação Classe A; uma que lê um byte e uma que lê um
arquivo inteiro são, cada uma, uma Classe B. A página de preços distribui cada método da API numa
classe, e é na distribuição que as pessoas erram:

- **Classe A** é tudo que escreve, e listar: `objects.insert`, `objects.copy`, `objects.rewrite`,
  `objects.compose`, qualquer `patch` ou `update`, e **`objects.list` e `buckets.list`**.
- **Classe B** é ler: qualquer `get`, dos dados ou dos metadados, e ler uma política.
- **De graça** é apagar: `objects.delete`, `buckets.delete`.

**Listar é cobrado como escrita, a doze vezes e meia o preço de uma leitura.** Um programa que lista
um prefixo para descobrir o que ler paga a tarifa cara pela listagem, e uma listagem devolve no máximo
1.000 nomes, então listar dois milhões de objetos são duas mil operações Classe A antes de ler um só
deles. E as classes ficam mais caras à medida que o armazenamento esfria: uma Classe B no Archive custa
0,05 o milhar, 125 vezes o preço do Standard, além da taxa de recuperação de 0,05 o GiB. A aula 2
compara as classes pelo que custam para guardar; esta tabela é o que custam para mexer.

**Uma requisição que falha em geral não é cobrada.** A página diz isso numa nota: operações
respondidas com 307, 4xx ou 5xx não são cobradas, com uma exceção para a página 404 de um bucket de
site. A próxima seção encontra algumas centenas delas.

## O tamanho de uma requisição contra o tamanho de um gibibyte

As unidades escondem a comparação que importa. Um GiB guardado por um mês a 0,035 compra quantas
operações?

```
ana@laptop:~/gcp$ python3 -c 'print(round(0.035 / (0.0004 / 1000)), round(0.035 / (0.005 / 1000)))'
87500 7000
```

**87.500 leituras, ou 7.000 escritas.** Quando os objetos de um gibibyte são lidos mais de umas
87.000 vezes no mês, somando tudo, ler custa mais do que guardar. Para um arquivo de um GiB isso
nunca acontece. Para um gibibyte feito de objetos de 4 KiB, acontece na primeira passada:

```
ana@laptop:~/gcp$ python3 -c 'n = 1024 * 1024 // 4; print(n, round(n * 0.0004 / 1000, 4), round(n * 0.005 / 1000, 4))'
262144 0.1049 1.3107
```

**Um GiB de objetos de 4 KiB são 262.144 objetos.** Ler cada um uma vez custa 0,1049, três vezes o
armazenamento do mês. Escrevê-los custou 1,3107, trinta e sete vezes. Uma requisição tem preço por
requisição, seja qual for o tamanho, e o armazenamento tem preço por byte, seja qual for o número de
objetos. O resto desta aula sai desses dois fatos.

## Nada disso é medido aqui

O fake-gcs-server não conta operações, não cobra nada e não manda conta. O que ele faz é registrar
cada requisição que responde, uma linha cada, e esse log é o que a próxima seção conta. Todo número
desta aula é uma contagem multiplicada por um preço tirado de uma página, com a conta à vista; num
projeto de verdade, os mesmos medidores chegam como SKUs na fatura, que a aula 13 de
`gcp-foundations` lê.
