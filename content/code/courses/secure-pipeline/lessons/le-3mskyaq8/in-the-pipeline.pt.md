---
title: Workflows conferidos a cada push
version: 1
---

Um arquivo de workflow é código que roda com credenciais, então ele recebe o que todo outro tipo de
código deste repositório recebe: uma checagem a cada push que quebra o build quando acha algo. O
estágio é uma linha de zizmor. Salve-o como `ci/workflows.sh`:

```sh
# The workflows and the bots' settings under .github, audited by zizmor with
# no network: what it can judge from the files alone. Any finding it reports
# breaks the build.
set -euo pipefail
zizmor --quiet --offline .github
```

Ele lê todo o `.github`, então os arquivos de configuração que a aula 18 acrescenta ali para os bots de
atualização também são lidos. E ele vem em segundo, logo depois de `secrets`, porque leva um segundo e
só lê texto. Salve a lista como `ci/stages`:

```
secrets
workflows
test
sast
sca
build
image
push
sbom
sign
```

### A execução

Faça commit do workflow e do estágio juntos, e envie:

```
ana@vm:~/linkbox$ git add .github ci
ana@vm:~/linkbox$ git commit -q -m "the pipeline's own workflow hardened, and checked by zizmor on every push"
9:46AM INF 0 commits scanned.
9:46AM INF scanned ~1130 bytes (1.13 KB) in 219ms
9:46AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 5834f06        
remote: secrets: passed in 0s        
remote: workflows: passed in 0s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 10s        
remote: build: passed in 2s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 5s        
remote: sign: passed in 2s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   42b39e2..5834f06  main -> main
```

`workflows` passou em segundo, e os outros nove passaram como na aula 15. A CI local não roda o
workflow, e não precisa: ela o lê, que é a checagem que importa para um arquivo cujo risco está no que
ele diz.

### Uma regressão, pega

Um mês depois, alguém acha o `env:` e o `$TITLE` complicados demais e põe o título de volta onde
estava. Numa branch:

```
ana@vm:~/linkbox$ git switch -q -c title-in-run
ana@vm:~/linkbox$ git diff | grep "^[-+] "
-        run: echo "testing $TITLE"
+        run: echo "testing ${{ github.event.pull_request.title }}"
ana@vm:~/linkbox$ git commit -q -am "print the title directly"
9:46AM INF 0 commits scanned.
9:46AM INF scanned ~67 bytes (67 bytes) in 255ms
9:46AM INF no leaks found
ana@vm:~/linkbox$ git push ci title-in-run
remote: run 2: title-in-run at c99af99        
remote: secrets: passed in 1s        
remote: workflows: FAILED in 0s, the end of workflows.log:        
remote:   error[template-injection]: code injection via template expansion        
remote:     --> .github/workflows/ci.yml:27:32        
remote:      |        
remote:   27 |         run: echo "testing ${{ github.event.pull_request.title }}"        
remote:      |         --- this run block     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ may expand into attacker-controllable code        
remote:      |        
remote:      = note: audit confidence → High        
remote:      = note: this finding has an auto-fix        
remote:      = help: audit documentation → https://docs.zizmor.sh/audits/#template-injection        
remote:           
remote:   1 findings (1 unsafe fixes): 0 informational, 0 low, 0 medium, 1 high        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      title-in-run -> title-in-run
```

**A branch para no segundo estágio**, com o achado e a linha, antes de um teste rodar ou de uma imagem
ser construída. A correção é a que a seção anterior fez, e o estágio vai continuar pedindo por ela em
toda branch que a desfizer. Nada chegou ao registry, porque o `push` nunca rodou.

### O que este estágio não vê

O zizmor offline lê os arquivos. Ele não confere se um commit fixado pertence mesmo à action que
nomeia, que é a auditoria `impostor-commit` e precisa da API do GitHub; nem sabe se uma versão de
action tem aviso publicado, que é a `known-vulnerable-actions` e precisa da mesma API. Rodadas online,
num job com token, essas duas auditorias também rodam. Nem ele nem scanner nenhum julga o runner em
que o workflow cai, que é o assunto das duas próximas seções.
