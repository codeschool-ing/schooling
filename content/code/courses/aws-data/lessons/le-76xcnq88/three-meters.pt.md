---
title: Três medidores em todo bucket
version: 1
---

**Uma conta do S3 tem três medidores, e o armazenamento é só um deles.** Os outros dois correm quando
os dados são usados: um conta requisições, o outro conta bytes que saem. As pessoas estimam um bucket
pelo tamanho, multiplicam pelo preço por GB-mês, e acertam sobre o bucket e erram sobre a conta,
porque um bucket muito lido é pago sobretudo pela leitura.

Esta lição não precisa de bucket para a maior parte do trabalho, só da tabela de preços da lição 1,
que lê o próprio cache e não precisa nem do moto nem da rede. Dois blocos dela desta vez:

```
ana@laptop:~/aws$ python3 prices.py s3 transfer
AWS public price list, sa-east-1, USD, excluding tax

S3 storage, USD per GB-month
  Standard, first 50 TB                                 0.04050  GB-month
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Standard-IA                                           0.02210  GB-month
  One Zone-IA                                           0.01770  GB-month
  Glacier Instant Retrieval                             0.00830  GB-month
  Glacier Flexible Retrieval                            0.00765  GB-month
  Glacier Deep Archive                                  0.00320  GB-month

S3 requests, USD per 1,000
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
  Standard-IA: GET                                      0.00100  per 1,000
  Glacier Instant Retrieval: GET                        0.01000  per 1,000
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month

S3 retrieval, USD per GB
  Standard-IA                                           0.01000  GB
  Glacier Instant Retrieval                             0.03000  GB
  Glacier Flexible, expedited                           0.04200  GB
  Glacier Flexible, standard                            0.01400  GB
  Deep Archive, standard                                0.02800  GB
  Deep Archive, bulk                                    0.00800  GB

Data transfer out of sa-east-1, USD per GB
  to the internet, first 10 TB                          0.15000  GB
  to the internet, next 40 TB                           0.13800  GB
  to the internet, next 100 TB                          0.12600  GB
  to the internet, over 150 TB                          0.11400  GB
  between zones, each direction                         0.01000  GB
  to us-east-1                                          0.13800  GB
  to CloudFront                                         0.00000  GB
  in from the internet                                  0.00000  GB
```

Os três medidores, lidos dessa tabela:

| medidor | unidade | a linha |
|---|---|---|
| armazenamento | GB-mês | Standard, 0,04050 |
| requisições | 1.000 requisições | `PUT`, `COPY`, `POST` e `LIST`, 0,00700; `GET` e o resto, 0,00056 |
| transferência | GB que sai da região | para a internet a partir de 0,15000, caindo com o volume; para outra zona 0,01000; para us-east-1 0,13800; para o CloudFront 0,00000 |

**Um `PUT` custa doze vezes e meia um `GET`**, 0,00700 contra 0,00056 por mil, e um `LIST` é cobrado
como `PUT`, não como `GET`. Um programa que lista um prefixo antes de ler cada objeto paga a tarifa cara
pela listagem. **Dados que entram são de graça**, `in from the internet` a 0,00000, e é por isso que um
bucket enche sem ninguém notar o custo e esvazia caro.

## O tamanho de uma requisição contra o tamanho de um gigabyte

As unidades escondem a comparação que importa. Um gigabyte guardado por um mês custa 0,0405. Isso
compra 0,0405 / 0,00056 × 1.000 = 72.321 requisições `GET`, ou 0,0405 / 0,00700 × 1.000 = 5.786
`PUT`s. Então **quando os objetos de um gigabyte são lidos mais de cerca de 72.000 vezes por mês ao
todo, as leituras custam mais que o armazenamento**. Para um arquivo de 1 GB isso nunca acontece. Para
um gigabyte feito de 262.144 objetos de 4 KB, ler cada objeto uma vez custa
262.144 × 0,00056 / 1.000 = 0,15, mais de três vezes e meia o armazenamento do mês.

Uma requisição tem preço por requisição, seja qual for o tamanho, e o armazenamento tem preço por byte,
seja qual for o número de objetos. Tudo na próxima seção sai dessas duas frases.

## Nenhum destes aparece no moto

O moto não conta requisições nem mede bytes, e nada neste laboratório produz uma conta. Todo número
desta lição é a tabela de preços multiplicada por uma contagem, com a conta mostrada, e as contagens
são do projeto, não medições de algo que rodou. Numa conta real, os mesmos medidores aparecem como
itens da fatura, por tipo de uso, que a lição 15 de `aws-foundations` lê no Cost and Usage Report.
