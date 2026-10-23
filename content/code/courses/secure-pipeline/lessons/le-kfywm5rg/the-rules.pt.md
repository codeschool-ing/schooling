---
title: As regras que um build obedece, e o script que roda a varredura
version: 1
---

Um scanner que relata e nunca decide é um scanner cuja saída ninguém precisa ler. **A decisão fica
escrita regra por regra, num arquivo que o build obedece**: para cada regra, se um acerto quebra o
build, é relatado ou é descartado. A baseline do ZAP lê esse arquivo com `-c`, e o formato é uma
regra por linha, com três campos separados por tabulação: o id da regra, a ação e o nome da regra
entre parênteses, que o ZAP ignora e uma pessoa lê.

| ação | o que um acerto faz | quando serve |
|---|---|---|
| `FAIL` | quebra o build (status de saída 1) | um defeito real, com correção nas suas mãos, que não pode voltar |
| `WARN` | é relatado, e o build segue | um achado que pede o julgamento de uma pessoa, ou que você não consegue corrigir hoje |
| `IGNORE` | sai da saída | uma regra que não se aplica de jeito nenhum a este serviço |
| `INFO` | é relatado só como informação | uma regra mantida para registro |

Uma regra que o arquivo não lista fica com o padrão, que é WARN. `zap-baseline.py -g FILE` escreve um
arquivo inicial com toda regra em WARN, que é uma lista útil para ler uma vez e um arquivo ruim para
manter: sessenta linhas que ninguém decidiu são sessenta linhas que ninguém vai revisar.

### As regras do linkbox

Três dos quatro achados são cabeçalhos ausentes, cada um corrigido por uma linha no código do próprio
linkbox, e, uma vez corrigido, uma regressão seria um defeito real. Essas três ficam em FAIL. A
quarta, 10031, não está listada, então continua WARN, e a seção da correção explica por que ela
também não é ignorada. Salve o arquivo como `ci/zap-rules.conf`:

```
# ZAP baseline rules for linkbox: a rule id, a tab, and what a match does.
# FAIL breaks the build, WARN reports it and IGNORE drops it. A rule that is
# not listed warns.
10020	FAIL	(Anti-clickjacking Header)
10021	FAIL	(X-Content-Type-Options Header Missing)
10038	FAIL	(Content Security Policy (CSP) Header Not Set)
```

Os separadores são caracteres de tabulação, não espaços. O ZAP divide cada linha nas tabulações, e
uma linha digitada com espaços não é lida.

### O estágio

O script monta o staging das seções anteriores, roda a varredura nele e desmonta tudo, aconteça o que
acontecer. Salve-o como `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own, and ZAP's baseline scan against it from a second container. The scan
# only looks: it reads what the application answers and sends it nothing
# meant to break it. A rule set to FAIL in ci/zap-rules.conf breaks the build.
set -euo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -I -z -silent
```

Para que serve cada parte:

- **`net=linkbox-staging-$$`.** `$$` é o id do processo do shell, então cada execução dá nome à
  própria rede e ao próprio contêiner, `linkbox-staging-<pid>-app`, e duas execuções ao mesmo tempo
  não se encontram.
- **O `trap … EXIT`.** Ele roda quando o script termina, com sucesso, com falha ou com o `set -e`
  parando no meio, e remove o contêiner e a rede. Sem ele, uma varredura que falha deixaria um
  serviço rodando na máquina para a próxima execução tropeçar.
- **`linkbox:${CI_COMMIT:-dev}`.** A imagem que esta execução construiu, marcada pelo `ci/build.sh`
  com a mesma variável, então a varredura lê o commit em teste e nenhum outro.
- **`sleep 2`.** O gunicorn precisa de um instante antes de responder. Dois segundos é um palpite que
  vale nesta máquina; um laço perguntando até o serviço responder seria mais robusto, e mais longo
  que o resto do script.
- **`-v "$PWD/ci:/zap/wrk:ro"`.** O ZAP procura os arquivos de `-c` em `/zap/wrk`. O diretório `ci`
  do projeto é montado ali só para leitura, então o scanner lê as regras e não muda nada.
- **`-I`.** Um WARN deixa de dar status de saída 2. Só um FAIL, ou uma varredura que não conseguiu
  terminar, quebra o build. A aula 7 troca isso por um terceiro desfecho, um alerta que o pipeline
  relata sem parar.

### A primeira execução quebra o build

Os cabeçalhos ainda não foram corrigidos, então o script deveria falhar, e **uma checagem só merece
confiança depois que você a viu falhar pelo motivo para o qual existe**. Rode-o na imagem do código
da aula 3, que o build da seção de staging deixou como `linkbox:dev`:

```
ana@vm:~/linkbox$ bash ci/dast.sh > /tmp/dast.log; echo "exit status $?"
2026-10-23 04:47:02,540 Unable to copy yaml file to /zap/wrk/zap.yaml [Errno 30] Read-only file system: '/zap/wrk/zap.yaml'
exit status 1
ana@vm:~/linkbox$ grep -v ^PASS /tmp/dast.log
Using the Automation Framework
Total of 4 URLs
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: Missing Anti-clickjacking Header [10020] x 2 
	http://linkbox-staging-6166-app:8000 (200 OK)
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: X-Content-Type-Options Header Missing [10021] x 2 
	http://linkbox-staging-6166-app:8000 (200 OK)
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: Content Security Policy (CSP) Header Not Set [10038] x 2 
	http://linkbox-staging-6166-app:8000 (200 OK)
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: 3	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 57
```

Status de saída 1, e as três regras que o arquivo marcou como FAIL agora são `FAIL-NEW`. O 10031
continua `WARN-NEW`, porque nada decidiu outra coisa. O 10038 bateu em duas respostas desta vez,
contra três na seção anterior, na mesma imagem: as contagens mudam, o veredicto não. No pipeline, a
saída inteira vai para `ci-logs/dast.log`, do jeito que o executor da aula 1 guarda o log de cada
estágio.

A linha sobre `zap.yaml` é o ZAP tentando salvar em `/zap/wrk` o plano que gerou para a execução. O
diretório está montado só para leitura de propósito, então o salvamento falha, o ZAP avisa na saída
de erro e a varredura segue. Ela aparece em toda execução deste estágio, e é a montagem só de
leitura fazendo o trabalho dela.

Esse é o estado de um time no dia em que uma checagem nova chega: está vermelha, e está certa. A
correção é a próxima seção, e vem com um teste, porque a varredura sozinha só avisaria de uma
regressão na próxima vez que rodasse.
