---
title: Os manifestos, e uma violação pega
version: 1
---

A aula 10 escreveu os manifestos de Kubernetes do linkbox com um contexto de segurança campo a campo:
um pod que se recusa a rodar como root, um sistema de arquivos raiz só de leitura, um limite de
memória, uma imagem do registry do próprio projeto. O Pod Security Admission e a política de admissão
então impõem parte disso no cluster. **Esta política checa os mesmos manifestos antes de eles chegarem
a qualquer cluster**, no commit que os altera, onde quem quebrou uma regra é quem lê a mensagem.

### A entrada, e o que ela acrescenta

`k8s/linkbox.yaml` tem três documentos (um Namespace, um Deployment e um Service) e
`k8s/admission.yaml` mais dois. O conftest entrega cada documento às regras separadamente, então
`input` é um objeto de Kubernetes por vez, com `kind`, `metadata` e `spec` exatamente como foram
escritos. Uma regra sobre Deployments começa conferindo `input.kind` e não faz nada com os outros
quatro.

Salve isto como `policy/kubernetes.rego`:

```
package kubernetes

# Rules for the manifests in k8s/. conftest hands each YAML document to
# these rules separately, so input is one object: a Namespace, a
# Deployment, a Service or an admission policy.

deployment if input.kind == "Deployment"

pod := input.spec.template.spec if deployment

containers contains c if {
	some c in pod.containers
}

# Pod Security Admission refuses a pod that may run as root; saying so here
# refuses it before it reaches a cluster. The pod's securityContext counts
# for every container, and a container's own overrides it.
deny contains msg if {
	some c in containers
	not runs_as_non_root(c)
	msg := sprintf("%s: container %s does not set runAsNonRoot: true", [input.metadata.name, c.name])
}

runs_as_non_root(c) if c.securityContext.runAsNonRoot == true

runs_as_non_root(c) if {
	not c.securityContext.runAsNonRoot == false
	pod.securityContext.runAsNonRoot == true
}

deny contains msg if {
	some c in containers
	not c.securityContext.readOnlyRootFilesystem == true
	msg := sprintf("%s: container %s does not set readOnlyRootFilesystem: true", [input.metadata.name, c.name])
}

deny contains msg if {
	some c in containers
	not c.resources.limits.memory
	msg := sprintf("%s: container %s declares no memory limit", [input.metadata.name, c.name])
}

# An image is named by a tag that is not latest, or by digest. A name with
# no tag at all means latest.
deny contains msg if {
	some c in containers
	floating(c.image)
	msg := sprintf("%s: container %s uses %s; name a version or a digest", [input.metadata.name, c.name, c.image])
}

floating(image) if endswith(image, ":latest")

floating(image) if {
	not contains(image, "@")
	parts := split(image, "/")
	not contains(parts[count(parts) - 1], ":")
}

# The same rule the cluster's admission policy enforces, checked here too.
deny contains msg if {
	some c in containers
	not startswith(c.image, "localhost:5000/")
	msg := sprintf("%s: container %s pulls %s; images come from localhost:5000", [input.metadata.name, c.name, c.image])
}

# The admission policy itself. A binding that only warns or audits lets
# every Deployment through, and nothing on the cluster says so; a policy
# that fails open lets them through whenever it cannot be evaluated.
# Kubernetes takes a missing failurePolicy as Fail.
deny contains msg if {
	input.kind == "ValidatingAdmissionPolicyBinding"
	not "Deny" in input.spec.validationActions
	msg := sprintf("%s: validationActions must include Deny", [input.metadata.name])
}

deny contains msg if {
	input.kind == "ValidatingAdmissionPolicy"
	input.spec.failurePolicy != "Fail"
	msg := sprintf("%s: failurePolicy must be Fail", [input.metadata.name])
}
```

Quase tudo tem o formato da seção anterior: um auxiliar que separa o que as regras olham, aqui cada
contêiner do template de pod de um Deployment, e uma regra `deny` por decisão. Três detalhes merecem
leitura atenta.

**`runs_as_non_root` está escrito duas vezes.** Duas definições do mesmo auxiliar são alternativas:
ele vale se o próprio contêiner diz `runAsNonRoot: true`, ou se o contêiner não diz `false` e o pod
diz `true`. É assim que o Kubernetes resolve os dois níveis, a configuração do contêiner sobrepondo a
do pod, e uma política que checasse só o nível do pod aprovaria um contêiner que a desligou em
silêncio.

