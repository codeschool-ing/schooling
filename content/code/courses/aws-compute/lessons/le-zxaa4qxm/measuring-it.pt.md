---
title: Medindo, com um import que custa alguma coisa
version: 1
---

O cold start do handler vazio foi o runtime e mais nada. Uma função de verdade importa bibliotecas e
constrói clientes, e **a coisa pesada mais comum no topo de uma função Python é o SDK da AWS**: o
`boto3`, que o runtime Python já traz, então uma função pode importá-lo sem empacotá-lo. Construir um
cliente carrega do disco a descrição da API do serviço e monta o código que assina as requisições, e
tudo isso acontece antes de a primeira chamada ser feita.

Duas versões da mesma função tornam a diferença visível. As duas devolvem o nome da classe de um
cliente S3, o que basta para provar que o cliente existe; nenhuma das duas fala com o S3, então nada
aqui precisa de rede nem de conta.

A primeira constrói o cliente no topo do arquivo, na fase init. Salve-a como `~/aws/eager/app.py`:

```python
# eager/app.py
import boto3

s3 = boto3.client("s3", region_name="sa-east-1")


def handler(event, context):
    return {"client": type(s3).__name__}
```

A segunda o constrói dentro do handler, a cada chamada. Salve-a como `~/aws/lazy/app.py`:

```python
# lazy/app.py
def handler(event, context):
    import boto3
    s3 = boto3.client("s3", region_name="sa-east-1")
    return {"client": type(s3).__name__}
```

## Uma função para medir

Três chamadas a um emulador recém-iniciado são uma requisição fria e duas quentes, e a função de
shell abaixo faz exatamente isso para o diretório que você indicar, e depois imprime as linhas do log
que trazem os tempos. Cole-a no terminal; ela dura até o terminal fechar.

```schooling-example
{"language": "sh", "file": "cold.sh", "parts": [{"code": "cold() {\n  docker run -d --name \"$1\" -p 9000:8080 ${2:+--cpus \"$2\"} \\\n    -v \"$PWD/$1\":/var/task:ro public.ecr.aws/lambda/python:3.12 app.handler > /dev/null\n  sleep 2\n", "note": "Um contêiner novo com o nome do diretório, e esse diretório como código da função, então toda execução começa fria. `${2:+--cpus \"$2\"}` só acrescenta um limite de CPU quando um segundo argumento é dado. A pausa dá tempo para o emulador começar a escutar."}, {"code": "  for n in 1 2 3; do\n    curl -s -o /dev/null -w \"call $n: %{time_total} s\\n\" \\\n      -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{}'\n  done\n", "note": "Três chamadas, uma depois da outra: a primeira é fria e as outras duas são quentes. O `curl` joga a resposta fora e imprime quanto tempo cada chamada levou, do ponto de vista de quem chamou."}, {"code": "  docker logs \"$1\" 2>&1 | grep -E 'INIT REPORT|^REPORT'\n  docker rm -f \"$1\" > /dev/null\n}\n", "note": "O log do emulador, filtrado para a linha que mede a fase init e as três linhas `REPORT`. Depois o contêiner é removido, o que libera o nome e a porta para a próxima execução."}]}
```

O `cold` recebe o diretório como primeiro argumento, e um segundo opcional que a última parte desta
seção usa.

## Eager contra lazy

```
ana@laptop:~/aws$ cold eager
call 1: 0.312086 s
call 2: 0.001804 s
call 3: 0.011283 s
16 Oct 2026 16:34:40,324 [INFO] (rapid) INIT REPORT(durationMs: 300.635000)
REPORT RequestId: 554deedb-dfef-4058-bc01-3f5c73ce7ff5	Init Duration: 0.06 ms	Duration: 306.68 ms	Billed Duration: 307 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: f62651b8-64eb-42f2-9e55-36bae95c9420	Duration: 0.93 ms	Billed Duration: 1 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 1ccb0edb-b9be-4733-ac64-ae46dba46816	Duration: 3.07 ms	Billed Duration: 4 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
ana@laptop:~/aws$ cold lazy
call 1: 0.343093 s
call 2: 0.009389 s
call 3: 0.007566 s
16 Oct 2026 16:34:43,196 [INFO] (rapid) INIT REPORT(durationMs: 67.552000)
REPORT RequestId: 207b5daf-893f-488c-98ca-1d19bcb80f54	Init Duration: 3.61 ms	Duration: 328.33 ms	Billed Duration: 329 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 5a5146b3-4f21-4f05-bfb7-851ce7665dd8	Duration: 8.07 ms	Billed Duration: 9 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 6a305a31-645e-4421-ba97-8c2c1d72392e	Duration: 6.70 ms	Billed Duration: 7 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

Ponha os números lado a lado, lendo a fase init no `INIT REPORT` e cada requisição no `curl`, como a
seção anterior disse:

| | fase init | primeira chamada | segunda chamada | terceira chamada |
|---|---|---|---|---|
| `eager` | 301 ms | 0,312086 s | 0,001804 s | 0,011283 s |
| `lazy` | 68 ms | 0,343093 s | 0,009389 s | 0,007566 s |

