---
title: O que reduz, começando pelo que é de graça
version: 1
---

Os remédios para um cold start costumam ser listados com os pagos primeiro, porque são produtos com
nome. **A maioria dos cold starts encurta de forma mais barata mudando o que o módulo faz no
import**, e a ordem abaixo vai do que não custa nada ao que é cobrado por segundo, que é a ordem em
que vale tentá-los.

## Descubra para onde vai o tempo

Antes de tirar qualquer coisa, meça do que o import é feito. O Python sabe cronometrar cada import
que faz, com `-X importtime`, e a imagem do Lambda tem o mesmo interpretador e o mesmo `boto3` com
que a função roda. A última coluna é o módulo, recuado pela profundidade.
A do meio é o tempo
total em microssegundos, incluindo tudo o que aquele módulo importou por sua vez:

```
ana@laptop:~/aws$ docker run --rm --entrypoint python3 public.ecr.aws/lambda/python:3.12 -X importtime -c 'import boto3' 2>&1 | sort -t'|' -k2 -n | tail -5
import time:       248 |     123203 |         botocore.waiter
import time:       784 |     154090 |       botocore.client
import time:       821 |     160525 |     botocore.session
import time:       578 |     166905 |   boto3.session
import time:       399 |     221273 | boto3
```

**Só o `import boto3` leva 221.273 microssegundos, cerca de 221 ms**, e a
maior parte é o `botocore`, a camada de baixo que conhece todas as APIs da AWS. O resto dos
301 ms que o `eager` gastou na seção anterior foi a construção do cliente. O mesmo
comando sobre o seu próprio módulo, rodado dentro da imagem, aponta o import que é lento, que quase
sempre é um que ninguém sabia que estava ali.

## Importe menos, e importe uma vez

Três mudanças não custam nada além de cuidado.

- **Importe o que a função usa.** Um módulo que importa um framework inteiro para chamar um helper
  paga pelo framework em todo cold start. O mesmo vale para uma biblioteca de dados importada "por
  via das dúvidas".
- **Construa clientes e conexões no topo do arquivo**, como a seção anterior mediu: pagos uma vez na
  fase init, reaproveitados por toda requisição quente.
- **Mantenha o pacote pequeno.** Na AWS o código é buscado durante a fase init, então os megabytes
  que a função nunca importa ainda precisam chegar. O emulador monta o código a partir do seu disco
  e não consegue mostrar essa parte; é o comportamento documentado da AWS, e não foi executado aqui.

Esse último ponto tem uma escolha dentro dele, visível na própria imagem:

```
ana@laptop:~/aws$ docker run --rm --entrypoint python3 public.ecr.aws/lambda/python:3.12 -c 'import boto3; print(boto3.__version__)'
1.35.92
ana@laptop:~/aws$ docker run --rm --entrypoint du public.ecr.aws/lambda/python:3.12 -sh /var/lang/lib/python3.12/site-packages/boto3 /var/lang/lib/python3.12/site-packages/botocore
1.6M	/var/lang/lib/python3.12/site-packages/boto3
27M	/var/lang/lib/python3.12/site-packages/botocore
```

O runtime traz o `boto3` 1.35.92, e o `botocore` embaixo dele ocupa
27 MB em disco. Uma função que depende dele não carrega nada a mais. Mesmo assim, o
conselho da própria AWS é empacotar a versão do SDK com que você testou, porque a cópia do runtime é
atualizada pela AWS no calendário dela, e uma função cujo comportamento muda quando outra pessoa
atualiza uma biblioteca é uma função que ninguém consegue reproduzir. **Empacotar o SDK compra uma
versão fixa ao preço de cerca de 27 MB a mais para baixar em todo cold start**; qual
dos dois pesa mais é uma decisão sobre a função, não uma regra.

## Memória, que também é CPU

A seção anterior mostrou o init ficando mais lento conforme a CPU encolhia, e no Lambda a CPU vem
com a configuração de memória. Aumentar a memória então encurta um cold start limitado por CPU, e
**isso não custa necessariamente mais, porque o preço é por gigabyte-segundo.** O preço sob demanda
da tabela para x86 em sa-east-1 é 0,0000166667 USD por GB-segundo, então uma requisição de 800 ms a
512 MB usa 0,5 × 0,8 = 0,4 GB-segundo, e a mesma requisição a 1.024 MB, se a CPU a mais a reduzir
pela metade, para 400 ms, usa 1 × 0,4 = 0,4 GB-segundo: os mesmos 0,0000066667 USD. Isso só vale
enquanto o trabalho acelera na mesma proporção. Uma função que passa o tempo esperando um banco de
dados não ganha nada com mais CPU e paga o dobro por segundo.

**Arm** é a outra linha da tabela: 0,0000133334 USD por GB-segundo no Graviton contra 0,0000166667
no x86, um quinto a menos por cada segundo de init e de handler. A AWS não promete um cold start mais
rápido em Arm, e nada aqui consegue medir um, porque o laptop e a imagem são x86; uma biblioteca com
partes compiladas também precisa da build para Arm. A lição 14 define a arquitetura e a lição 23
pesa o preço.

## O que sobra

Bem feitas, as mudanças gratuitas trazem um cold start Python para perto do próprio runtime, os
48 ms do handler vazio neste laptop mais o que a AWS acrescenta para posicionar o
ambiente e buscar o código. **Para um consumidor de fila ou um job noturno, a história acaba aí**:
ninguém está esperando a primeira requisição. Para uma API em que uma pessoa está, o cold start que
sobra é o que a próxima seção paga para remover.
