---
title: No pipeline, e de novo na porta do cluster
version: 1
---

As regras e os testes delas estão no commit. Falta rodá-las a cada push, e decidir em que ponto da
lista elas entram.

### O estágio

Salve como `ci/policy.sh`:

```sh
# Policy as code: this project's own rules, in policy/, over the files that
# say how linkbox is built and how it runs. The rules' own tests run first,
# so a rule that has stopped refusing what it was written to refuse breaks
# the build before it is trusted to pass anything.
set -euo pipefail
conftest verify --no-color
conftest test --no-color --namespace docker Dockerfile
conftest test --no-color --namespace kubernetes k8s/
```

Três comandos, e o `set -e` para no primeiro que falhar. Os testes vêm primeiro pelo motivo que as
seções anteriores deram: se uma regra não recusa mais o que foi escrita para recusar, as aprovações
dela não significam nada, e o build deve quebrar por isso antes de reportar qualquer uma. O
`--no-color` mantém códigos de escape fora do log; no seu terminal, deixe-o de fora e uma falha
aparece em vermelho.

O estágio lê três coisas do repositório e nada mais: nenhuma imagem, nenhuma rede, nenhum cluster.
Leva bem menos de um segundo, então o lugar dele é perto do começo da lista, depois dos dois estágios
que procuram segredos e arquivos de workflow inseguros e antes de qualquer coisa ser instalada ou
construída. Uma regra quebrada deve custar segundos ao autor, não os minutos que os estágios de imagem
levam. A lista, como `ci/stages`:

```
secrets
workflows
policy
test
sast
sca
build
image
push
sbom
sign
```

Onze estágios, a lista completa que a figura da aula 1 mostrou. Rode o estágio na sua máquina
primeiro, o mesmo script que o servidor roda (aula 2):

```
ana@vm:~/linkbox$ bash ci/policy.sh

18 tests, 18 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped

3 tests, 3 passed, 0 warnings, 0 failures, 0 exceptions

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
```

Faça o commit e o push:

```
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git commit -q -m "the policies on every push"
1:55AM INF 0 commits scanned.
1:55AM INF scanned ~448 bytes (448 bytes) in 172ms
1:55AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 8e4c80c        
remote: secrets: passed in 1s        
remote: workflows: FAILED in 0s, the end of workflows.log:        
remote:   bash: ci/workflows.sh: No such file or directory        
remote: run 1: failed, the logs are in ~/ci/runs/1/logs        
To /home/ana/ci/linkbox.git
   0979302..8e4c80c  main -> main
```

Todos os estágios passaram, `policy` entre eles, e cada linha do log dele fica no diretório da
execução como a de qualquer outro estágio.

### Uma mudança que o pipeline recusa

A política de admissão da aula 10 é a última checagem do cluster sobre todo Deployment. Suponha que
alguém está depurando um deploy recusado no fim do dia e muda o binding para `Warn`, para que uma
recusa vire uma mensagem e o deploy passe. A ideia é voltar depois. Num branch:

```
ana@vm:~/linkbox$ git switch -q -c debug-admission
ana@vm:~/linkbox$ sed -i 's/validationActions: \["Deny"\]/validationActions: ["Warn"]/' k8s/admission.yaml
ana@vm:~/linkbox$ git diff --unified=0
diff --git a/k8s/admission.yaml b/k8s/admission.yaml
index fbd2608..6ea106d 100644
--- a/k8s/admission.yaml
+++ b/k8s/admission.yaml
@@ -32 +32 @@ spec:
-  validationActions: ["Deny"]
+  validationActions: ["Warn"]
ana@vm:~/linkbox$ git commit -q -am "admission: warn while debugging"
1:55AM INF 0 commits scanned.
1:55AM INF scanned ~30 bytes (30 bytes) in 178ms
1:55AM INF no leaks found
ana@vm:~/linkbox$ git push ci debug-admission
remote: run 2: debug-admission at b892ec2        
remote: secrets: passed in 1s        
remote: workflows: FAILED in 0s, the end of workflows.log:        
remote:   bash: ci/workflows.sh: No such file or directory        
remote: run 2: failed, the logs are in ~/ci/runs/2/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      debug-admission -> debug-admission
```

A execução parou em `policy`, antes dos testes, do build ou de qualquer coisa demorada, e as últimas
linhas do log apontam o arquivo, a regra e a correção. Sem este estágio a mudança teria sido revisada
como um diff de uma palavra num arquivo YAML, e o cluster teria continuado aceitando todo Deployment,
com a política ainda instalada e listada pelo `kubectl` como se funcionasse.

Jogue o branch fora:

