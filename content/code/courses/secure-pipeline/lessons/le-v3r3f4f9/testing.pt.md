---
title: Testando as próprias políticas
version: 1
---

Uma política que nunca dispara é idêntica a uma política satisfeita. As duas imprimem uma linha de
aprovações, as duas saem com 0, as duas deixam o pipeline seguir. **A falha contra a qual este curso
foi construído, uma checagem que em silêncio não aconteceu, é o jeito natural de uma política
quebrar**: um erro de digitação no nome de um campo, um auxiliar indefinido onde deveria ser falso,
uma refatoração que muda o que um padrão casa. Cada uma dessas transforma uma regra numa regra que
aprova tudo, e nada muda na tela.

Então uma política precisa de testes próprios, e Rego os tem embutidos.

### Como funciona um teste em Rego

Um teste é uma regra cujo nome começa com `test_`. Ele passa quando o corpo vale. Dentro dele,
`with input as ...` troca a entrada naquela avaliação, então um teste pode entregar às regras um
documento pequeno e inventado e afirmar o que sai: que `deny` está vazio para um bom, ou que contém uma
mensagem exata para um ruim. O `conftest verify` acha todos os testes do diretório de políticas e os
roda.

Os testes ficam ao lado das regras, num pacote próprio, e importam o pacote que testam. Salve os
testes das regras do Dockerfile como `policy/docker_test.rego`:

```
package docker_test

import data.docker

# A Dockerfile the rules accept: both images by digest, a numeric user.
good := [
	{"Cmd": "from", "Stage": 0, "Value": ["python:3.13-slim@sha256:57b2", "AS", "build"]},
	{"Cmd": "run", "Stage": 0, "Value": ["mkdir /data"]},
	{"Cmd": "from", "Stage": 1, "Value": ["gcr.io/distroless/python3-debian13:nonroot@sha256:727e"]},
	{"Cmd": "user", "Stage": 1, "Value": ["65532:65532"]},
]

test_good_dockerfile_passes if {
	count(docker.deny) == 0 with input as good
}

test_a_tag_is_refused if {
	bad := array.concat([{"Cmd": "from", "Stage": 0, "Value": ["python:3.13-slim"]}], array.slice(good, 1, 4))
	docker.deny["FROM python:3.13-slim: name the base image by digest (image@sha256:...)"] with input as bad
}

test_no_user_is_refused if {
	docker.deny["the final stage sets no USER: name a numeric user that is not root"] with input as array.slice(good, 0, 3)
}

# A USER in the build stage says nothing about the image that ships.
test_a_user_in_the_build_stage_does_not_count if {
	bad := array.concat(array.slice(good, 0, 1), [{"Cmd": "user", "Stage": 0, "Value": ["65532"]}, good[2]])
	count(docker.deny) == 1 with input as bad
}

test_root_by_number_is_refused if {
	bad := array.concat(array.slice(good, 0, 3), [{"Cmd": "user", "Stage": 1, "Value": ["0:0"]}])
	docker.deny["USER 0:0: use a numeric user other than 0, such as 65532"] with input as bad
}

test_a_user_name_is_refused if {
	bad := array.concat(array.slice(good, 0, 3), [{"Cmd": "user", "Stage": 1, "Value": ["nonroot"]}])
	docker.deny["USER nonroot: use a numeric user other than 0, such as 65532"] with input as bad
}
```

A entrada é uma lista de instruções escrita à mão, só com os campos que as regras leem. Cada teste
muda uma coisa no Dockerfile bom e espera uma mensagem específica. Afirmar a mensagem exata, e não só
que algo foi negado, pega uma regra que dispara pelo motivo errado.

O quarto teste é o que mais vale a pena ter. Um USER no estágio de build é fácil de escrever e não diz
nada sobre a imagem que vai para produção, e uma regra que juntasse todo USER sem olhar o estágio
aprovaria aquele Dockerfile. O teste espera exatamente uma mensagem, a do USER que falta, e falha se o
USER do estágio de build for contado.

E os testes dos manifestos como `policy/kubernetes_test.rego`:

