---
title: Um deploy é um comando
version: 2
---

Um deploy que vive na cabeça de alguém, ou numa página de wiki com doze passos, é um deploy que sai
diferente a cada vez. **Um deploy deveria ser um comando que recebe um artefato e um ambiente e ou dá
certo por inteiro ou diz que falhou.** O do `shipquote` é um script. Salve como `ops/deploy.sh`:

```schooling-example
{
  "language": "sh",
  "file": "ops/deploy.sh",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# Deploy one built artifact to one environment, then smoke-test it.\n#   ops/deploy.sh staging dist/shipquote-1.4.0.tar.gz\n# An environment is a directory under ~/envs holding its own config.env;\n# every release is unpacked beside the others, and `current` points at one.\nset -euo pipefail\nenv=$1 artifact=$2\nroot=${SHIPQUOTE_ENVS:-$HOME/envs}/$env\n[ -f \"$root/config.env\" ] || { echo \"deploy: $root/config.env does not exist\" >&2; exit 1; }",
      "note": "Um ambiente é um diretório em `~/envs` com o próprio `config.env`. Um deploy para um ambiente que não tem um para aqui: sem padrões, sem adivinhar que porta a produção usa."
    },
    {
      "code": "(cd \"$(dirname \"$artifact\")\" && sha256sum --check --quiet \"$(basename \"$artifact\").sha256\")",
      "note": "O hash gravado pelo build é conferido **antes de qualquer coisa ser desempacotada**. A seção 08 mostra esta linha recusando um artefato."
    },
    {
      "code": "name=$(basename \"$artifact\" .tar.gz)\nversion=${name#shipquote-}\nmkdir -p \"$root/releases\"\ntar -xzf \"$artifact\" -C \"$root/releases\"\n[ -L \"$root/current\" ] && ln -sfn \"$(readlink \"$root/current\")\" \"$root/previous\"\nln -sfn \"releases/$name\" \"$root/current\"",
      "note": "Cada release é desempacotado ao lado dos outros, e `current` é um link para um deles. O link que estava lá antes é guardado como `previous`, que é o que o rollback da aula 11 usa."
    },
    {
      "code": "\"$(dirname \"$0\")/restart.sh\" \"$env\"\nset -a; . \"$root/config.env\"; set +a\n\"$(dirname \"$0\")/smoke.sh\" \"http://127.0.0.1:$SHIPQUOTE_PORT\" \"$version\"",
      "note": "Reinicia o processo do ambiente no release novo, depois roda o smoke test contra ele, com a versão que o nome do artefato prometeu."
    }
  ]
}
```

O `deploy.sh` passa dois trabalhos a scripts próprios. Parar o processo antigo e subir o novo é o
`restart.sh`. Salve como `ops/restart.sh`:

```sh
#!/usr/bin/env bash
# Stop the environment's running process, if any, and start `current` with
# the environment's own configuration.
set -euo pipefail
env=$1
root=${SHIPQUOTE_ENVS:-$HOME/envs}/$env
if [ -f "$root/pid" ] && kill -0 "$(cat "$root/pid")" 2>/dev/null; then
  kill "$(cat "$root/pid")"
  while kill -0 "$(cat "$root/pid")" 2>/dev/null; do sleep 0.1; done
fi
set -a; . "$root/config.env"; set +a
export SHIPQUOTE_ENV=$env
cd "$root/current"
setsid python3 -m shipquote.app >> "$root/app.log" 2>&1 < /dev/null &
echo $! > "$root/pid"
for _ in $(seq 50); do
  curl -s --max-time 1 "http://127.0.0.1:$SHIPQUOTE_PORT/health" > /dev/null && exit 0
  sleep 0.1
done
echo "restart: $env did not answer on port $SHIPQUOTE_PORT" >&2
exit 1
```

Ele guarda o id do processo no arquivo `pid` do ambiente, sobe o programa desligado do terminal com
`setsid`, com a saída acrescentada ao `app.log`, e espera até cinco segundos o `/health` responder.
O outro, `rollback.sh`, aponta o `current` de volta para o `previous`, e a aula 11 trata de quando
usá-lo. Ele faz parte desta versão, então salve-o agora também. Salve como `ops/rollback.sh`:

```sh
#!/usr/bin/env bash
# Point the environment back at the release it ran before, restart, smoke.
set -euo pipefail
env=$1
root=${SHIPQUOTE_ENVS:-$HOME/envs}/$env
[ -L "$root/previous" ] || { echo "rollback: $env has no previous release" >&2; exit 1; }
before=$(readlink "$root/previous")
ln -sfn "$(readlink "$root/current")" "$root/previous"
ln -sfn "$before" "$root/current"
"$(dirname "$0")/restart.sh" "$env"
set -a; . "$root/config.env"; set +a
"$(dirname "$0")/smoke.sh" "http://127.0.0.1:$SHIPQUOTE_PORT" "${before#releases/shipquote-}"
```

Um ambiente é um diretório que você cria, com uma configuração de uma linha:

```sh
mkdir -p ~/envs/staging ~/envs/production
echo SHIPQUOTE_PORT=8200 > ~/envs/staging/config.env
echo SHIPQUOTE_PORT=8300 > ~/envs/production/config.env
```

A configuração inteira do ambiente de homologação é essa linha, e o deploy para ele imprime uma
linha:

```
ana@laptop:~/shipquote$ cat ~/envs/staging/config.env
SHIPQUOTE_PORT=8200
ana@laptop:~/shipquote$ ops/deploy.sh staging dist/shipquote-1.4.0.tar.gz
smoke: http://127.0.0.1:8200 is up and running 1.4.0
ana@laptop:~/shipquote$ ls -F ~/envs/staging ~/envs/staging/releases
/home/ana/envs/staging:
app.log
config.env
current@
pid
releases/

/home/ana/envs/staging/releases:
shipquote-1.4.0/
ana@laptop:~/shipquote$ readlink ~/envs/staging/current
releases/shipquote-1.4.0
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8200/version; echo
{"version": "1.4.0", "env": "staging"}
```

O smoke test, assunto da próxima seção, achou o programa respondendo na porta 8200 e rodando 1.4.0. O
diretório mostra o arranjo: a configuração, o id e o log do processo, os releases, e `current`
apontando para `releases/shipquote-1.4.0`. O próprio programa confirma: versão `1.4.0`, ambiente
`staging`.

## Por que os releases ficam lado a lado

Desempacotar cada release no próprio diretório e trocar um link quer dizer que a troca é **uma
operação atômica**: não há momento em que metade dos arquivos é nova e metade velha. Também quer dizer
que o release anterior continua no disco, inteiro, então voltar é outra troca, e não outro build.
Plataformas de contêiner fazem o mesmo com imagens: toda revisão fica no registro, e implantar é
apontar o serviço para uma delas.

## O que o laboratório deixa de fora

Um deploy de verdade também precisa drenar as conexões do processo antigo antes de pará-lo, rodar as
migrações do banco na ordem certa e espalhar a mudança por muitas máquinas. O `restart.sh` simplesmente
para o processo antigo e sobe o novo, então por um instante nada responde na porta. A aula 10 mede
esse instante, e mostra dois jeitos de fazê-lo sumir.
