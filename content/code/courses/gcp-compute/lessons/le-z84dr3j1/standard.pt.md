---
title: O ambiente padrão, e o arquivo que o descreve
version: 1
---

O App Engine é o jeito mais antigo de o Google rodar o seu código, mais antigo que o Compute
Engine, e foi construído sobre uma ideia que o resto do mercado levou anos para alcançar. **Você
entrega o código-fonte e um arquivo que o descreve; o Google faz o build, roda, escala e dá um
endereço.** Não há máquina nem contêiner em nada que você escreve.

## O que você escreve

Dois arquivos para a vitrine da loja, uma página que cumprimenta o cliente e diz qual versão
respondeu. **Crie `~/gcp/storefront` e salve isto como `main.py` dentro dela:**

```python
# storefront/main.py
import os

from flask import Flask

app = Flask(__name__)


@app.get('/')
def home():
    version = os.environ.get('GAE_VERSION', 'local')
    return f'shop storefront, version {version}\n'
```

É uma aplicação Flask comum. `GAE_VERSION` é uma das variáveis que o App Engine define em toda
instância, junto com `GAE_SERVICE` e `GAE_INSTANCE`; no seu laptop ela não existe, e a página diz
isso. Depois a descrição, **salva como `app.yaml` ao lado**:

```yaml
# storefront/app.yaml
runtime: python312
entrypoint: gunicorn -b :$PORT main:app
instance_class: F1
automatic_scaling:
  max_instances: 5
```

Quatro linhas de decisão. **`runtime`** dá a linguagem e a versão para as quais o Google vai fazer
o build. **`entrypoint`** é o comando que inicia o servidor, e o App Engine define `PORT` antes de
rodá-lo, exatamente como o Cloud Run faz. **`instance_class`** é o tamanho de cada instância, e a
seção 03 dá o preço. **`automatic_scaling`** diz quantas podem rodar ao mesmo tempo;
`max_instances` é o teto que impede um pico de virar conta. Um `requirements.txt` com `Flask` e
`gunicorn` completa a pasta; o build do Google instala o que ele lista.

## Rodando do jeito que o App Engine vai rodar

O entrypoint é um comando, então ele roda no seu laptop como está escrito. No segundo terminal, com
`PORT` definida como o App Engine definiria:

```
ana@laptop:~/gcp/storefront$ PORT=8081 gunicorn -b :$PORT main:app
[2026-10-30 15:36:13 -0300] [6840] [INFO] Starting gunicorn 26.2.0
[2026-10-30 15:36:13 -0300] [6840] [INFO] Listening at: http://0.0.0.0:8081 (6840)
[2026-10-30 15:36:13 -0300] [6840] [INFO] Using worker: sync
[2026-10-30 15:36:13 -0300] [6844] [INFO] Booting worker with pid: 6844
[2026-10-30 15:36:13 -0300] [6840] [INFO] Control socket listening at /home/ana/.gunicorn/gunicorn.ctl
```

O gunicorn diz em que endereço se ligou e que worker iniciou, e fica esperando. No primeiro
terminal:

```
ana@laptop:~/gcp/storefront$ curl -s localhost:8081/
shop storefront, version local
```

**A página respondeu `version local`** porque nada definiu `GAE_VERSION`. Publicado, o mesmo código
responde com o nome da versão, e a seção 03 usa exatamente isso para mostrar o tráfego passando de
uma versão para outra.

## Publicando, e onde o laboratório para

Publicar é um comando a partir da pasta, e aqui ele é recusado pelo motivo de todo comando remoto
deste curso:

```
ana@laptop:~/gcp/storefront$ gcloud app deploy
ERROR: (gcloud.app.deploy) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

Com uma conta, o `gcloud app deploy` envia a pasta, o Google faz o build, e a versão começa a
atender em `https://planner-dev.rj.r.appspot.com`, onde `rj` é o código que o Google dá à região
de São Paulo. **O primeiro deploy num projeto também cria a própria aplicação do App Engine**, e
esse passo tem uma consequência a que a seção 05 volta: a região escolhida ali é permanente.

Pare o gunicorn com Ctrl+C quando terminar.
