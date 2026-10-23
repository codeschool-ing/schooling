---
title: Trivy, um motor e várias portas de entrada
version: 1
---

A aula 8 usou o Trivy em imagens e a aula 5 num arquivo de requirements, o que pode deixar a
impressão de duas ferramentas que por acaso têm o mesmo nome. **O Trivy é um motor só, com várias
portas de entrada.** Todo modo faz as mesmas duas coisas: acha os registros do que está instalado (um
banco de pacotes do Debian, um arquivo `METADATA`, um lockfile) e os compara com um banco de
vulnerabilidades. O que muda entre os modos é só de onde vêm os arquivos.

| modo | lê | onde se encaixa |
|---|---|---|
| `image` | uma imagem, do Docker ou de um registry, camada por camada | o pipeline, depois do build |
| `rootfs` | um filesystem já desempacotado em disco | a raiz de uma máquina ou de um container, montada para inspeção |
| `fs` | um diretório de código: lockfiles, requirements, manifestos | o pipeline, antes do build; o editor |
| `sbom` | um bill of materials que alguém fez antes | depois, sem o artefato em si |
| `config` | Dockerfiles, manifestos do Kubernetes, Terraform | o pipeline, ao lado do código que os contém |
| `k8s` | um cluster vivo: workloads, imagens, configurações | numa agenda, contra o que está rodando |

O jeito de acreditar que é um motor só é dar a ele a mesma imagem por quatro portas diferentes e
observar a contagem. A primeira porta, a própria imagem:

```
ana@vm:~/linkbox$ trivy image -q --format json localhost:5000/linkbox:main | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "localhost:5000/linkbox:main (debian 13.7)",
    "n": 162
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

### Os mesmos arquivos, desempacotados

O `rootfs` lê um filesystem que já está em disco. É o que um scanner recebe quando lhe entregam um
disco montado ou a raiz de um container em vez de uma imagem, e você consegue fazer um a partir da
imagem do linkbox: crie um container sem iniciá-lo e exporte o filesystem dele.

```
ana@vm:~/linkbox$ mkdir -p ~/scratch/rootfs
ana@vm:~/linkbox$ docker create --name linkbox-rootfs localhost:5000/linkbox:main
0a1e3e40d9bf737d7a2cd5446d0e2755e59f386df54050e6004c2cb348a84f98
ana@vm:~/linkbox$ docker export linkbox-rootfs | tar -xf - -C ~/scratch/rootfs
ana@vm:~/linkbox$ docker rm linkbox-rootfs
linkbox-rootfs
ana@vm:~/linkbox$ ls ~/scratch/rootfs
app
bin
boot
data
dev
etc
home
lib
lib64
packages
proc
root
run
sbin
sys
tmp
usr
var
ana@vm:~/linkbox$ trivy rootfs -q --format json ~/scratch/rootfs | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "/home/ana/scratch/rootfs (debian 13.7)",
    "n": 162
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

Os mesmos 162 nos pacotes do Debian, e nada nos de Python. **Sem camadas, sem metadados da imagem, sem
registry, e a mesma resposta**, porque a resposta sempre esteve em dois lugares dentro desses
arquivos: `/var/lib/dpkg/status.d` para o Debian e os diretórios `dist-info` em `/packages` para o
Python.

### Os mesmos arquivos, descritos

O `sbom` escaneia uma lista de componentes em vez dos próprios arquivos. Peça ao Trivy que escreva essa
lista para a imagem em CycloneDX, um dos dois formatos que a aula 13 compara, e escaneie a lista:

```
ana@vm:~/linkbox$ trivy image -q --format cyclonedx -o ~/scratch/linkbox.cdx.json localhost:5000/linkbox:main
ana@vm:~/linkbox$ trivy sbom -q --format json ~/scratch/linkbox.cdx.json | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "/home/ana/scratch/linkbox.cdx.json (debian 13.7)",
    "n": 162
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

162 de novo, a partir de um arquivo sem imagem nenhuma por trás. Essa é a promessa de
um bill of materials, uma resposta a "somos afetados?" muito depois de a imagem sumir, e a aula 13
testa a promessa com uma lista feita por outra ferramenta.

### O código, antes do build

O `fs` lê o repositório como ele está, o que para o linkbox significa `requirements.txt`:

```
ana@vm:~/linkbox$ trivy fs -q --table-mode summary .

Report Summary

┌──────────────────┬──────┬─────────────────┬─────────┐
│      Target      │ Type │ Vulnerabilities │ Secrets │
├──────────────────┼──────┼─────────────────┼─────────┤
│ requirements.txt │ pip  │        0        │    -    │
└──────────────────┴──────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

