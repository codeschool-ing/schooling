---
title: Costuras portáveis
version: 1
---

Uma **costura** é um ponto em que o seu sistema encontra o provedor por uma interface que outra
pessoa também implementa. Código que toca o Google só nas costuras pode ser levado embora
reconstruindo o outro lado de cada costura; código que toca o Google em todo lugar precisa ser
reescrito. **Projetar para portabilidade não quer dizer evitar os serviços do Google. Quer dizer
escolher onde ficam as costuras, e manter o código do seu lado delas.**

## As costuras que este curso já usa

**A imagem de contêiner.** Uma imagem OCI feita para o Cloud Run roda sem mudança no GKE, em
qualquer outro Kubernetes, numa máquina com Docker e no serviço de contêineres de todo outro
provedor. O contrato que o Cloud Run pede (escutar em `$PORT`, não guardar estado, sair no
`SIGTERM`, lição 8) é um contrato que qualquer um deles consegue cumprir. É a costura mais forte da
lista, e o motivo de a lição 22 pôr os serviços da loja em contêineres.

**A API do Knative.** A descrição de um serviço do Cloud Run segue o formato do Knative Serving:
`gcloud run services describe orders --format export` imprime um documento com
`apiVersion: serving.knative.dev/v1`, e o mesmo documento, sem as anotações do Google, pode ser
publicado em qualquer cluster Kubernetes que rode o Knative. Esse comando não é executado aqui,
porque precisa de conta; o formato está na referência do Cloud Run do Google.

**O Functions Framework.** Uma função do Cloud Run é uma função Python com um decorador, e o
decorador vem de uma biblioteca de código aberto. Eis a menor que a loja poderia usar, salva como
`~/gcp/seam/main.py`:

```python
# seam/main.py
import functions_framework


@functions_framework.http
def status(request):
    return {'service': 'orders', 'status': 'ok'}
```

Inicie num terminal próprio, a partir de `~/gcp/seam`, com
`functions-framework --target=status --port=8080`, e pergunte a ela do seu terminal de trabalho:

```
ana@laptop:~/gcp/seam$ curl -s localhost:8080/
{"service":"orders","status":"ok"}
ana@laptop:~/gcp/seam$ curl -s -i localhost:8080/ | head -4
HTTP/1.1 200 OK
Server: gunicorn
Date: Fri, 30 Oct 2026 18:16:20 GMT
Connection: keep-alive
```

**Esse é o mesmo programa que o Google rodaria**, servido pelo mesmo framework, num laptop sem conta
e sem rede. O cabeçalho `Server` diz o que está por baixo: o gunicorn, um servidor web Python comum,
com o framework como uma camada fina por cima. A lição 17 constrói funções de verdade assim. O que
faz disso uma costura é que nada no `main.py` diz Google: o framework é o adaptador, e roda onde o
Python rodar.

**CloudEvents.** Os eventos que o Eventarc entrega (lição 18) são CloudEvents, uma especificação da
CNCF com bibliotecas em toda linguagem importante. Um handler escrito para o formato CloudEvents lê
o mesmo envelope vindo do roteador de eventos de outro provedor. O que muda é o conteúdo: um evento
sobre um objeto do Cloud Storage traz os campos do Cloud Storage.

## Onde não há costura

Alguns serviços não têm outra implementação, e o movimento honesto é admitir isso e contê-lo.
**Ponha toda chamada ao Pub/Sub, ao Firestore ou ao Cloud Tasks atrás de um módulo pequeno seu**,
com o nome do que a loja precisa ("publicar um evento de pedido", "enfileirar uma miniatura") em vez
do nome da API do Google. Sair então quer dizer reescrever esse módulo, não caçar pelo código todo.

O que o módulo não deve virar é um framework que esconde todo provedor atrás do mínimo denominador
comum. Isso custa os recursos pelos quais você escolheu o Google e ainda deixa os dados para trás. O
módulo é uma lista dos lugares em que a loja toca o Google, mantida curta de propósito.

**O Terraform é uma costura de fluxo de trabalho, não de recursos.** O hábito de descrever a
infraestrutura como código vai junto com a equipe; os recursos não. Um bloco
`google_cloud_run_v2_service` não tem equivalente fora do Google, e reescrever a configuração faz
parte do que custa sair.
