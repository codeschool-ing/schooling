---
title: Quatro medidores em toda conta de armazenamento
version: 1
---

**Uma conta do Blob Storage tem quatro medidores, e a capacidade é só um deles.** A capacidade conta
gigabytes guardados por um mês. As operações contam requisições, com preço por 10.000. A recuperação
de dados conta gigabytes lidos de volta dos níveis cool, cold e archive. A banda conta os bytes que
saem. As pessoas estimam uma conta pelo tamanho, multiplicam pelo preço por GB-mês e acertam a conta
de armazenamento e erram a fatura, porque uma conta muito lida é paga principalmente pela leitura.

**Esta seção é ensinada a partir das páginas de preços da Microsoft para o Blob Storage e para banda,
e nada nela foi rodado.** Nenhum emulador mede nada, e a tabela de preços da lição 1 não pôde ser lida
da máquina em que este curso foi gravado. Toda conta abaixo usa preços redondos que dizem ser
ilustrativos, como a lição 1 explicou.

## Os quatro, e suas unidades

| medidor | unidade | o que o move |
|---|---|---|
| capacidade | GB-mês, por nível e por redundância | quanto se guarda, em que nível, com quantas cópias |
| operações | 10.000 operações, por nível, por classe | toda requisição: uma escrita, uma leitura, uma listagem |
| recuperação de dados | GB, no cool, no cold e no archive | bytes lidos de volta de um nível barato de manter |
| banda | GB que sai, por destino | bytes enviados para a internet ou para outra região |

**As operações têm preço por classe, e as classes não custam o mesmo.** A tabela da Microsoft as
agrupa em operações de escrita, operações de leitura, operações de listar e criar contêiner, e todas
as outras operações, com uma linha para cada classe em cada nível. Escritas custam mais que leituras.
Listar tem uma linha própria e não tem preço de leitura. E quanto mais frio o nível, mais custa cada
operação, que é a troca da lição 4 vista do outro lado: cool, cold e archive são baratos de manter
porque cobram para serem tocados.

**A recuperação de dados é uma segunda cobrança na mesma leitura.** Ler um gigabyte do nível cool paga
as operações de leitura e depois o gigabyte; lê-lo do hot paga só as operações. O archive soma, antes
de tudo isso, a reidratação da lição 4.

**Dados que entram são de graça.** A página de banda não cobra nada por bytes transferidos para dentro
do Azure, e é por isso que uma conta enche sem ninguém notar o custo e esvazia caro. As operações de
escrita que põem os bytes lá continuam cobradas: bytes que entram são de graça, requisições que entram
não.

Uma conta com replicação geo-redundante, o GRS e o GZRS da lição 1, tem uma quinta linha: a
transferência de dados de georreplicação, por GB copiado para a região par. Toda escrita é copiada,
então uma conta reescrita com frequência paga pela segunda região a cada reescrita.

## O tamanho de uma operação contra o tamanho de um gigabyte

As unidades escondem a comparação que importa. Aos preços ilustrativos desta lição, 0,02 USD para
guardar um GB no hot por um mês e 0,004 USD por 10.000 leituras, um gigabyte-mês compra
0,02 / 0,004 × 10.000 = 50.000 leituras. Então **quando os blobs de um gigabyte são lidos mais de umas
50.000 vezes por mês no total, as leituras custam mais que guardá-los**. Para um arquivo de 1 GB isso
nunca acontece. Para um gigabyte feito de 262.144 blobs de 4 KB cada, ler cada blob uma vez são
262.144 leituras, 0,10 USD, cinco vezes o armazenamento do mês.

Uma operação tem preço por operação, seja qual for o tamanho, e a capacidade tem preço por byte, seja
qual for o número de blobs. As duas próximas seções saem dessas duas frases.

## Lendo as linhas de verdade

A tabela de preços da lição 1 as imprime. Em `~/azure`, com rede:

```sh
python prices.py Storage Hot
python prices.py Bandwidth
```

**Nenhuma das duas foi rodada quando o curso foi gravado**, pelo motivo que a lição 1 dá, então não há
saída aqui para comparar com a sua. O Azure registra transferências como um serviço à parte, e é por
isso que a segunda linha pede `Bandwidth` e não `Storage`; se ela não imprimir nada para
`brazilsouth`, a fonte a ler é a própria página de preços de banda. Leia a unidade de cada linha antes
do preço: capacidade é por GB-mês, operações por 10K, recuperação e banda por GB. Numa assinatura de
verdade, os mesmos medidores voltam como linhas da fatura, que a lição 14 de `azure-foundations` lê.