**Zero está certo, e é um zero diferente do da imagem.** Ele diz que as versões fixadas que a aula 5
escolheu não têm aviso hoje. Não diz nada sobre os pacotes do Debian, que só existem depois que a
imagem base é baixada, então `fs` e `image` são duas checagens, e não uma checagem rodada duas vezes.

### O cluster, como ele roda

O `k8s` pergunta à API do Kubernetes o que está implantado, depois escaneia a imagem e as
configurações de cada workload. Com o cluster da aula 10 no ar e o linkbox aplicado:

```
ana@vm:~/linkbox$ kubectl get deployments -n linkbox
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
linkbox   0/1     0            0           0s
ana@vm:~/linkbox$ trivy k8s -q --include-namespaces linkbox --report summary

Summary Report for kind-linkbox
===============================

Workload Assessment
┌───────────┬────────────────────┬──────────────────────┬───────────────────┬───────────────────┐
│ Namespace │      Resource      │   Vulnerabilities    │ Misconfigurations │      Secrets      │
│           │                    ├───┬────┬────┬────┬───┼───┬───┬───┬───┬───┼───┬───┬───┬───┬───┤
│           │                    │ C │ H  │ M  │ L  │ U │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │
├───────────┼────────────────────┼───┼────┼────┼────┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
│ linkbox   │ Deployment/linkbox │   │ 26 │ 87 │ 49 │   │   │   │ 1 │ 3 │   │   │   │   │   │   │
└───────────┴────────────────────┴───┴────┴────┴────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN


Infra Assessment
┌───────────┬──────────┬───────────────────┬───────────────────┬───────────────────┐
│ Namespace │ Resource │  Vulnerabilities  │ Misconfigurations │      Secrets      │
│           │          ├───┬───┬───┬───┬───┼───┬───┬───┬───┬───┼───┬───┬───┬───┬───┤
│           │          │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │
└───────────┴──────────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN


RBAC Assessment
┌───────────┬──────────┬───────────────────┐
│ Namespace │ Resource │  RBAC Assessment  │
│           │          ├───┬───┬───┬───┬───┤
│           │          │ C │ H │ M │ L │ U │
└───────────┴──────────┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN
```

A coluna de vulnerabilidades é a imagem de novo: 26 altas, 87 médias e 49 baixas, que somam os mesmos
162. A coluna de misconfigurations, uma média e três baixas, é o que o `config` diz sobre o mesmo
Deployment na próxima seção. **O valor deste modo não é um achado novo, é a pergunta que ele
responde**: o que está rodando no cluster hoje, quem quer que tenha implantado e do jeito que for. Um
Deployment aplicado à mão no mês passado, com uma imagem que nunca passou pelo pipeline, aparece aqui e
em nenhum outro lugar. Isso faz do `k8s` o parente mais próximo de um scan de rede entre os scanners de
artefato, e ele pertence ao mesmo tipo de calendário.

O deployment mostra `0/1` pronto porque o scan rodou segundos depois do apply. O scan lê a
especificação do Deployment e baixa a imagem dele, então não precisa do pod rodando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"sp-l11-ways\" aria-label=\"Uma imagem entregue ao Trivy por quatro modos, e o repositório por um quinto. A imagem, o filesystem exportado dela, o bill of materials CycloneDX do Trivy e o Deployment no cluster kind dão cada um 162 achados do Debian. O requirements.txt do repositório dá 0, porque os pacotes do Debian só existem na imagem.\"><defs><marker id=\"sp-l11-ways-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy image</text><text x=\"185\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:main</text><path d=\"M345 38 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"20\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"64\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy rootfs</text><text x=\"185\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">~/scratch/rootfs</text><path d=\"M345 82 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"64\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"108\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy sbom</text><text x=\"185\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox.cdx.json</text><path d=\"M345 126 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"108\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy k8s</text><text x=\"185\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Deployment/linkbox</text><path d=\"M345 170 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"152\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"196\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy fs</text><text x=\"185\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requirements.txt</text><path d=\"M345 214 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"196\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">0</text><rect x=\"420\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um motor, um banco</text><text x=\"650\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">achados do Debian</text><path d=\"M570 125 L598 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path></svg>", "caption": "Quatro portas para os mesmos arquivos dão os mesmos 162. A quinta lê outros arquivos e responde outra pergunta."}
```

### Por que um motor só importa

Quando quatro portas dão a mesma contagem, uma diferença entre duas execuções significa que algo mudou
no artefato ou no banco, não na ferramenta. É isso que faz o SBOM guardado da aula 13 valer a pena. E
também marca o limite da garantia: a concordância vale entre os modos do próprio Trivy, lendo o banco
do próprio Trivy. Outra ferramenta, ou um SBOM escrito por outra ferramenta, é outra medição, e a
última seção desta aula mostra o quanto duas delas podem se afastar num único pacote.
