---
title: Um staging que roda do jeito que a produção vai rodar
version: 1
---

A aula 4 montou o staging da varredura dinâmica: uma rede criada para uma execução, o linkbox num
contêiner e o ZAP em outro. Ela iniciava o linkbox com `docker run` e os padrões, o que quer dizer que
**o scan testava um contêiner que a produção nunca deveria rodar**: gravável, com catorze capabilities
ao alcance. Um ambiente de staging merece o nome quando se parece com aquilo que ele substitui, e um
controle que quebra a aplicação é mais bem achado por um scan noturno do que pelo primeiro deploy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"sp-l09-staging\" aria-label=\"Uma execução do estágio de varredura dinâmica. Uma rede é criada para a execução. O linkbox sobe nela somente leitura, sem capabilities e sem privilégios novos, e o scan baseline do ZAP pede as páginas dele a partir de um segundo contêiner. O status de saída do ZAP vira o do estágio: 0 passa, 2, um alerta, vira 3, e qualquer outro, incluindo um scan que não alcançou a aplicação, vira 1 e quebra o build.\"><defs><marker id=\"sp-l09-staging-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"400\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma rede só para esta execução</text><rect x=\"35\" y=\"60\" width=\"360\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">linkbox:&lt;commit&gt;</text><text x=\"215.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">somente leitura, sem capabilities</text><rect x=\"35\" y=\"175\" width=\"360\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ZAP baseline, -z -silent</text><text x=\"215.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">zaproxy/zap-stable:2.17.0</text><path d=\"M215 173 L215 118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><text x=\"222\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pede cada página que encontra</text><text x=\"500\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o ZAP sai com</text><text x=\"650\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o estágio sai com</text><rect x=\"445\" y=\"55\" width=\"110\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><rect x=\"590\" y=\"55\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"647.5\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aprovado</text><path d=\"M555 78 L588 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><rect x=\"445\" y=\"121\" width=\"110\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><rect x=\"590\" y=\"121\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"647.5\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alerta</text><path d=\"M555 144 L588 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><rect x=\"445\" y=\"187\" width=\"110\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">qualquer outro</text><rect x=\"590\" y=\"187\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"647.5\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">build quebrado</text><path d=\"M555 210 L588 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><line x1=\"397\" y1=\"203\" x2=\"425\" y2=\"203\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"425\" y1=\"78\" x2=\"425\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><path d=\"M425 78 L443 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><path d=\"M425 144 L443 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path><path d=\"M425 210 L443 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l09-staging-ah-paper-dim)\"></path></svg>", "caption": "O mesmo scan da aula 4, contra um contêiner iniciado do jeito que a produção o inicia.", "same": ["ZAP baseline, -z -silent"]}
```

### A mudança

Quatro flags entram no `docker run` que inicia o linkbox, exatamente as que esta aula testou uma a
uma. O script novo, como `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own the way it runs everywhere, read-only and with no privileges, and ZAP's
# baseline scan against it from a second container. The scan only looks: it
# reads what the application answers and sends it nothing meant to break it.
# ZAP's own exit status is the verdict: a rule set to FAIL in
# ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
# could not finish breaks the build too.
set -uo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" \
  --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 \
  --cap-drop ALL --security-opt no-new-privileges \
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

O que mudou em relação à versão da aula 7, do jeito que o git mostra:

```
ana@vm:~/linkbox$ git diff ci/dast.sh
diff --git a/ci/dast.sh b/ci/dast.sh
index 685912a..4bba5ea 100644
--- a/ci/dast.sh
+++ b/ci/dast.sh
@@ -1,14 +1,17 @@
 # Dynamic analysis: the image this run built, started on a network of its
-# own, and ZAP's baseline scan against it from a second container. The scan
-# only looks: it reads what the application answers and sends it nothing
-# meant to break it. ZAP's own exit status is the verdict: a rule set to FAIL
-# in ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
+# own the way it runs everywhere, read-only and with no privileges, and ZAP's
+# baseline scan against it from a second container. The scan only looks: it
+# reads what the application answers and sends it nothing meant to break it.
+# ZAP's own exit status is the verdict: a rule set to FAIL in
+# ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
 # could not finish breaks the build too.
 set -uo pipefail
 net=linkbox-staging-$$
 docker network create "$net" >/dev/null
 trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
 docker run -d --rm --name "$net-app" --network "$net" \
+  --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 \
+  --cap-drop ALL --security-opt no-new-privileges \
   -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
 sleep 2
 docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
```

