---
title: Entrega, repetições e a duplicata que você vai receber
version: 1
---

A suposição confortável é que um evento chega uma vez. **O Eventarc e o Pub/Sub prometem o
contrário: pelo menos uma vez.** Um evento é entregue até o destino confirmar, e uma entrega pode
chegar duas vezes mesmo sem falha nenhuma, porque uma confirmação pode se perder no caminho de
volta. Código que reage a eventos é escrito desde o início para a segunda chegada.

## Vendo uma repetição acontecer

A lição 17 disse que uma exceção quer dizer falha e que falha quer dizer entrega de
novo. Eis como é esse "de novo" quando nada o freia. **Salve isto como `~/gcp/flaky/main.py`**, uma
função que falha toda vez, como falha uma cujo banco de dados caiu:

```python
# flaky/main.py
import functions_framework


@functions_framework.cloud_event
def flaky(event):
    print(f"delivery of message {event['id']}", flush=True)
    raise RuntimeError('database unavailable')
```

Inicie-a no segundo terminal, desta vez com a saída indo para um arquivo, porque você vai contar
linhas nele:

```
ana@laptop:~/gcp/flaky$ functions-framework --target flaky --signature-type cloudevent > ~/gcp/flaky.log 2>&1
```

Depois, no primeiro terminal, inicie o emulador de Pub/Sub como na lição 17 e empurre uma mensagem
para a função:

```
ana@laptop:~/gcp$ docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev
b2fc243cd6c56d662906eb384ef27f0ddcc2162ad519e14031b3f92dc280ce0b
ana@laptop:~/gcp$ python3 pubsub.py topic orders
projects/planner-dev/topics/orders
ana@laptop:~/gcp$ python3 pubsub.py push flaky orders http://localhost:8080/
projects/planner-dev/subscriptions/flaky -> http://localhost:8080/
ana@laptop:~/gcp$ python3 pubsub.py publish orders 1042
message 1
```

Espere dez segundos e conte as entregas. Cada uma escreveu a sua linha, depois o erro do framework
e um traceback:

```
ana@laptop:~/gcp$ grep -c 'delivery of message 1' flaky.log
10
ana@laptop:~/gcp$ grep -m 3 -A 1 'delivery of message 1' flaky.log
delivery of message 1
[2026-10-30 15:25:47,569] ERROR in app: Exception on / [POST]
--
delivery of message 1
[2026-10-30 15:25:48,590] ERROR in app: Exception on / [POST]
--
delivery of message 1
[2026-10-30 15:25:49,598] ERROR in app: Exception on / [POST]
```

**Uma mensagem, entregue de novo mais ou menos a cada segundo**, enquanto a função continuar
falhando. O emulador repete praticamente sem intervalo, o que torna o problema visível num laptop.
O Google Cloud é mais gentil e o problema é o mesmo: com uma política de repetição na assinatura, o
Pub/Sub espera entre 10 segundos e 10 minutos entre tentativas, aumentando a espera a cada vez, e
continua tentando até a mensagem expirar. As assinaturas do Eventarc guardam uma mensagem por 24
horas, então uma função quebrada por um dia vê o mesmo evento mais de cem vezes.

Pare tudo com `docker rm -f pubsub` e Ctrl+C no terminal da função.

## Três defesas

**Torne o trabalho idempotente.** Processar o mesmo evento duas vezes precisa deixar o mundo como
processá-lo uma vez deixou. O `id` do CloudEvent é único por origem, então a proteção mais simples é
uma tabela de ids já tratados, consultada e gravada na mesma transação que o trabalho. Fazer uma
miniatura é idempotente por natureza, já que gravar o mesmo arquivo duas vezes dá o mesmo arquivo.
Mandar um e-mail não é, e um cliente que recebe quatro confirmações do pedido sabe exatamente que
tipo de código você escreveu.

**Separe as falhas que vale repetir das que não vale.** Um banco fora do ar vale a repetição; um
evento com dados malformados vai estar malformado na milésima tentativa também. Para o segundo
tipo, registre no log, volte normalmente e deixe passar: lançar a exceção só compraria um dia de
falhas idênticas.

**Dê um destino ao veneno.** Uma assinatura do Pub/Sub pode ter um **tópico de mensagens mortas**
e um número máximo de tentativas de entrega, entre 5 e 100. Depois da última tentativa a mensagem
vai para esse tópico em vez de ser repetida, e alguma coisa, ou alguém, olha para ela lá. Para um
gatilho do Eventarc isso se configura na assinatura que o Eventarc criou, e a documentação do Google
mostra como encontrá-la.

## Repetições nas funções que você publica

Numa função publicada com gatilho de evento, a repetição vem **desligada**: um evento que falha é
descartado depois de uma tentativa. Ligá-la é uma escolha por função, com `--retry` no `gcloud
functions deploy` ou `retry_policy = "RETRY_POLICY_RETRY"` no Terraform, e é a escolha certa
exatamente quando as três defesas acima estão no lugar. Desligada, uma falha se perde em silêncio.
Ligada, sem idempotência, uma falha se repete em voz alta. Nenhuma das duas é segura sozinha.
