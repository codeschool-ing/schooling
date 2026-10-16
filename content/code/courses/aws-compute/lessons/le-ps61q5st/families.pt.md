---
title: As cinco categorias, e como escolher entre elas
version: 1
---

O jeito mais comum de escolher um tipo de instância é pegar o maior que o orçamento permite, como
se as famílias fossem níveis de qualidade e `r` fosse uma `m` melhor. **Uma família é uma
proporção, não uma posição.** Cada uma junta processador e memória, às vezes discos ou
aceleradores, numa proporção que serve a um tipo de trabalho. O tipo certo é aquele em que o
recurso que o seu programa esgota primeiro é aquele de que você mais paga.

## De onde vem o catálogo

O moto responde a `describe-instance-types` com uma cópia dos dados da própria AWS para cada tipo,
tirada quando aquela versão do moto foi feita. As especificações desta seção são portanto da AWS, ao
contrário dos preços do moto, que são marcadores de lugar:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --query "length(InstanceTypes)"
1373
ana@laptop:~/aws$ aws ec2 describe-instance-type-offerings --query "length(InstanceTypeOfferings)"
743
ana@laptop:~/aws$ aws ec2 describe-instance-type-offerings --location-type availability-zone --filters Name=instance-type,Values=i4i.large --query "InstanceTypeOfferings[].Location" --output text
sa-east-1a	sa-east-1b	sa-east-1c
```

**Existem 1.373 tipos, e 743 deles são oferecidos em São Paulo.** A segunda contagem é a que importa
para um template: um tipo que não é oferecido numa região, ou numa das zonas dela, não pode ser
lançado ali, por mais certo que esteja o resto do pedido. O terceiro comando pergunta por zona, e a
`i4i.large` é oferecida nas três zonas de `sa-east-1`. Um tipo oferecido em duas zonas de três é o
motivo de um auto scaling group, na lição 4, às vezes não conseguir pôr uma instância onde você
esperava.

## As cinco categorias

A AWS separa as famílias em cinco categorias, e a primeira letra do nome diz qual:

| categoria | famílias | para que serve |
|---|---|---|
| uso geral | `m`, `t` | servidores web e de aplicação, quase tudo quando não há motivo para escolher outra |
| otimizada para computação | `c` | trabalho que é quase só conta: codificação, compilação, lotes, servidores de jogos |
| otimizada para memória | `r`, `x`, `u`, `z` | bancos de dados, caches, análises que mantêm o conjunto de trabalho na memória |
| otimizada para armazenamento | `i`, `d`, `h` | bancos de dados que leem e escrevem nos próprios discos locais a taxas muito altas |
| computação acelerada | `p`, `g`, `inf`, `trn`, `f` | GPUs e chips da própria AWS, para treinar e rodar modelos, vídeo, renderização |

Uma máquina de cada, lado a lado:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large c7i.large r7i.large i4i.large g4dn.xlarge --query "InstanceTypes[].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB,InstanceStorageInfo.TotalSizeInGB,GpuInfo.Gpus[0].Name]" --output table
-----------------------------------------------
|            DescribeInstanceTypes            |
+--------------+----+--------+-------+--------+
|  c7i.large   |  2 |  4096  |  None |  None  |
|  g4dn.xlarge |  4 |  16384 |  125  |  T4    |
|  i4i.large   |  2 |  16384 |  468  |  None  |
|  m7i.large   |  2 |  8192  |  None |  None  |
|  r7i.large   |  2 |  16384 |  None |  None  |
+--------------+----+--------+-------+--------+
```

Leia a coluna de memória contra a coluna de vCPU. A `c7i.large` tem 4.096 MiB para 2 vCPU, o que dá
**2 GiB por vCPU**. A `m7i.large` tem 4 GiB por vCPU e a `r7i.large` tem 8. A `i4i.large` tem as
mesmas 2 vCPU e 16 GiB da `r7i.large` e acrescenta um disco NVMe de 468 GB no host, que é o assunto
da lição 3. A `g4dn.xlarge` acrescenta um processador gráfico NVIDIA T4 a 4 vCPU e 16 GiB.

A tabela de preços de 16 de outubro de 2026 dá números às quatro primeiras, por hora em `sa-east-1`:
`c7i.large` 0,13755 USD, `m7i.large` 0,16065, `r7i.large` 0,21105 e `i4i.large` 0,274. As mesmas duas
vCPU custam metade a mais quando vêm com quatro vezes a memória, e o disco da `i4i` soma outros
0,06295 USD por hora em cima da `r7i`. Os tipos acelerados não estão na tabela, porque nada neste
curso precisa de um; os preços deles são muitas vezes esses.

## Escolher pelo que acaba primeiro

Todo programa tem um recurso que esgota primeiro, e a família certa é escolhida por esse recurso e
por nada mais. Dois exemplos com os números da tabela:

**Um serviço Java com um heap de 12 GiB e usando cerca de uma vCPU.** O tipo de uso geral que
comporta a memória é a `m7i.xlarge`, 4 vCPU e 16 GiB, a 0,3213 USD por hora. A `r7i.large`, otimizada
para memória, tem os mesmos 16 GiB com 2 vCPU, a 0,21105. O serviço nunca usou as duas vCPU a mais,
então a `r` economiza 0,11025 USD por hora, o que num mês de 730 horas dá 80,48 USD por instância, e
o mesmo de novo para cada cópia atrás do balanceador.

**Um codificador de vídeo que mantém as duas vCPU em 100% e usa 3 GiB.** A `m7i.large` traz 8 GiB de
que ele não precisa. A `c7i.large` tem as mesmas duas vCPU e 4 GiB, e custa 0,0231 USD por hora a
menos: 16,86 USD por mês por instância.

O erro oposto é igualmente fácil. Um cache numa `c7i.large` guarda um quarto do que a `r7i.large`
guarda, por cerca de dois terços do preço, e passa os dias expulsando entradas que a `r` teria
mantido.

**Nada disso é visível de fora.** O uso de CPU e de memória vem de medir o programa sob a carga real,
o que na AWS significa CloudWatch, e as lições 8 a 10 do `aws-operations` montam isso. O moto não
guarda métrica nenhuma, então neste curso a medição é descrita, não feita. A AWS também tem o Compute
Optimizer, que lê essas métricas e sugere um tipo; ele é a lição 23 do `aws-operations`, e o que ele
sugere é a mesma comparação feita acima, em escala.

## Quando ainda não há nada medido

Um serviço novo, sem histórico, não tem um primeiro recurso que acaba. Comece num tipo de uso geral,
`m` e a geração atual, e trate a escolha como uma hipótese: meça sob carga por uma semana, depois
ande pela proporção. Trocar de tipo é parar e iniciar com outro tipo, coisa que os launch templates da
lição 4 tornam rotina, então o primeiro palpite é barato de corrigir.
