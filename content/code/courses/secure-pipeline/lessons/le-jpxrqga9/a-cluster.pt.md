---
title: Um cluster que puxa do seu registry
version: 1
---

As aulas 8 e 9 endureceram uma imagem e o jeito de rodá-la, e as duas ainda dependem de alguém
digitar o `docker run` certo. **Um cluster transforma essas flags em regras que valem para todo mundo
que faz deploy nele**, e é isso que esta aula monta. O cluster é o kind, Kubernetes em contêineres
Docker, o mesmo que a aula 5 de `kubernetes` montou e usou dali em diante; aqui ele tem uma tarefa a
mais, puxar o linkbox do registry da sua máquina em vez da internet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l10-network\" aria-label=\"A sua máquina roda o contêiner do registry, publicado em 127.0.0.1:5000, para onde o pipeline envia. O nó do kind é outro contêiner, na rede kind do Docker. O contêiner do registry também entra nessa rede. Dentro do nó, o containerd lê o hosts.toml, que diz que o nome localhost:5000 é alcançado em http://registry:5000, então o nó puxa localhost:5000/linkbox:main do contêiner do registry.\"><defs><marker id=\"sp-l10-network-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l10-network-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a sua máquina</text><rect x=\"30\" y=\"60\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/push.sh</text><text x=\"125.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">localhost:5000/linkbox</text><rect x=\"270\" y=\"45\" width=\"425\" height=\"220\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"285\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">rede do Docker: kind</text><rect x=\"290\" y=\"80\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">contêiner do registry</text><text x=\"375.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:5000</text><rect x=\"500\" y=\"80\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nó do kind</text><text x=\"590.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linkbox-control-plane</text><rect x=\"500\" y=\"170\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hosts.toml</text><text x=\"590.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">localhost:5000 → registry:5000</text><path d=\"M220 88 L288 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-network-ah-phosphor)\"></path><path d=\"M498 108 L462 108\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-network-ah-amber)\"></path><text x=\"480\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">puxa</text><path d=\"M590 168 L590 138\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-network-ah-amber)\"></path><text x=\"375\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">docker network connect</text></svg>", "caption": "Um nome só, localhost:5000/linkbox, dos dois lados. No nó, um arquivo diz onde esse nome de fato está."}
```

### O que está no registry

O pipeline envia a cada execução, e o push da aula 9 deixou `main` apontando para a imagem mais
recente:

```
ana@vm:~$ cd ~/linkbox
ana@vm:~/linkbox$ curl -s http://localhost:5000/v2/linkbox/tags/list
{"name":"linkbox","tags":["8bd2e60","main"]}
```

### A configuração do cluster

O kind roda cada nó do Kubernetes como um contêiner Docker, e dentro dele o `containerd` puxa as
imagens. Dizer ao containerd onde fica um registry é um arquivo por registry em
`/etc/containerd/certs.d`, e a configuração do kind só precisa ligar esse diretório. Salve como
`~/kind.yaml`:

```yaml
# The study cluster: one node, which pulls localhost:5000/... from the
# registry container on this machine.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
```

**O primeiro patch é o que importa**: ele faz o containerd ler o `certs.d`. Os outros dois estão ali
por causa da máquina em que este curso foi gravado, que tem cgroup v1 e proíbe um processo de baixar
a própria pontuação de OOM; a aula 5 de `kubernetes` encontrou os mesmos dois. Num Linux atual com
cgroup v2, no Docker Desktop ou num Codespace, apague os dois, e se o cluster não subir sem eles, o
`kind create cluster` imprime o motivo nas últimas linhas.

```
ana@vm:~/linkbox$ kind create cluster --name linkbox --config ~/kind.yaml
cgroup v1 is deprecated in Kubernetes and will not be supported in a future kind release, please upgrade to cgroup v2
Creating cluster "linkbox" ...
 • Ensuring node image (kindest/node:v1.37.0) 🖼️  ...
 ✓ Ensuring node image (kindest/node:v1.37.0) 🖼️
 • Preparing nodes 📦   ...
 ✓ Preparing nodes 📦 
 • Writing configuration 📜  ...
 ✓ Writing configuration 📜
 • Starting control-plane 🕹️  ...
 ✓ Starting control-plane 🕹️
 • Installing CNI 🔌  ...
 ✓ Installing CNI 🔌
 • Installing StorageClass 💾  ...
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-linkbox"
You can now use your cluster with:

kubectl cluster-info --context kind-linkbox

Thanks for using kind! 😊
```

A primeira linha é o aviso do próprio kind sobre o cgroup v1, o motivo do terceiro patch, e tudo o
que vem depois é um cluster subindo. O nó precisa de mais alguns segundos para se declarar pronto, e
os próximos comandos esperam por isso.

### Ensinando ao nó onde fica `localhost:5000`

Dentro do nó, `localhost` é o próprio nó, e não a sua máquina, então `localhost:5000` apontaria para o
nada. A correção é a que a documentação do kind dá para um registry local, em duas partes: um
`hosts.toml` que diz "para `localhost:5000`, pergunte a `http://registry:5000`", e o contêiner do
registry ligado à rede em que o nó está, para o nome `registry` resolver:

```
ana@vm:~/linkbox$ docker exec linkbox-control-plane mkdir -p /etc/containerd/certs.d/localhost:5000
ana@vm:~/linkbox$ printf '[host."http://registry:5000"]\n' | docker exec -i linkbox-control-plane cp /dev/stdin /etc/containerd/certs.d/localhost:5000/hosts.toml
ana@vm:~/linkbox$ docker network connect kind registry
ana@vm:~/linkbox$ kubectl wait --for=condition=Ready node --all --timeout=180s
node/linkbox-control-plane condition met
ana@vm:~/linkbox$ kubectl get nodes
NAME                    STATUS   ROLES           AGE   VERSION
linkbox-control-plane   Ready    control-plane   21s   v1.37.0
```

**A imagem mantém o nome com que foi enviada**, `localhost:5000/linkbox:main`, na sua máquina e no
cluster, e só o nó sabe que, para ele, esse nome quer dizer um contêiner chamado `registry`. Isso
importa para a regra de admissão desta aula, que confere nomes de imagem: o nome é o mesmo em todo
lugar onde aparece. `http://` é aceitável pelo mesmo motivo da aula 8; o tráfego nunca sai desta
máquina.

Um cluster que puxa de um registry em outro lugar precisa dos mesmos dois fatos, um endereço e um
jeito de confiar nele, e um de verdade acrescenta credenciais: um pull secret, ou uma identidade do
nó que o registry aceite. Essa parte não roda aqui, porque este registry não pede nenhuma.

### Quando o cluster não é necessário

O cluster é a coisa mais pesada que o curso roda depois do ZAP. `kind delete cluster --name linkbox`
o remove, o registry e as imagens dele ficam, e os comandos desta seção o montam de novo em um
minuto.
