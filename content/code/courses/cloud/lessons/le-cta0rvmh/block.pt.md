---
title: "Volumes de bloco: um disco na ponta de um cabo"
version: 1
---

Um volume de bloco é de onde a máquina virtual da aula 4 dá boot, e o que ela ganha quando precisa
de mais espaço. **É um dispositivo de rede, não um disco dentro do servidor**: o provedor guarda os
dados na própria frota de armazenamento e apresenta o volume à instância como se fosse local. Por
isso um volume sobrevive à instância a que estava anexado, e pode ser desanexado de uma instância e
anexado a outra.

Três propriedades decorrem dessa construção.

**Um volume mora numa zona de disponibilidade.** Ele é replicado dentro da zona, então um disco que
falha não o perde, mas uma instância em outra zona não consegue anexá-lo. Levar um volume a outra
zona é copiá-lo, e é para isso que servem os snapshots da próxima seção. Azure e Google também
vendem discos replicados em duas ou três zonas, por um preço maior; o padrão nos três é uma zona. A
aula 9 diz o que é uma zona e por que perder uma é coisa que acontece.

**Um volume fica anexado a uma instância por vez.** Duas máquinas gravando blocos no mesmo disco
teriam cada uma a sua ideia do sistema de arquivos na memória e o corromperiam em minutos, então o
padrão proíbe. Alguns tipos de volume com IOPS provisionado podem ser anexados a várias instâncias
da mesma zona, e isso só funciona com um sistema de arquivos feito para discos compartilhados, o que
ext4 e XFS não são. Quando várias máquinas precisam dos mesmos arquivos, a resposta é o serviço de
arquivos, duas seções adiante.

**Um volume é pago por GB provisionado, não por GB usado.** Você escolhe o tamanho ao criar e o
taxímetro corre sobre esse tamanho, com o sistema de arquivos cheio ou vazio. Estas são as linhas de
EBS da tabela, tiradas da mesma lista pública de preços, com versões fixadas, que o resto do curso
lê, em USD por GB-mês:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -A3 '^EBS'
EBS, USD per GB-month
  gp3 SSD volume                           0.1520       0.0800
  st1 HDD volume                           0.0860       0.0450
  snapshot                                 0.0680       0.0500
```

Um volume `gp3` de 200 GB em `sa-east-1` custa 200 × 0,1520 = 30,40 USD por mês desde o momento em
que existe, anexado ou não. Um volume esquecido depois que a instância foi encerrada continua
gerando cobrança, e é uma das linhas mais comuns numa conta que ninguém sabe explicar; a aula 10 volta a
ele.

## Tamanho, IOPS e vazão são botões separados

Um disco é rápido ou lento de dois jeitos diferentes. **IOPS** conta operações por segundo: quantas
leituras ou gravações pequenas e separadas o volume faz. **Vazão** conta bytes por segundo: com que
rapidez uma leitura sequencial longa flui. Um banco de dados lendo milhares de páginas de 8 KB em
lugares espalhados precisa de IOPS; um job que lê um arquivo de 50 GB do começo ao fim precisa de
vazão. Nos tipos de volume mais antigos os dois cresciam com o tamanho, e as pessoas compravam um
disco maior para ter um disco mais rápido.

O `gp3`, o SSD de uso geral da tabela, separa as duas coisas. Ele vem com uma base de 3.000 IOPS e
125 MiB/s qualquer que seja o tamanho, e mais de cada um se compra à parte, sem acrescentar
gigabytes. O `st1` é um volume de disco rígido feito para o outro tipo de trabalho: mais barato por
GB, 0,0860 contra 0,1520 em São Paulo, rápido em leituras sequenciais longas e lento nas
espalhadas, e não pode ser volume de boot. Escolher entre os dois é uma questão de padrão de acesso,
não de tamanho.

Acima dos blocos, o volume não oferece nada. **Formatar, montar, aumentar o sistema de arquivos
depois que o volume cresce e verificá-lo depois de uma queda são trabalho do sistema operacional**,
o que, nos termos da aula 1, faz deles trabalho seu.
