---
title: Uma correção automática, julgada pelo pipeline
version: 1
---

A mudança de um bot é uma mudança como qualquer outra, e quem a julga é o pipeline. Esta seção torna
isso concreto na branch com o lock de um mês atrás. Primeiro o pipeline acha o aviso; depois uma
ferramenta que escreve correções por você faz uma; depois o pipeline julga a correção.

### O pipeline acha

Envie a branch para o servidor de CI. Toda branch roda o pipeline:

```
ana@vm:~/linkbox$ git push ci stale-lock
remote: run 2: stale-lock at 159779d        
remote: secrets: passed in 1s        
remote: workflows: passed in 0s        
remote: test: passed in 1s        
remote: sast: passed in 4s        
remote: sca: FAILED in 7s, the end of sca.log:        
remote:   Found 1 known vulnerability in 1 package        
remote:   BREAKS: werkzeug 3.1.8 PYSEC-2026-4312, fixed in 3.1.9        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      stale-lock -> stale-lock
```

O estágio de composição quebrou o build, com o portão da aula 7 dizendo por quê: o werkzeug 3.1.8 tem
um aviso, PYSEC-2026-4312, com versão corrigida, a 3.1.9. Em 20 de setembro não havia nada a
relatar, porque a correção e o aviso vieram depois. **Um lock que era seguro quando foi compilado não
é seguro para sempre**, e é assim que isso aparece: nada na branch mudou, e o veredito mudou.

### A correção automática

O pip-audit consegue corrigir o que acha. `--fix` move cada pacote vulnerável para a primeira versão
que corrige os avisos dele e grava o resultado de volta nos arquivos de requisitos:

```
ana@vm:~/linkbox$ pip-audit --fix -r requirements.txt -r requirements-dev.txt
WARNING:pip_audit._dependency_source.requirement:added fixed subdependency explicitly to requirements file requirements-dev.txt: werkzeug
Found 1 known vulnerability in 1 package and fixed 1 vulnerability in 1 package
Name     Version ID              Fix Versions Applied Fix
-------- ------- --------------- ------------ -----------------------------------------------
werkzeug 3.1.8   PYSEC-2026-4312 3.1.9        Successfully upgraded werkzeug (3.1.8 => 3.1.9)
ana@vm:~/linkbox$ grep -A2 "^werkzeug" requirements.txt requirements-dev.txt
requirements.txt:werkzeug==3.1.9 \
requirements.txt-    --hash=sha256:63a77fb8892bf28ebc3178683445222aa500e48ebad5ec77b0ad80f8726b1f50 \
requirements.txt-    --hash=sha256:9bad61a4268dac112f1c5cd4630a56ede601b6ed420300677a869083d70a4c44
--
requirements-dev.txt:werkzeug==3.1.9
ana@vm:~/linkbox$ git diff --stat
 requirements-dev.txt | 12 +++++++-----
 requirements.txt     | 24 ++++++++++++------------
 2 files changed, 19 insertions(+), 17 deletions(-)
```

Ele relata sucesso, e a linha de versão concorda: `werkzeug==3.1.9`. Leia as duas linhas abaixo dela.
**Esses hashes são do werkzeug 3.1.8**; são os mesmos dois hashes que o lock antigo tinha. O
pip-audit editou a versão e deixou o resto da entrada como estava, e fez mais duas mudanças que
ninguém pediu: acrescentou o werkzeug ao `requirements-dev.txt` como um pin próprio, sem hash nenhum,
avisando no warning; e reescreveu a indentação dos comentários `# via`, que são a maior parte das
36 linhas alteradas do diff. O `requirements.in` continua sem dizer nada sobre o werkzeug, então a próxima
compilação desfaria a correção.

Nada nessa saída parece errado a menos que você saiba para que serve uma linha de hash. Faça o commit
como um bot faria, e deixe o pipeline julgar:

```
ana@vm:~/linkbox$ git commit -q -am "pip-audit --fix"
10:18AM INF 0 commits scanned.
10:18AM INF scanned ~313 bytes (313 bytes) in 207ms
10:18AM INF no leaks found
ana@vm:~/linkbox$ git push ci stale-lock
remote: run 3: stale-lock at b5392bd        
remote: secrets: passed in 1s        
remote: workflows: passed in 0s        
remote: test: FAILED in 0s, the end of test.log:        
remote:   error: In `--require-hashes` mode, all requirements must have a hash, but none were provided for: werkzeug==3.1.9        
remote: run 3: failed, the logs are in ~/ci/runs/3/logs        
To /home/ana/ci/linkbox.git
   159779d..b5392bd  stale-lock -> stale-lock
```

O estágio de testes quebrou, antes de qualquer scanner rodar, e o uv nomeia a primeira coisa que
recusou: no modo `--require-hashes` todo requisito precisa de hash, e o pin que o pip-audit
acrescentou ao `requirements-dev.txt` não tem nenhum. Essa é só a primeira recusa. Instale o `requirements.txt` sozinho, num ambiente
de rascunho, e a segunda está esperando; as últimas seis linhas do erro do uv são a parte que
importa:

```
ana@vm:~/linkbox$ uv venv -q /tmp/hashcheck
ana@vm:~/linkbox$ uv pip install -q --python /tmp/hashcheck --require-hashes -r requirements.txt 2>&1 | tail -n 6
      Expected:
        sha256:63a77fb8892bf28ebc3178683445222aa500e48ebad5ec77b0ad80f8726b1f50
        sha256:9bad61a4268dac112f1c5cd4630a56ede601b6ed420300677a869083d70a4c44

      Computed:
        sha256:6392e50c78460ba618e5b21f08a71f59c99ce99cdc6cf6e3dd7e6ccca8754fab
```