**Só o comentário e duas linhas de flags.** O scan, a rede, a limpeza e a tradução do status de saída
do ZAP em aprovação, alerta ou quebra são da aula 4 e da aula 7, intocados. Os limites de memória e de
processos ficam de fora, como a seção anterior argumentou: o staging vive um minuto.

### A execução noturna

A varredura dinâmica está na lista noturna, então rode essa lista à mão. O primeiro estágio
reconstrói a imagem sem cache, como a aula 2 arrumou:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/nightly
rebuild: passed in 13s
dast: WARNING in 30s, the end of dast.log:
  PASS: Sub Resource Integrity Attribute Missing [90003]
  PASS: Charset Mismatch [90011]
  PASS: Application Error Disclosure [90022]
  PASS: WSDL File Detection [90030]
  PASS: Loosely Scoped Cookie [90033]
  WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
  	http://linkbox-staging-17713-app:8000/search?q=ZAP (200 OK)
  FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
pipeline passed with 1 warning(s)
```

**O mesmo veredito de antes da mudança: um alerta da regra 10031**, o falso positivo que a aula 4
decidiu pela resposta, e todas as outras regras passando. É esse o resultado que importa aqui. O
linkbox rodou somente leitura, como o usuário 65532, sem capabilities e sem jeito de ganhar
nenhuma, durante todo um scan que pediu cada página que conseguiu achar, e nada falhou. **Se uma das
flags tivesse quebrado algo, é aqui que teria aparecido**, como um scan que não alcançou a aplicação,
que a aula 7 transformou em build quebrado em vez de aprovação silenciosa.

### Faça o commit

```
ana@vm:~/linkbox$ git commit -q -am "staging runs the image read-only, as nobody, with no capabilities"
2:09AM INF 0 commits scanned.
2:09AM INF scanned ~483 bytes (483 bytes) in 219ms
2:09AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 364671a        
remote: secrets: passed in 0s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: passed in 7s        
remote: build: passed in 1s        
remote: image: passed in 2s        
remote: push: passed in 1s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   425c3da..364671a  main -> main
```

O push roda o `ci/stages`, que não inclui a varredura dinâmica, então esta execução só prova que a
mudança não quebrou mais nada; a próxima execução noturna é a que a exercita. As linhas `INF` do hook
de pre-commit são a varredura de segredos da aula 6, como em todo commit.

### Para onde essas flags vão depois

Uma flag num script protege os contêineres que esse script inicia. O deploy real do linkbox, a partir
da aula 10, não é iniciado por um script e sim por um manifesto do Kubernetes, e cada flag desta aula
tem um campo lá:

| `docker run` | `securityContext` e spec do pod no Kubernetes |
|---|---|
| `USER` da imagem, conferido | `runAsNonRoot: true` |
| `--read-only` | `readOnlyRootFilesystem: true` |
| `--tmpfs /tmp`, `--tmpfs /data` | volumes `emptyDir` montados em `/tmp` e `/data` |
| `--cap-drop ALL` | `capabilities: {drop: ["ALL"]}` |
| `--security-opt no-new-privileges` | `allowPrivilegeEscalation: false` |
| perfil seccomp padrão do Docker | `seccompProfile: {type: RuntimeDefault}` |
| `--memory`, `--pids-limit` | `resources.limits.memory`; o limite de pids é definido por nó, pelo kubelet |

A diferença que importa é quem confere. Aqui as flags estão presentes porque o script diz, e outro
script poderia deixá-las de fora. Num cluster, a aula 10 faz o namespace recusar qualquer pod que as
deixe de fora, seja quem for que escreveu o manifesto.
