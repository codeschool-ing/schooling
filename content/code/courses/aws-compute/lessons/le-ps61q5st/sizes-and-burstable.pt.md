---
title: Tamanhos, preço por tamanho e a família burstable
version: 1
---

Um tamanho parece um ajuste de qualidade, pequeno para teste e grande para produção. **Dentro de uma
família, um tamanho é só uma quantidade**: cada degrau acima é o dobro de vCPU e o dobro de memória,
pelo dobro do preço por hora. O que muda de fato com o tamanho é tudo o que a tabela não imprime nas
primeiras colunas, e uma família quebra o padrão por completo.

## O dobro, pelo dobro do preço

Todos os tamanhos da `m7i` que o catálogo do moto conhece, do menor para o maior:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --filters "Name=instance-type,Values=m7i.*" --query "sort_by(InstanceTypes,&VCpuInfo.DefaultVCpus)[].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB,NetworkInfo.NetworkPerformance]" --output table
-----------------------------------------------------------
|                  DescribeInstanceTypes                  |
+-----------------+------+---------+----------------------+
|  m7i.large      |  2   |  8192   |  Up to 12.5 Gigabit  |
|  m7i.xlarge     |  4   |  16384  |  Up to 12.5 Gigabit  |
|  m7i.2xlarge    |  8   |  32768  |  Up to 12.5 Gigabit  |
|  m7i.4xlarge    |  16  |  65536  |  Up to 12.5 Gigabit  |
|  m7i.8xlarge    |  32  |  131072 |  12.5 Gigabit        |
|  m7i.12xlarge   |  48  |  196608 |  18.75 Gigabit       |
|  m7i.16xlarge   |  64  |  262144 |  25 Gigabit          |
|  m7i.24xlarge   |  96  |  393216 |  37.5 Gigabit        |
|  m7i.metal-24xl |  96  |  393216 |  37.5 Gigabit        |
|  m7i.48xlarge   |  192 |  786432 |  50 Gigabit          |
|  m7i.metal-48xl |  192 |  786432 |  50 Gigabit          |
+-----------------+------+---------+----------------------+
```

A proporção fica em 4 GiB por vCPU da `large` à `48xlarge`. Os dois tamanhos `metal` têm as vCPU e a
memória do tamanho ao lado porque são o mesmo host, entregue inteiro. Não há hipervisor nem outro
cliente nele, que é do que precisa um software que tem de ver o próprio hardware, como um
hipervisor seu.

A tabela de preços de 16 de outubro de 2026 tem três desses tamanhos, e eles dobram exatamente:
`m7i.large` 0,16065 USD por hora, `m7i.xlarge` 0,3213, `m7i.2xlarge` 0,6426. Num mês de 730 horas
isso dá 117,27, 234,55 e 469,10 USD. **Duas `large` custam exatamente o que custa uma `xlarge`**,
então a escolha entre elas não é sobre dinheiro. Uma máquina maior roda uma cópia do programa com
mais espaço; duas menores sobrevivem à perda de qualquer uma, e deixam um grupo crescer e encolher em
passos menores. A lição 4 é onde essa segunda propriedade começa a render.

## O que o tamanho muda de fato: a rede

A última coluna acima diz "Up to 12.5 Gigabit" para os quatro menores tamanhos e um número simples a
partir da `8xlarge`. **"Up to" é um pico, e a linha de base é bem mais baixa**:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types m7i.large m7i.xlarge m7i.4xlarge m7i.8xlarge --query "InstanceTypes[].[InstanceType,NetworkInfo.NetworkCards[0].BaselineBandwidthInGbps,NetworkInfo.NetworkCards[0].PeakBandwidthInGbps]" --output table
----------------------------------
|      DescribeInstanceTypes     |
+--------------+---------+-------+
|  m7i.4xlarge |  6.25   |  12.5 |
|  m7i.8xlarge |  12.5   |  12.5 |
|  m7i.large   |  0.781  |  12.5 |
|  m7i.xlarge  |  1.562  |  12.5 |
+--------------+---------+-------+
```

A `m7i.large` tem garantidos 0,781 gigabit por segundo e pode subir a 12,5 por um tempo, num sistema
de créditos próprio que a AWS não publica em detalhe. A linha de base dobra com o tamanho, como todo
o resto, até encontrar o pico na `8xlarge`. Um serviço que transmite arquivos, ou move muitos dados
para um banco, pode ser segurado pela rede num tamanho pequeno muito antes de o processador ficar
ocupado. Esse é um motivo para subir de tamanho, e nenhum gráfico de CPU vai mostrá-lo. A banda do
EBS segue o mesmo padrão, e a lição 3 volta a ela.

## Graviton, cerca de um quinto mais barato

