---
title: O mesmo script no laptop e no servidor
version: 1
---

Um pipeline que só roda num servidor é depurado na base do push: muda uma linha, faz push, espera, lê
o log, muda outra linha. Cada volta custa uma execução inteira e um commit que ninguém queria no
histórico. O linkbox evita isso por construção, porque **o pipeline é um script no repositório**, e o
servidor não faz nada além de rodá-lo. O que o servidor roda, o seu laptop também roda, antes do
push.

Essa é a teoria. Rode no projeto que você montou na aula 1:

```
ana@vm:~/linkbox$ ci/pipeline.sh
test: FAILED in 0s, the end of test.log:
  error: Failed to create virtual environment
    Caused by: A virtual environment already exists at: .venv
  
  hint: Use the `--clear` flag or set `UV_VENV_CLEAR=1` to replace the existing virtual environment
```

Falhou antes de rodar qualquer teste. O estágio de teste cria um ambiente virtual novo chamado
`.venv`, e **o seu projeto já tem um**, da aula 1, então o `uv` se recusa a substituí-lo. No servidor
o mesmo estágio passa toda vez, porque o hook clona o commit num diretório vazio a cada execução.
**O mesmo script não é a mesma execução**: o laptop carrega um estado que o servidor nunca tem, como
um ambiente antigo, um arquivo de banco, um build que sobrou de ontem ou uma mudança ainda sem
commit.

### Rodar do jeito que o servidor roda

As condições do servidor são fáceis de copiar: um clone novo, depois o pipeline do próprio clone.
Faça o mesmo num diretório de rascunho:

```
ana@vm:~/linkbox$ rm -rf /tmp/linkbox-run && git clone -q ~/linkbox /tmp/linkbox-run && /tmp/linkbox-run/ci/pipeline.sh
test: passed in 1s
build: passed in 0s
pipeline passed
```

Essa é a execução do servidor, na sua máquina, em mais ou menos o mesmo tempo. A imagem leva a tag
`dev` porque ninguém definiu `CI_COMMIT`, o que só o hook faz.

**Um clone limpo testa o que tem commit, e nada mais.** É para isso que ele serve, e também é o
limite dele: uma mudança que você ainda não commitou não está no clone. Para essas, rode a ferramenta
rápida que responde à pergunta em mãos: `.venv/bin/python -m pytest -q` para os testes e, a partir da
aula 3, a análise estática sozinha. Deixe a execução completa para o commit que você vai enviar. O
pipeline é o contrato; as ferramentas avulsas são a olhada rápida antes de assinar.

### Um pipeline que recebe uma lista

Esta aula dá ao pipeline uma segunda lista, para as checagens lentas que rodam uma vez por dia, então
o executor precisa saber qual lista ler. Ele lê `ci/stages` por padrão, que é o que o hook pede, e
qualquer outro arquivo dado como primeiro argumento. Salve como `ci/pipeline.sh`:

```sh
#!/usr/bin/env bash
# The pipeline: every stage named in a list, in order. The list is ci/stages,
# what runs on every push, unless another is given, such as ci/nightly. A
# stage is the script ci/<name>.sh, run from the repository's root. Exit 0
# passes it; anything else breaks the build, and the run stops at that stage.
# A list that is not there breaks it too, rather than passing with no stages.
set -uo pipefail
cd "$(dirname "$0")/.."
LIST=${1:-ci/stages}
[ -f "$LIST" ] || { echo "no list of stages at $LIST"; exit 1; }
LOGS=${CI_LOGS:-ci-logs}
mkdir -p "$LOGS"
while read -r stage; do
  case $stage in '' | '#'*) continue ;; esac
  start=$SECONDS
  if bash "ci/$stage.sh" >"$LOGS/$stage.log" 2>&1; then
    echo "$stage: passed in $((SECONDS - start))s"
  else
    echo "$stage: FAILED in $((SECONDS - start))s, the end of $stage.log:"
    tail -n 15 "$LOGS/$stage.log" | sed 's/^/  /'
    exit 1
  fi
done <"$LIST"
echo "pipeline passed"
```

O Git mostra as linhas que mudaram em relação à versão da aula 1:

```
ana@vm:~/linkbox$ git diff ci/pipeline.sh | grep '^[-+]'
--- a/ci/pipeline.sh
+++ b/ci/pipeline.sh
-# The pipeline: every stage named in ci/stages, in that order. A stage is the
-# script ci/<name>.sh, run from the repository's root. Exit 0 passes it;
-# anything else breaks the build, and the run stops at that stage.
+# The pipeline: every stage named in a list, in order. The list is ci/stages,
+# what runs on every push, unless another is given, such as ci/nightly. A
+# stage is the script ci/<name>.sh, run from the repository's root. Exit 0
+# passes it; anything else breaks the build, and the run stops at that stage.
+# A list that is not there breaks it too, rather than passing with no stages.
+LIST=${1:-ci/stages}
+[ -f "$LIST" ] || { echo "no list of stages at $LIST"; exit 1; }
-done <ci/stages
+done <"$LIST"
```

### A linha que impede um passe silencioso

Uma linha da mudança está ali por causa de uma falha que você não veria de outro jeito. **Sem ela,
uma lista que não existe é um pipeline que passa.** O laço `while` lê as linhas do arquivo; quando o
arquivo não existe, o bash imprime uma reclamação, o laço roda zero vezes e o script segue até a
última linha. Para ver, faça uma cópia do executor sem essa linha e dê a ela o nome de uma lista com
erro de digitação:

```
ana@vm:~/linkbox$ grep -v 'no list of stages' ci/pipeline.sh > ci/unguarded.sh
ana@vm:~/linkbox$ bash ci/unguarded.sh ci/stagse; echo "exit $?"
ci/unguarded.sh: line 22: ci/stagse: No such file or directory
pipeline passed
exit 0
ana@vm:~/linkbox$ rm ci/unguarded.sh
```

**"pipeline passed", e o status de saída é 0.** Nada rodou. No laptop, alguém talvez note a
reclamação logo acima; num job agendado que ninguém vigia, um erro de digitação no nome da lista
relataria um passe toda noite, enquanto o agendamento existisse. O executor que você salvou recusa:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/stagse; echo "exit $?"
no list of stages at ci/stagse
exit 1
```

Uma checagem que não rodou não é uma checagem que passou. A aula 7 faz disso uma regra para todo
estágio, e este é o primeiro lugar do curso que precisa dela.
