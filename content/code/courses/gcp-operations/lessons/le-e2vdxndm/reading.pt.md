---
title: Lendo um segredo em tempo de execução
version: 1
---

**A API lê a senha quando inicia, de um arquivo que a plataforma põe ali, e nunca da própria imagem ou do
repositório.** O Cloud Run pode expor uma versão de segredo a um contêiner de duas formas: como **variável de
ambiente**, resolvida uma vez quando a instância inicia, ou como **arquivo num volume montado**, que o Cloud Run
mantém apontando para a versão que ele nomeia. De qualquer jeito o código lê um valor em tempo de execução, e a
imagem guarda só o nome de onde procurar. Nenhum dos dois rodou aqui; o que roda é o mesmo formato com o Docker,
onde um arquivo que você escreve faz o papel do volume que o Cloud Run montaria.

O programa lê o arquivo cujo caminho recebe, e diz o que achou sem imprimi-lo. Escreva-o em `~/gcp/readsecret.py`:

```python
# readsecret.py
import os
import pathlib

path = pathlib.Path(os.environ.get("DB_PASSWORD_FILE", "/secrets/db-password"))
password = path.read_text().strip()
print(f"read {len(password)} characters from {path}, starting with {password[:2]}…")
```

Depois crie `~/gcp/secrets/db-password` com um valor de treino dentro, e monte esse diretório só para leitura onde
o Cloud Run montaria o segredo:

```
ana@laptop:~/gcp$ docker run --rm -v "$PWD/secrets":/secrets:ro -v "$PWD/readsecret.py":/app/readsecret.py:ro mirror.gcr.io/library/python:3.12.16-slim python /app/readsecret.py
read 19 characters from /secrets/db-password, starting with k7…
```

**O programa imprime o tamanho e dois caracteres, nunca o valor.** Um segredo impresso num log é um segredo no
Cloud Logging, legível por todos com `roles/logging.viewer` e guardado pelo tempo que o bucket da lição 9 guardar.
Depurar uma string de conexão imprimindo-a é o jeito mais comum de uma senha sair do Secret Manager.

## Variável de ambiente ou arquivo

| | variável de ambiente | arquivo montado |
|---|---|---|
| quando é lido | uma vez, quando a instância inicia | pelo código, sempre que ele abre o arquivo |
| uma versão nova | só chega a instâncias iniciadas depois dela | chega ao arquivo de uma instância em execução se a montagem nomeia `latest` |
| visível para | tudo o que lê o ambiente do processo, inclusive um relatório de falha que o despeja | o processo que lê o arquivo |

A loja monta arquivos, pela segunda e terceira linhas: uma instância em execução pega uma senha girada sem
reiniciar, desde que o código releia o arquivo numa conexão que falhou, e nada que despeja o ambiente despeja a
senha. **Fixe um número de versão, não `latest`, para tudo em que uma mudança não revisada quebraria a produção**;
`latest` é o certo para uma senha que um job de rotação troca de propósito.
