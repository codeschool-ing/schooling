---
title: "Concorrência reservada: um teto e um piso ao mesmo tempo"
version: 1
---

O nome sugere reservar capacidade com antecedência, algo pago e mantido aquecido. **A
concorrência reservada não é nenhuma das duas coisas: não custa nada e não inicia nada.** É uma
linha traçada dentro do pool da conta. Configurá-la em 100 numa função faz duas coisas ao mesmo
tempo, e as duas são o mesmo número visto de dois lados:

- um piso: 100 do pool pertencem àquela função, e nenhuma outra pode usá-los, então uma vizinha
  descontrolada não consegue deixá-la sem nada;
- um teto: a função nunca roda mais de 100 ambientes, e a 101ª requisição simultânea dela sofre
  throttle mesmo quando o resto do pool está parado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"Uma barra de 1.000 execuções simultâneas para uma conta numa região. Da esquerda: 200 reservadas para checkout, 100 reservadas para orders, 600 sem reserva e compartilhadas, e as 100 finais, tracejadas, que a AWS mantém sem reserva. Uma chave sob as primeiras 900 diz que esse é o máximo que pode ser reservado; uma chave sob as últimas 700 diz que essas são compartilhadas por toda função sem reserva.\"><defs><marker id=\"pool-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Uma conta, uma região: 1.000 execuções simultâneas</text><text x=\"60\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"660\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.000</text><rect x=\"60\" y=\"84\" width=\"120\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">checkout</text><text x=\"120\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">200 reservadas</text><rect x=\"180\" y=\"84\" width=\"60\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">orders</text><text x=\"210\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">100</text><rect x=\"240\" y=\"84\" width=\"360\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">compartilhadas</text><text x=\"420\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">600, qualquer função sem reserva</text><rect x=\"600\" y=\"84\" width=\"60\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"630\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">mantidas</text><text x=\"630\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">100</text><path d=\"M60 160 L60 168 L600 168 L600 160\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"330\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">reserváveis, todas as funções juntas: no máximo 900</text><path d=\"M240 206 L240 214 L660 214 L660 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"450\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">sem reserva: 700, contando o piso de 100</text></svg>", "caption": "Reservar divide o pool em vez de aumentá-lo. checkout sempre consegue chegar a 200 e nunca passa disso; orders, o mesmo com 100; todo o resto da conta divide o que sobra, e a AWS recusa qualquer reserva que deixaria menos de 100 sem reserva."}
```

## Dois motivos para reservar, e eles apontam para lados opostos

O primeiro é garantir. A função de checkout precisa responder mesmo no dia em que a função que
redimensiona imagens é inundada por um upload em massa. Reservar 200 para o checkout quer dizer que
a enxurrada pode levar todo o resto e o checkout continua com os seus 200.

O segundo é limitar. A função grava num banco PostgreSQL que aceita 100 conexões, e cada ambiente
segura uma. Sem um teto, um pico inicia 300 ambientes, 200 deles não conseguem conectar, e o banco
passa o pico recusando pessoas. Com uma reserva de 80, o Lambda faz throttle da 81ª requisição antes de ela chegar ao banco.
O throttle então vai para onde a seção anterior disse que ele vai para aquele
gatilho: de volta para quem chamou, para a fila de novas tentativas do Lambda, ou de volta para a
fila do SQS. **Um throttle na função sai mais barato que uma falha no banco**, porque nada ficou
pela metade.

O limite tem um caso extremo que vale conhecer. Uma reserva de 0 faz throttle de toda requisição. Isso
a torna o interruptor que para uma função na hora, sem apagá-la nem mudar o código: durante um
incidente, enquanto um deploy ruim é revertido, ou para parar uma função que está chamando a si
mesma em loop.

## Fazendo isso contra o moto

Uma função precisa de uma role e de um pacote antes de receber qualquer coisa. A role é a que a
lição 9 de `aws-foundations` explica, com uma política de confiança que deixa o serviço Lambda
assumi-la. O pacote é o handler lento da primeira seção desta lição, compactado:

```
ana@laptop:~/aws$ aws iam create-role --role-name orders-role --query Role.Arn --output text --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
arn:aws:iam::123456789012:role/orders-role
ana@laptop:~/aws$ zip -j orders.zip slow/app.py
  adding: app.py (deflated 9%)
ana@laptop:~/aws$ aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --memory-size 1024 --role arn:aws:iam::123456789012:role/orders-role --zip-file fileb://orders.zip --query "{Name: FunctionName, Memory: MemorySize, State: State}"
{
    "Name": "orders",
    "Memory": 1024,
    "State": "Active"
}
```

`1024` megabytes é 1 GB, o que mantém simples a conta da próxima seção. Agora a reserva, e a
leitura dela. O próprio registro da função a traz em `Concurrency`:

```
ana@laptop:~/aws$ aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 100
{
    "ReservedConcurrentExecutions": 100
}
ana@laptop:~/aws$ aws lambda get-function --function-name orders --query Concurrency
{
    "ReservedConcurrentExecutions": 100
}
```

É tudo o que o Lambda guarda: um número na função. Não há capacidade por trás dele, e nada foi
iniciado.

## O piso de todas as outras

A AWS mantém as últimas 100 do pool para as funções sem reserva, para que elas sempre tenham onde
rodar. **Numa conta com os 1.000 padrão, as reservas de todas as funções juntas podem somar no
máximo 900**, e uma reserva que empurraria a parte sem reserva para baixo de 100 é recusada com uma
`InvalidParameterValueException` que cita esse mínimo. O moto não sabe nada do piso nem do pool.
Peça a ele o dobro do pool e ele concorda:

```
ana@laptop:~/aws$ aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 2000
{
    "ReservedConcurrentExecutions": 2000
}
```

Na AWS esse comando falha, e nada muda. É o caso mais claro desta lição do moto respondendo como a
AWS e fazendo valer muito menos: um script que funcionou aqui prova que a chamada está bem formada, e
nada sobre se a AWS aceitaria o número.

O interruptor e o caminho de volta, que remove a reserva e devolve a função ao pool compartilhado.
O `delete-function-concurrency` não imprime nada quando dá certo, e a leitura que vem depois também
não, porque não há mais valor para mostrar:

```
ana@laptop:~/aws$ aws lambda put-function-concurrency --function-name orders --reserved-concurrent-executions 0
{
    "ReservedConcurrentExecutions": 0
}
ana@laptop:~/aws$ aws lambda delete-function-concurrency --function-name orders
ana@laptop:~/aws$ aws lambda get-function-concurrency --function-name orders
```

## O que reservar custa às outras funções

Cada unidade reservada é uma unidade que mais ninguém pode usar, precise a função dela naquele
momento ou não. Reservar 600 para uma função cujo pico é 50 deixa 400 para o resto da conta, e 550
da reserva parados. **Reserve para um pico medido, mais uma margem, e não para um número redondo**;
a lição 8 de `aws-operations` lê esse pico na métrica `ConcurrentExecutions` do CloudWatch, que
existe por função e por conta.

A concorrência reservada decide quantos ambientes uma função pode ter. Ela não diz nada sobre se
algum deles existe antes de uma requisição chegar, e a primeira requisição num ambiente novo ainda
espera ele iniciar. Manter ambientes prontos com antecedência é outra configuração, com outra
conta, e é a próxima seção.