O uv baixou o werkzeug 3.1.9, calculou o hash dele e viu que não era nenhum dos dois que o lock espera, porque esses são da 3.1.8. **As duas recusas são o controle da aula 15 funcionando como projetado**: um pin
sem hash, ou com o hash de outro arquivo, é exatamente a cara de uma adulteração, e o instalador
não distingue um engano honesto de um ataque, então recusa os dois. A correção automática não
consertou o build; ela levou a falha do portão de segurança para a instalação.

### A correção que um lock pede

Reverta o commit do bot, o que traz o lock antigo de volta como um commit novo em vez de reescrever
uma branch que o servidor de CI já tem, e faça a mudança do jeito que a aula 15 fez toda mudança no
lock: compilar de novo. `-P werkzeug` deixa o uv mover esse pacote e mantém todos os outros pins como o arquivo os
tem, e a nova data de `--exclude-newer` permite a versão corrigida:

```
ana@vm:~/linkbox$ git revert --no-edit HEAD
[stale-lock 4709680] Revert "pip-audit --fix"
 Date: Fri Oct 23 10:18:28 2026 -0300
 2 files changed, 17 insertions(+), 19 deletions(-)
ana@vm:~/linkbox$ uv pip compile -q requirements.in --generate-hashes --exclude-newer 2026-10-16 -P werkzeug -o requirements.txt
ana@vm:~/linkbox$ git diff
diff --git a/requirements.txt b/requirements.txt
index 39214f3..e765172 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,5 +1,5 @@
 # This file was autogenerated by uv via the following command:
-#    uv pip compile requirements.in --generate-hashes --exclude-newer 2026-09-20 -o requirements.txt
+#    uv pip compile requirements.in --generate-hashes --exclude-newer 2026-10-16 -o requirements.txt
 blinker==1.9.0 \
     --hash=sha256:b4ce2265a7abece45e7cc896e98dbebe6cead56bcf805a3d23136d145f5445bf \
     --hash=sha256:ba0efaa9080b619ff2f3459d1d500c57bddea4a6b424b60a91141db6fd2f08bc
@@ -118,7 +118,7 @@ markupsafe==3.0.3 \
     #   flask
     #   jinja2
     #   werkzeug
-werkzeug==3.1.8 \
-    --hash=sha256:63a77fb8892bf28ebc3178683445222aa500e48ebad5ec77b0ad80f8726b1f50 \
-    --hash=sha256:9bad61a4268dac112f1c5cd4630a56ede601b6ed420300677a869083d70a4c44
+werkzeug==3.1.9 \
+    --hash=sha256:55ca7c70a75689be937aa27f8ff4b018f06ff4838fc73045560bf0f5a1291060 \
+    --hash=sha256:6392e50c78460ba618e5b21f08a71f59c99ce99cdc6cf6e3dd7e6ccca8754fab
     # via flask
```

O diff é a linha de cabeçalho, que registra o comando novo, e três linhas do werkzeug: uma versão nova
e os dois hashes que vão com ela. Envie:

```
ana@vm:~/linkbox$ git commit -q -am "werkzeug 3.1.9, for PYSEC-2026-4312"
10:18AM INF 0 commits scanned.
10:18AM INF scanned ~287 bytes (287 bytes) in 213ms
10:18AM INF no leaks found
ana@vm:~/linkbox$ git push ci stale-lock
remote: run 4: stale-lock at 3576bfa        
remote: secrets: passed in 0s        
remote: workflows: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: passed in 8s        
remote: build: passed in 3s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 4s        
remote: sign: passed in 2s        
remote: pipeline passed with 0 warning(s)        
remote: run 4: passed        
To /home/ana/ci/linkbox.git
   b5392bd..3576bfa  stale-lock -> stale-lock
```

Todos os estágios passam. O pluggy 1.6.0, o markupsafe 3.0.3 e o iniconfig 2.3.0 continuam antigos, e
tudo bem: eles não têm aviso, e são as atualizações de rotina que os bots vão propor numa segunda,
depois da espera.

### O que isso diz sobre correções automáticas

| | `pip-audit --fix` | `uv pip compile -P werkzeug` |
|---|---|---|
| acha a versão que corrige o aviso | sim | não, você nomeia o pacote |
| sabe que o arquivo é um lock compilado | não | sim, foi ele que o escreveu |
| escreve os hashes da versão nova | não, e acrescenta um pin sem nenhum | sim |
| muda só o que foi pedido | não: um pin novo no arquivo de dev, e todo comentário | sim: um pacote e o cabeçalho |
| o veredito do pipeline | quebrado na instalação | passou |

A questão não é que o pip-audit seja uma ferramenta ruim. O `--fix` dele foi escrito para uma lista
simples de pins, e numa lista assim ele faz a coisa certa. **Uma ferramenta de correção vale o quanto
ela entende o arquivo que edita**, e o pull request de um bot merece a mesma pergunta que o de
qualquer pessoa: o pipeline que o julgou conferiu o que importa? Aqui conferiu, porque a aula 15 fez a
instalação checar hashes. Um pipeline sem essa checagem teria instalado o werkzeug 3.1.9, passado em
todos os estágios e entregado um lock cujos hashes não protegiam nada.

A branch cumpriu o papel dela. Deixe-a sem merge: `main` nunca teve o lock antigo, e o merge traria
quatro pins de um mês atrás de volta junto com a única correção.