**`floating` lê a tag depois da última barra.** `localhost:5000/linkbox` contém dois-pontos, na porta
do registry, e mesmo assim não tem tag, o que significa `latest` para quem a puxar. Procurar
dois-pontos na string inteira a aprovaria. Os testes da próxima seção fixam esse caso.

**As duas últimas regras checam a própria política de admissão.** Um `ValidatingAdmissionPolicyBinding`
cujas `validationActions` dizem `Warn` ou `Audit` em vez de `Deny` continua sendo instalado, continua
aparecendo no `kubectl get`, e deixa todo Deployment passar. Uma política cujo `failurePolicy` é
`Ignore` os deixa passar sempre que não consegue ser avaliada. As duas são edições de uma palavra, e
nenhuma mostra sintoma no cluster. São exatamente o tipo de mudança que uma revisão deixa passar e uma
regra não.

Mais uma regra repete uma regra que a aula 10 já impõe na admissão: as imagens vêm de
`localhost:5000`. Essa duplicação é proposital, e a última seção desta aula a defende.

### Rodando

```
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
```

Sete regras contra cinco documentos: 35 testes, todos aprovados. Os manifestos do linkbox já fazem
tudo o que essas regras pedem, o que é de se esperar depois da aula 10, e é o estado normal de uma
política: **ela é escrita para passar hoje e falhar no dia em que alguém mudar alguma coisa.**

### Uma mudança que quebra três regras

Para vê-la falhar, faça o tipo de edição que chega com pressa: o contêiner não consegue gravar um
arquivo de cache, então alguém torna o sistema de arquivos raiz gravável, e para testar um build local
aponta a imagem para `linkbox:latest`. O `sed` faz as duas edições, e o `git diff` as mostra como um
revisor as veria:

```
ana@vm:~/linkbox$ sed -i 's/readOnlyRootFilesystem: true/readOnlyRootFilesystem: false/; s|localhost:5000/linkbox:main|linkbox:latest|' k8s/linkbox.yaml
ana@vm:~/linkbox$ git diff --unified=0 k8s/
diff --git a/k8s/linkbox.yaml b/k8s/linkbox.yaml
index 9fd9a17..276b8ea 100644
--- a/k8s/linkbox.yaml
+++ b/k8s/linkbox.yaml
@@ -34 +34 @@ spec:
-          image: localhost:5000/linkbox:main
+          image: linkbox:latest
@@ -45 +45 @@ spec:
-            readOnlyRootFilesystem: true
+            readOnlyRootFilesystem: false
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/
FAIL - k8s/linkbox.yaml - kubernetes - linkbox: container linkbox does not set readOnlyRootFilesystem: true
FAIL - k8s/linkbox.yaml - kubernetes - linkbox: container linkbox pulls linkbox:latest; images come from localhost:5000
FAIL - k8s/linkbox.yaml - kubernetes - linkbox: container linkbox uses linkbox:latest; name a version or a digest

35 tests, 32 passed, 0 warnings, 3 failures, 0 exceptions
```

Três mensagens para duas linhas alteradas. A mudança da imagem quebra duas regras de uma vez, a da tag
e a do registry, e cada mensagem diz qual contêiner e o que fazer. Um revisor olhando o diff vê duas
linhas pequenas; a política vê três decisões revertidas.

Volte o arquivo ao que era, e a política passa de novo:

```
ana@vm:~/linkbox$ git checkout k8s/linkbox.yaml
Updated 1 path from the index
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
```

### Faça o commit das políticas

A mudança do Dockerfile e as duas políticas vão num commit só, para a regra e a linha que ela exige
chegarem juntas:

```
ana@vm:~/linkbox$ git add Dockerfile policy
ana@vm:~/linkbox$ git commit -q -m "policy as code: the Dockerfile and the manifests"
9:38AM INF 0 commits scanned.
9:38AM INF scanned ~4406 bytes (4.41 KB) in 202ms
9:38AM INF no leaks found
```

As três linhas depois do commit são o hook de pre-commit da aula 6 varrendo os arquivos preparados em
busca de segredos, como faz a cada commit daqui em diante. Nada roda essas regras num push ainda; a
última seção desta aula acrescenta o estágio. Antes, as regras precisam de testes próprios, porque uma
política tem o mesmo modo de falha de qualquer outra checagem deste curso: ela pode parar de funcionar
e continuar passando.