```
ana@vm:~/linkbox$ git switch -q main
ana@vm:~/linkbox$ git branch -D debug-admission
Deleted branch debug-admission (was b892ec2).
```

### Uma regra, checada duas vezes

A política recusa imagens de fora de `localhost:5000`, e a política de admissão da aula 10 também, no
cluster. A mesma decisão está escrita em duas linguagens, Rego e CEL, e é checada em dois lugares.
**Isso não é duplicação a remover; as duas checagens guardam portas diferentes.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"sp-l19-twice\" aria-label=\"Duas portas para uma regra. O commit de um desenvolvedor vai para o repositório, onde o estágio policy do pipeline roda o conftest sobre os arquivos e recusa o push antes de qualquer build. Qualquer requisição ao cluster, do pipeline ou de um laptop rodando kubectl apply, chega ao API server, onde a política de admissão recusa o objeto antes de ele ser gravado. O pipeline vê o commit e a revisão; a admissão vê todo objeto, venha de onde vier.\"><defs><marker id=\"sp-l19-twice-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l19-twice-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l19-twice-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"40\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um desenvolvedor</text><rect x=\"170\" y=\"40\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o repositório</text><text x=\"235.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">um commit</text><rect x=\"335\" y=\"32\" width=\"170\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pipeline: estágio policy</text><text x=\"420.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">conftest sobre os arquivos</text><path d=\"M135 63 L168 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-paper-dim)\"></path><path d=\"M300 63 L333 63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-paper-dim)\"></path><text x=\"420\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">vê: o commit, a revisão, o autor</text><rect x=\"15\" y=\"170\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"75.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um laptop</text><rect x=\"335\" y=\"162\" width=\"170\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">API server</text><text x=\"420.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">ValidatingAdmissionPolicy (CEL)</text><rect x=\"560\" y=\"170\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"632.5\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">gravado e agendado</text><path d=\"M505 193 L558 193\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-paper-dim)\"></path><path d=\"M505 63 L530 63 L530 140 L420 140 L420 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l19-twice-ah-phosphor)\"></path><text x=\"538\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">implanta</text><path d=\"M135 193 L333 193\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l19-twice-ah-amber)\"></path><text x=\"234\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">kubectl apply, por fora do pipeline</text><text x=\"420\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">vê: todo objeto, venha de onde vier</text></svg>", "caption": "O pipeline para o autor cedo e barato. O cluster para todo mundo, inclusive quem deu a volta no pipeline.", "same": ["API server", "ValidatingAdmissionPolicy (CEL)"]}
```

| | o pipeline (conftest) | o cluster (admissão) |
|---|---|---|
| quando roda | a cada push, antes de qualquer build | a cada criação ou atualização de um Deployment |
| o que vê | os arquivos do commit, como foram escritos | o objeto como chega ao API server, inclusive o que for acrescentado no caminho |
| o que não vê | um `kubectl apply` de um laptop, um manifesto que nunca passou pelo repositório, um objeto alterado à mão no cluster | a revisão: quem mudou a regra e por quê, e de que commit ela veio |
| quem ele para | o autor da mudança, com a mensagem no próprio pipeline | qualquer pessoa ou coisa com acesso ao cluster, inclusive um pipeline comprometido |
| quanto custa uma falha | segundos, e uma correção no mesmo branch | um deploy que falhou, percebido na hora do deploy |

O pipeline é a checagem cedo: barata, específica e dirigida a quem pode corrigir o problema. O
cluster é a última: ela vale mesmo quando o pipeline foi pulado, mal configurado ou subvertido, que é
o assunto da aula 16. Uma não substitui a outra. Uma regra imposta só no CI é uma convenção que
qualquer um com `kubectl` pode ignorar; uma regra imposta só na admissão é uma que todo desenvolvedor
encontra pela primeira vez na hora do deploy, tarde demais para ser barata.

Manter as duas em sintonia é o custo. Uma regra mudada num lugar e não no outro é uma brecha com cara
de cobertura. Dois hábitos mantêm isso honesto: mudar as duas no mesmo commit, já que o repositório do
linkbox guarda as duas, e deixar o pipeline checar as configurações da própria política de admissão,
como fazem as duas últimas regras de `policy/kubernetes.rego`, para a checagem do cluster não poder
ser enfraquecida sem o pipeline dizer.

O Gatekeeper roda o próprio OPA como controlador de admissão, então o mesmo Rego poderia servir às
duas portas. É uma escolha razoável numa plataforma maior. Este curso mantém CEL no cluster porque
ele vem embutido no Kubernetes e não exige instalar nada; o Gatekeeper está descrito aqui a partir da
documentação e não foi instalado.
