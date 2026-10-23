---
title: Quando a montagem falha
version: 1
---

Um laboratório que não funciona na primeira tentativa é normal, e as falhas são poucas e se
repetem. Cada uma abaixo foi produzida de propósito na máquina da gravação, então a mensagem é a que
você vai ver. Leia primeiro a última linha de um erro: as ferramentas imprimem a causa embaixo e o
contexto em cima.

### O CI não roda, e nada diz por quê

Esta é a perigosa, porque o push dá certo. O git só roda um hook com permissão de execução, e quando
ela falta, imprime uma dica e segue em frente:

```
ana@vm:~/linkbox$ chmod -x ~/ci/linkbox.git/hooks/post-receive
ana@vm:~/linkbox$ git commit -q --allow-empty -m "does the CI run?"
ana@vm:~/linkbox$ git push ci main
hint: The 'hooks/post-receive' hook was ignored because it's not set as executable.
hint: You can disable this warning with `git config advice.ignoredHook false`.
To /home/ana/ci/linkbox.git
   85988f7..82c44d5  main -> main
ana@vm:~/linkbox$ chmod +x ~/ci/linkbox.git/hooks/post-receive
```

**O push passou e nenhum pipeline rodou.** Sem a dica não haveria sinal nenhum: nenhuma linha
`remote:`, e um commit no servidor que nada checou. Essa é a falha contra a qual o curso inteiro é
construído, uma checagem que silenciosamente não aconteceu, e é por isso que o pipeline imprime uma
linha para cada estágio que roda e uma última dizendo que passou. **Quando fizer push, procure essa
última linha, não a ausência de erro.** `chmod +x` no hook resolve, e o push seguinte roda.

### O Docker não responde

```
ana@vm:~/linkbox$ DOCKER_HOST=unix:///run/nothing.sock docker version --format "{{.Server.Version}}"

failed to connect to the docker API at unix:///run/nothing.sock; check if the path is correct and if the daemon is running: dial unix /run/nothing.sock: connect: no such file or directory
```

O cliente não alcançou o daemon. A mensagem cita o socket que ele tentou, e isso diz qual das três
causas é. O daemon não está rodando: `sudo systemctl start docker` no Linux, ou abra o Docker
Desktop. `DOCKER_HOST` aponta para outro lugar: `unset DOCKER_HOST`. Ou, com o socket padrão, o
erro termina em `permission denied`, o que quer dizer que o seu usuário ainda não está no grupo
`docker`, ou está e não entrou de novo desde então; `id -nG` diz qual dos dois. Essa última
variante não foi reproduzida aqui.

### O PyPI não é alcançado

```
ana@vm:~/linkbox$ rm -rf .venv && uv venv -q
ana@vm:~/linkbox$ HTTPS_PROXY=http://127.0.0.1:9 uv pip install -r requirements.txt
error: Request failed after 3 retries in 5.0s
  Caused by: Failed to fetch: `https://pypi.org/simple/itsdangerous/`
  Caused by: error sending request for url (https://pypi.org/simple/itsdangerous/)
  Caused by: client error (Connect)
  Caused by: tunnel error: failed to create underlying connection
  Caused by: tcp connect error
  Caused by: Connection refused (os error 111)
```

O uv tentou três vezes e desistiu, e a cadeia de causas termina na conexão. Esta foi produzida
apontando o uv para um proxy onde nada escuta, por isso a cadeia cita um túnel; num computador sem
rede nenhuma ela termina num nome que não pôde ser resolvido. Seja como for, o índice de pacotes
nunca foi alcançado, então o arquivo de requisitos não é o problema. Se o seu computador chega à
internet por um proxy da empresa, `HTTPS_PROXY` precisa ter o endereço dele, e a autoridade
certificadora do proxy precisa ser uma em que o seu sistema confia.

### A porta está ocupada

```
ana@vm:~/linkbox$ .venv/bin/gunicorn --bind 127.0.0.1:8000 app:app
[2026-10-23 01:09:30 -0300] [24073] [INFO] Starting gunicorn 21.2.0
[2026-10-23 01:09:30 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:30 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:31 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:31 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:32 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:32 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:33 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:33 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:34 -0300] [24073] [ERROR] Connection in use: ('127.0.0.1', 8000)
[2026-10-23 01:09:34 -0300] [24073] [ERROR] Retrying in 1 second.
[2026-10-23 01:09:35 -0300] [24073] [ERROR] Can't connect to ('127.0.0.1', 8000)
```

Algo já escuta na porta 8000, muitas vezes um gunicorn que você subiu antes com `--daemon` e não
parou. `ss -ltnp 'sport = :8000'` diz qual processo é, e `kill $(cat linkbox.pid)` para o que esta
aula subiu. O gunicorn tenta cinco vezes, uma por segundo, antes de desistir, e por isso o erro se
repete.

### Qualquer outra coisa

Rode o mesmo comando de novo sem mudar nada, uma vez. Se falhar do mesmo jeito, a mensagem é a
informação, e a última linha mais o nome da ferramenta é o que buscar. Se falhar de outro jeito,
alguma coisa na máquina mudou entre as duas execuções, e vale saber disso antes de qualquer outra
coisa.
