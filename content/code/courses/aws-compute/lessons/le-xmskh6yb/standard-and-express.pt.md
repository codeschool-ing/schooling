---
title: Standard e Express
version: 1
---

Uma máquina de estados tem um tipo, escolhido quando ela é criada e nunca mudado depois. Os dois
tipos leem a mesma Amazon States Language, o que os faz parecer um produto só com um ajuste de
velocidade. **São dois motores com promessas diferentes**: um workflow Standard é um registro
durável de uma execução que pode durar um ano, e um workflow Express é uma execução rápida e
barata de no máximo cinco minutos de que o serviço não se lembra. Escolher entre eles é escolher
qual promessa o trabalho precisa.

## O que cada um promete

| | Standard | Express |
|---|---|---|
| execução mais longa | um ano | cinco minutos |
| quantas vezes uma execução acontece | exatamente uma | pelo menos uma (iniciada de forma assíncrona) ou no máximo uma (de forma síncrona) |
| histórico | guardado pelo serviço, legível por 90 dias depois da execução | nenhum no serviço; vai para o CloudWatch Logs se você ligar o log |
| `.waitForTaskToken` e `.sync` | sim | não |
| cobrado por | transição de estado | requisição, e duração por memória |

**"Exatamente uma" é sobre o workflow, não sobre a sua tarefa.** Uma execução Standard nunca roda o
mesmo estado duas vezes por acidente; um `Retry` que você escreveu o roda de novo de propósito, e a
próxima seção trata do que isso significa para a tarefa. Uma execução Express assíncrona pode rodar
duas vezes para um único início, então todo passo nela precisa ser seguro de repetir. A linha do
histórico é a que as pessoas encontram primeiro: as chamadas `get-execution-history` da seção
anterior não têm equivalente no Express, e uma execução Express que falhou e não foi registrada
não deixa nada para ler.

## O moto mantém um motor só

O moto aceita o tipo e o esquece:

```
ana@laptop:~/aws$ aws stepfunctions create-state-machine --name orders-fast --type EXPRESS --definition file://split.asl.json --role-arn "$ROLE" --query stateMachineArn --output text
arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast
ana@laptop:~/aws$ aws stepfunctions describe-state-machine --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast --query type
"STANDARD"
ana@laptop:~/aws$ aws stepfunctions start-sync-execution --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast --input '{"lines": []}'

aws: [ERROR]: Could not connect to the endpoint URL: "http://sync-localhost:4567/"
```

**Na AWS, o `describe-state-machine` responde `EXPRESS` aqui.** O moto roda toda máquina de estados
com o seu único interpretador, que se comporta como um workflow Standard: histórico, durações de
qualquer tamanho, task tokens. Então no laboratório uma máquina Express espera uma hora sem
reclamar, o que a AWS pararia em cinco minutos. O `start-sync-execution` que falhou é coisa da
linha de comando: ela manda um início síncrono para um host cujo nome começa com `sync-`, que na
AWS é `sync-states.sa-east-1.amazonaws.com` e aqui não existe. Uma execução Express síncrona devolve
a saída na mesma chamada, e é assim que uma rota do API Gateway espera um workflow curto numa
requisição só.

## Dois modelos de preço

A tabela imprimiu os dois em 16 de outubro de 2026:

```
ana@laptop:~/aws$ python3 prices.py integration | sed -n 9,12p
Step Functions
  Standard, state transitions                       37.5  per million
  Express, requests                                    1  per million
  Express, duration (first tier)              0.00001667  per GB-second
```

Uma **transição de estado** é contada toda vez que uma execução entra num estado, inclusive a cada
nova tentativa. O workflow de pedidos da Ana em produção tem dez passos, e a loja atende um milhão
de pedidos por mês. Como workflows Standard isso dá 1.000.000 × 10 = 10.000.000 de transições, ou
seja, 10 × 37,5 = 375,00 USD por mês. As 4.000 transições por mês que a AWS dá de graça ficam fora
da conta; elas não fariam diferença visível.

Como workflows Express, cada pedido é uma requisição e uma duração. **O Express cobra memória em
degraus de 64 MB e tempo arredondado para cima até os próximos 100 ms**, e um workflow que só chama
serviços não precisa de mais que o menor degrau. A 2 segundos cada, um milhão de execuções são
1.000.000 × 2 s × 0,0625 GB = 125.000 GB-segundos, ou seja, 125.000 × 0,00001667 = 2,08 USD de
duração mais 1 × 1 = 1,00 USD de requisições: 3,08 USD por mês. A primeira faixa de duração da AWS
cobre os primeiros 1.000 GB-horas de um mês, e 125.000 GB-segundos são cerca de 35, então o preço
da tabela vale para tudo.

**375 contra 3,08 é um fator de umas 120 vezes, e não é a decisão inteira.** O preço do Express
compra cinco minutos, nenhum histórico e execuções que podem se repetir. Se um passo do workflow
de pedidos cobra um cartão, uma execução que se repete cobra duas vezes, a menos que esse passo
seja idempotente. Se algum passo espera uma pessoa, o depósito ou uma janela de cancelamento de
trinta minutos, a execução passa dos cinco minutos e o Express não consegue segurá-la.

## Qual, então

**Standard para o longo e o importante; Express para o curto e o numeroso.** Um pedido que espera
um depósito, um reembolso que precisa de aprovação, um job noturno que roda por uma hora: Standard,
e o preço por transição é pequeno perto do que cada execução vale. Transformar cada imagem que
chega ao S3 em três miniaturas, ou validar e rotear cem mil eventos por minuto: Express, onde o
preço por transição dominaria e cada execução é barata de repetir.

Um desenho comum usa os dois: um workflow Standard para o pedido como um todo, e um workflow
Express iniciado de dentro dele para uma rajada de passos curtos, para que o medidor caro conte uma
transição pela rajada em vez de centenas.