```
package kubernetes_test

import data.kubernetes

# A container the rules accept, reduced to the fields they read, and the
# Deployment around it. Each test changes one thing and expects one message.
container := {
	"name": "linkbox",
	"image": "localhost:5000/linkbox:main",
	"securityContext": {"readOnlyRootFilesystem": true},
	"resources": {"limits": {"memory": "128Mi"}},
}

deployment(c, pod_security) := {
	"kind": "Deployment",
	"metadata": {"name": "linkbox"},
	"spec": {"template": {"spec": {"securityContext": pod_security, "containers": [c]}}},
}

good := deployment(container, {"runAsNonRoot": true})

test_the_good_deployment_passes if {
	count(kubernetes.deny) == 0 with input as good
}

test_root_is_refused if {
	kubernetes.deny["linkbox: container linkbox does not set runAsNonRoot: true"] with input as deployment(container, {})
}

# The container may say it for itself, and may also undo what the pod says.
test_the_container_can_set_it if {
	c := object.union(container, {"securityContext": {"runAsNonRoot": true}})
	count(kubernetes.deny) == 0 with input as deployment(c, {})
}

test_the_container_can_undo_it if {
	c := object.union(container, {"securityContext": {"runAsNonRoot": false}})
	kubernetes.deny["linkbox: container linkbox does not set runAsNonRoot: true"] with input as deployment(c, {"runAsNonRoot": true})
}

test_a_writable_root_is_refused if {
	c := object.union(container, {"securityContext": {"readOnlyRootFilesystem": false}})
	kubernetes.deny["linkbox: container linkbox does not set readOnlyRootFilesystem: true"] with input as deployment(c, {"runAsNonRoot": true})
}

# A request is not a limit: the container may still grow until the node runs out.
test_a_request_alone_is_refused if {
	c := object.union(object.remove(container, {"resources"}), {"resources": {"requests": {"memory": "64Mi"}}})
	kubernetes.deny["linkbox: container linkbox declares no memory limit"] with input as deployment(c, {"runAsNonRoot": true})
}

test_latest_is_refused if {
	c := object.union(container, {"image": "localhost:5000/linkbox:latest"})
	kubernetes.deny["linkbox: container linkbox uses localhost:5000/linkbox:latest; name a version or a digest"] with input as deployment(c, {"runAsNonRoot": true})
}

# localhost:5000 has a colon too; the tag is what follows the last slash.
test_no_tag_is_refused if {
	c := object.union(container, {"image": "localhost:5000/linkbox"})
	kubernetes.deny["linkbox: container linkbox uses localhost:5000/linkbox; name a version or a digest"] with input as deployment(c, {"runAsNonRoot": true})
}

test_a_digest_passes if {
	c := object.union(container, {"image": "localhost:5000/linkbox@sha256:2c1f"})
	count(kubernetes.deny) == 0 with input as deployment(c, {"runAsNonRoot": true})
}

test_another_registry_is_refused if {
	c := object.union(container, {"image": "docker.io/library/linkbox:main"})
	kubernetes.deny["linkbox: container linkbox pulls docker.io/library/linkbox:main; images come from localhost:5000"] with input as deployment(c, {"runAsNonRoot": true})
}

test_a_binding_that_only_warns_is_refused if {
	binding := {"kind": "ValidatingAdmissionPolicyBinding", "metadata": {"name": "linkbox-deployments"}, "spec": {"validationActions": ["Warn"]}}
	kubernetes.deny["linkbox-deployments: validationActions must include Deny"] with input as binding
}

test_a_policy_that_fails_open_is_refused if {
	policy := {"kind": "ValidatingAdmissionPolicy", "metadata": {"name": "linkbox-deployments"}, "spec": {"failurePolicy": "Ignore"}}
	kubernetes.deny["linkbox-deployments: failurePolicy must be Fail"] with input as policy
}
```

Mesmo formato: um contêiner bom e o Deployment em volta dele, montado por uma função para cada teste
poder mudar um campo. `object.union` mescla uma mudança no contêiner; `object.remove` tira um campo
antes quando o teste precisa que ele suma em vez de mudar.

### Rodando

```
ana@vm:~/linkbox$ conftest verify --no-color

18 tests, 18 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

18 testes, 6 para o Dockerfile e 12 para os manifestos. Eles rodam em bem menos de um segundo, e é
por isso que o estágio do pipeline pode rodá-los a cada push antes de rodar as regras.

### Um teste pegando o que nada mais pegaria

Eis o tipo de edição que quebra uma política em silêncio. Alguém lê `floating`, acha que olhar a parte
depois da última barra é preciosismo, e passa a procurar dois-pontos no nome inteiro da imagem. Parece
uma simplificação:

```
ana@vm:~/linkbox$ sed -i 's/not contains(parts\[count(parts) - 1\], ":")/not contains(image, ":")/' policy/kubernetes.rego
ana@vm:~/linkbox$ git diff --unified=0 policy/
diff --git a/policy/kubernetes.rego b/policy/kubernetes.rego
index 464cc0d..0f85bd5 100644
--- a/policy/kubernetes.rego
+++ b/policy/kubernetes.rego
@@ -56 +56 @@ floating(image) if {
-	not contains(parts[count(parts) - 1], ":")
+	not contains(image, ":")
ana@vm:~/linkbox$ conftest test --no-color --namespace kubernetes k8s/

35 tests, 35 passed, 0 warnings, 0 failures, 0 exceptions
ana@vm:~/linkbox$ conftest verify --no-color
FAIL - policy/kubernetes_test.rego -  - data.kubernetes_test.test_no_tag_is_refused

18 tests, 17 passed, 0 warnings, 1 failure, 0 exceptions, 0 skipped
```

Veja o que cada comando disse. **Contra os manifestos reais, a política quebrada continua aprovando os
35 testes**, porque a imagem do linkbox tem tag e a linha quebrada só importa para uma imagem sem tag.
Sem os testes, essa mudança entraria verde e a regra estaria morta a partir daquele dia:
`localhost:5000/linkbox` contém os dois-pontos da porta, então a regra quebrada nunca mais enxerga uma
imagem sem tag. O `conftest verify` aponta o único teste que conhece esse caso, e o comentário dele
diz por que ele existe.

Volte a linha, e os dois passam:

```
ana@vm:~/linkbox$ git checkout policy/kubernetes.rego
Updated 1 path from the index
ana@vm:~/linkbox$ conftest verify --no-color

18 tests, 18 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

### O que merece um teste

Escreva um teste para cada mensagem que uma regra pode produzir, para cada `deny` ser visto disparando
pelo menos uma vez. Depois um para cada caso que alguém erraria ao editar a regra: a configuração do
pod que um contêiner sobrepõe, os dois-pontos da porta de um registry, o USER no estágio errado. São
os testes dos arquivos acima, e cada um é um erro que de outro modo passaria em silêncio.

Faça o commit dos testes junto com as regras que eles testam:

```
ana@vm:~/linkbox$ git add policy
ana@vm:~/linkbox$ git commit -q -m "tests for the policies"
9:38AM INF 0 commits scanned.
9:38AM INF scanned ~5223 bytes (5.22 KB) in 249ms
9:38AM INF no leaks found
```
