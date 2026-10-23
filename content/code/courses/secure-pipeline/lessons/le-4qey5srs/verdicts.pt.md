---
title: Quebra, alerta, passa: três códigos de saída
version: 1
---

Até agora um estágio tinha duas respostas: sai com 0 e a execução segue, qualquer outra coisa e ela
para. É um gate sem jeito de alertar, que obriga cada estágio a escolher entre quebrar por ruído e
esconder um achado real atrás de uma aprovação. A varredura dinâmica da aula 4 fez a segunda escolha:
`-I` mandava o ZAP sair com 0 nos alertas, então os alertas não chegavam a ninguém. **Falta uma
terceira resposta, e o pipeline tem de contá-la e mostrá-la**, senão um alerta é uma aprovação com
mais palavras.

### O pipeline, com alerta

O código de saída continua sendo o veredito: 0 passa, 3 passa com um alerta, e qualquer outra coisa
quebra o build. Um alerta imprime o fim do log do estágio, como uma falha, e a última linha os conta,
então uma execução com alertas nunca parece limpa. A checagem que a aula 2 acrescentou continua: uma
lista que não existe quebra a execução em vez de passar sem estágio nenhum. Salve como
`ci/pipeline.sh`:

```sh
#!/usr/bin/env bash
# The pipeline: every stage named in a list, in order. The list is ci/stages,
# what runs on every push, unless another is given, such as ci/nightly. A
# stage is the script ci/<name>.sh, run from the repository's root, and its
# exit status is its verdict: 0 passes, 3 passes with a warning that is
# counted and shown, and anything else breaks the build and stops the run.
# A list that is not there breaks it too, rather than passing with no stages.
set -uo pipefail
cd "$(dirname "$0")/.."
LIST=${1:-ci/stages}
[ -f "$LIST" ] || { echo "no list of stages at $LIST"; exit 1; }
LOGS=${CI_LOGS:-ci-logs}
mkdir -p "$LOGS"
warnings=0
while read -r stage; do
  case $stage in '' | '#'*) continue ;; esac
  start=$SECONDS
  bash "ci/$stage.sh" >"$LOGS/$stage.log" 2>&1
  status=$?
  took=$((SECONDS - start))
  if [ "$status" -eq 0 ]; then
    echo "$stage: passed in ${took}s"
  elif [ "$status" -eq 3 ]; then
    warnings=$((warnings + 1))
    echo "$stage: WARNING in ${took}s, the end of $stage.log:"
    tail -n 8 "$LOGS/$stage.log" | sed 's/^/  /'
  else
    echo "$stage: FAILED in ${took}s, the end of $stage.log:"
    tail -n 15 "$LOGS/$stage.log" | sed 's/^/  /'
    exit 1
  fi
done <"$LIST"
echo "pipeline passed with $warnings warning(s)"
```

### Por que 3

Um alerta precisa de um número que nenhuma falha produza por acidente, porque o pipeline lê o número e
mais nada. 1 é o que quase todo programa devolve quando falha, inclusive um programa Python que
trava. 2 está ocupado duas vezes: o Python sai com 2 quando é chamado com uma opção que não conhece, e
a varredura baseline do ZAP sai com 2 quando tem alertas. 127 é o shell dizendo que um comando não
existe:

@@CAPTURE statuses@@

**Se o alerta fosse 2, um estágio cujo programa foi chamado com um erro de digitação numa flag teria
passado com alerta**, e uma execução que não checou nada teria seguido. O 3 não está livre no mundo; o
gunicorn saiu com 3 na aula 6 quando o worker não conseguiu subir. Dentro destes estágios ele só vem de
uma linha que diz `exit 3` de propósito ou do gate abaixo, que é a propriedade que importa. Todo código
que o pipeline não reconhece quebra o build, então um programa que falha de um jeito que ninguém previu
falha fechado.

### Análise estática: o que quebra e o que alerta

Salve como `ci/sast.sh`:

```sh
# Static analysis. A finding of medium severity or worse breaks the build,
# and a low one is a warning.
set -uo pipefail
semgrep scan --metrics=off --quiet --error --emacs --config .semgrep.yml . || exit 1
bandit -q -r . -c bandit.yaml --severity-level medium || exit 1
bandit -q -r . -c bandit.yaml --severity-level low || exit 3
```

O Semgrep roda só as duas regras que a aula 3 escreveu para este projeto, cada uma para um defeito que
o linkbox de fato teve, então um achado de qualquer uma quebra o build. `--emacs` imprime cada achado numa linha simples, com
arquivo, linha e mensagem, que é o que um log de CI consegue mostrar. As regras embutidas do Bandit
são mais amplas, e a severidade delas é a linha entre os dois vereditos: média ou alta quebra, baixa
alerta. Isso é um julgamento sobre as regras do Bandit, não uma lei. Os achados baixos dele são, na
maioria, do tipo que a aula 3 viu no B105, uma string que parece senha e precisa que uma pessoa a leia,
e uma pessoa ler é o que um alerta pede.

**Cada comando carrega o próprio `|| exit`**, então o veredito de cada um fica escrito ao lado dele. O
`set -e` conhece um tipo só de falha e transformaria todas no mesmo código, que é o que esta aula está
desfazendo.

### Análise dinâmica: os vereditos do próprio ZAP

A varredura baseline do ZAP já tem três respostas: 0 para nada, 2 para alertas e 1 para uma regra
marcada FAIL, mais 3 quando a varredura em si não conseguiu terminar. A nova versão para de esconder
os alertas, tira o `-I` e traduz. Salve como `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own, and ZAP's baseline scan against it from a second container. The scan
# only looks: it reads what the application answers and sends it nothing
# meant to break it. ZAP's own exit status is the verdict: a rule set to FAIL
# in ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
# could not finish breaks the build too.
set -uo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" \
  -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -z -silent
case $? in
  0) exit 0 ;;
  2) exit 3 ;;
  *) exit 1 ;;
esac
```

O `case` leva o 2 para o 3 do pipeline, mantém o 0 e manda **todo o resto para 1**: uma regra FAIL,
uma varredura que travou, um contêiner que nunca subiu. O `set -e` saiu deste script porque, com ele, o 2 do ZAP teria parado o script antes que o `case` pudesse lê-lo.

| estágio | quebra o build (1) | alerta (3) | passa (0) |
|---|---|---|---|
| `secrets` | qualquer achado não registrado como morto | nunca | nada encontrado |
| `sast` | um achado do Semgrep, um achado do Bandit de severidade média ou maior | um achado do Bandit de severidade baixa | nada encontrado |
| `sca` | um aviso com correção e sem exceção | um aviso sem correção; uma exceção na última semana | nada a apontar |
| `dast` | uma regra FAIL, ou uma varredura que não terminou | uma regra WARN | nada encontrado |

A linha do `sca` é a que precisa de um programa para decidir, e é a próxima seção.