Os tipos `g` custam menos que os equivalentes Intel de mesma forma. Da mesma tabela, por hora:

| forma | Intel | Graviton | diferença |
|---|---|---|---|
| 2 vCPU, 8 GiB | `m7i.large` 0,16065 | `m7g.large` 0,1301 | 19,0% |
| 2 vCPU, 4 GiB | `c7i.large` 0,13755 | `c7g.large` 0,1111 | 19,2% |
| 2 vCPU, 16 GiB | `r7i.large` 0,21105 | `r7g.large` 0,1704 | 19,3% |

Para uma `m7g.large` isso dá 94,97 USD por mês em vez de 117,27, 22,30 economizados por instância
antes de qualquer diferença de velocidade. Lembre da seção sobre nomes que as duas vCPU do Graviton
são dois núcleos, onde as da Intel são um. **A economia só é real se o software roda em Arm**, e
essa é a pergunta a responder primeiro; uma imagem `x86_64` não vai respondê-la por você.

## A família burstable

Os tipos `t` (`t3` na Intel, `t3a` na AMD, `t4g` no Graviton) não vendem a vCPU inteira. Vendem uma
**linha de base**: uma fatia de cada vCPU que a instância pode usar o tempo todo, e **créditos de
CPU** que pagam o que passar disso. Um crédito é uma vCPU a 100% por um minuto. Abaixo da linha de
base a instância ganha créditos; acima, gasta. A AWS documenta os números por tamanho, e dois deles
estão na tabela:

| tipo | vCPU | linha de base por vCPU | créditos ganhos por hora | máximo que guarda | preço por hora |
|---|---|---|---|---|---|
| `t3.micro` | 2 | 10% | 12 | 288 | 0,0168 |
| `t3.medium` | 2 | 20% | 24 | 576 | 0,0672 |

Os créditos por hora são a linha de base em minutos: 20% de duas vCPU por sessenta minutos dá 24. O
máximo que ela guarda é o ganho de um dia. Então uma `t3.medium` que roda as duas vCPU a 50% gasta 60
créditos por hora e ganha 24, perdendo 36; a partir de um saldo cheio de 576, ela tem 16 horas antes
de os créditos acabarem.

O que acontece depois depende do **modo de crédito**. No modo `standard` a instância é presa à linha
de base, e um serviço que estava ocupado a 50% precisa caber em 20%. No modo `unlimited` ela segue
rodando a toda velocidade, e o excedente é cobrado por vCPU-hora, a uma taxa que a AWS publica e a
tabela não traz. A AWS lança `t3`, `t3a` e `t4g` no modo `unlimited`, a não ser que o pedido diga
outra coisa.

Esta é a parte que o moto não modela. Ele tem o indicador que diz que um tipo é burstable, e nada
por trás:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types t3.micro t3.medium t4g.medium m7i.large --query "InstanceTypes[].[InstanceType,BurstablePerformanceSupported]" --output text
m7i.large	False
t3.medium	True
t3.micro	True
t4g.medium	True
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type t3.medium --credit-specification CpuCredits=unlimited --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 describe-instance-credit-specifications --instance-ids "$ID"
{
    "InstanceCreditSpecifications": [
        {
            "InstanceId": "i-e9e4d8eb7983437bb",
            "CpuCredits": "standard"
        }
    ]
}
ana@laptop:~/aws$ aws ec2 modify-instance-credit-specification --instance-credit-specifications "InstanceId=$ID,CpuCredits=unlimited"

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

A instância foi lançada com `CpuCredits=unlimited`, e o moto a informa como `standard`; quando pedem
para trocar o modo, ele falha com um erro dele mesmo, não da AWS. O moto não roda processador
nenhum, então não ganha nem gasta créditos, e a métrica `CPUCreditBalance` que a AWS publica para
toda instância burstable não existe aqui. **O que esta seção diz sobre créditos veio da documentação
da AWS e não foi executado.**

## Burstable ou fixa

A `t3.medium` tem 2 vCPU e 4 GiB por 0,0672 USD por hora; a `c7i.large` tem as mesmas duas vCPU e
4 GiB por 0,13755. A máquina burstable custa menos da metade porque não está prometendo o processador
o dia todo. **Para uma máquina que fica ociosa, é uma pechincha**: um servidor de staging, um bastion,
uma ferramenta interna pequena, qualquer coisa com média abaixo da linha de base. Um serviço que fica
acima de 20% o expediente inteiro é estrangulado no modo `standard` ou cobra excedente em silêncio
no `unlimited`. Um tipo fixo teria sido mais rápido, pelo mesmo dinheiro ou menos. O teste é a média de CPU de uma semana contra a linha de base da tabela, que, de novo, vem do
CloudWatch.