Há três coisas nessa tabela.

**O cliente é a parte cara, e é pago uma vez.** O `eager` passa 301 ms na fase init
contra 48 ms do handler vazio da seção anterior, e a diferença é o `import boto3` e um
cliente. As chamadas quentes dele são então questão de milissegundos, porque o cliente já existe.

**Levar o trabalho para dentro do handler não o elimina.** O `lazy` tem uma fase init curta, mais ou
menos a do runtime vazio, e a primeira chamada paga quase tudo no lugar dela: a requisição fria é
quase tão lenta num caso quanto no outro, porque o mesmo import aconteceu, só que depois. E olhe o
`Duration` das requisições quentes dele no `REPORT`: 8,07 e 6,70 ms, contra
0,93 e 3,07 do `eager`. O Python guarda um módulo importado, então o segundo
`import boto3` sai de graça, mas o cliente é construído de novo a cada chamada. **O trabalho
preguiçoso é pago de novo em toda requisição quente, e as requisições quentes são quase todas.**

**O `Init Duration` do emulador não diz nem uma coisa nem outra.** O primeiro `REPORT` do `eager` dá
uma fração de milissegundo como `Init Duration` e põe a fase init dentro do `Duration`. Na AWS o
primeiro traria o número de verdade, e o segundo só o tempo do próprio handler.

A regra que sai daí é a que a documentação da AWS enuncia e que toda medição aqui confirma: **faça
uma vez, fora do handler, o que toda requisição precisa**, para que o custo seja pago no init e
reaproveitado por cada requisição quente naquele ambiente. Um cliente, um pool de conexões, uma
configuração lida de um arquivo. A inicialização preguiçosa dentro do handler tem um uso legítimo:
uma dependência de que só algumas requisições precisam, construída no primeiro uso e guardada numa
global para a próxima.

## A fase init é feita de CPU

Construir um cliente é computação, e computação roda na velocidade da CPU que o ambiente recebe.
**No Lambda essa CPU é proporcional à memória que você configura**: a AWS documenta uma vCPU
inteira em 1.769 MB, e uma função de 128 MB recebe uma pequena fração de uma. O emulador ignora a
configuração de memória, mas o Docker consegue limitar a CPU que um contêiner recebe, e é o mais
perto que um laptop chega. Isto é uma analogia, rodada com o `--cpus` do Docker, e não a alocação do
próprio Lambda:

```
ana@laptop:~/aws$ cold eager 1
call 1: 0.346706 s
call 2: 0.002653 s
call 3: 0.004523 s
16 Oct 2026 16:34:46,967 [INFO] (rapid) INIT REPORT(durationMs: 342.851000)
REPORT RequestId: 603cba49-8cd3-46fa-81ad-55c5dcae865b	Init Duration: 0.07 ms	Duration: 345.24 ms	Billed Duration: 346 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 74fcd1d6-fd1b-4a34-889b-dcd295e85762	Duration: 1.78 ms	Billed Duration: 2 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 06e66ea3-5556-4a73-a523-2c336f372471	Duration: 3.76 ms	Billed Duration: 4 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
ana@laptop:~/aws$ cold eager 0.5
call 1: 0.643410 s
call 2: 0.006040 s
call 3: 0.016945 s
16 Oct 2026 16:34:50,272 [INFO] (rapid) INIT REPORT(durationMs: 610.819000)
REPORT RequestId: 80221845-6ca6-4bbd-ba6e-91e61977ff92	Init Duration: 0.06 ms	Duration: 618.45 ms	Billed Duration: 619 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 63e70195-480d-4d0d-8537-6525b06cacdf	Duration: 5.16 ms	Billed Duration: 6 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 153eaefb-992b-4580-afe7-bd2c0c8763f0	Duration: 3.54 ms	Billed Duration: 4 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
ana@laptop:~/aws$ cold eager 0.25
call 1: 1.362279 s
call 2: 0.033606 s
call 3: 0.008431 s
16 Oct 2026 16:34:54,569 [INFO] (rapid) INIT REPORT(durationMs: 1336.616000)
REPORT RequestId: d40b5567-fd82-46de-b8f8-c258fa3a5ec2	Init Duration: 0.10 ms	Duration: 1343.82 ms	Billed Duration: 1344 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 1b5d41cc-fd79-4415-8db1-08ca167a9bb4	Duration: 6.26 ms	Billed Duration: 7 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
REPORT RequestId: 3914e56c-f183-4093-8a47-453e46229d31	Duration: 1.00 ms	Billed Duration: 1 ms	Memory Size: 3008 MB	Max Memory Used: 3008 MB	
```

O mesmo módulo `eager`, a mesma máquina. Com uma CPU inteira a fase init leva 343 ms, com
meia 611 ms, e com um quarto 1337 ms. Os tempos num laptop compartilhado
variam dezenas de milissegundos de uma execução para outra.
Leia a tendência e não o último
dígito: **uma fase init que é sobretudo computação fica mais lenta na proporção em que a CPU
encolhe.** No Lambda, a configuração de memória é portanto também uma configuração de cold start, e
a próxima seção pesa o que aumentá-la custa.
