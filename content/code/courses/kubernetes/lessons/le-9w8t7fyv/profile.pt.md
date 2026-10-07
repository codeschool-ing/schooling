---
title: Um scheduler é uma configuração
version: 1
---

A lição 29 dirigiu pods com seletores e afinidade, tudo escrito no pod. O scheduler que lia essas regras
tem regras próprias, e **elas são um arquivo**. Cada decisão que ele toma é um ciclo de plugins, e a
configuração dele diz quais plugins rodam e quanto cada um conta:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"O ciclo de agendamento de um pod, da esquerda para a direita. Uma fila de pods sem nó. Plugins de filtro removem os nós onde o pod não pode rodar, por exemplo o NodeResourcesFit quando falta CPU. Plugins de pontuação dão um número a cada nó que sobrou, e as configurações do perfil decidem quanto cada plugin conta. A maior pontuação ganha e a associação é escrita no API server. Um extender, se configurado, é chamado por HTTP depois dos plugins dos passos de filtro e de pontuação.\"><defs><marker id=\"cyc-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"60\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"81.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">queue</text><text x=\"81.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pods sem nó</text><rect x=\"190\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Filtro</text><text x=\"265.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nós onde não pode rodar saem</text><rect x=\"380\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Pontuação</text><text x=\"455.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cada nó ganha um número</text><rect x=\"570\" y=\"60\" width=\"134\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"637.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Bind</text><text x=\"637.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nodeName é escrito</text><path d=\"M148 88 L188 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cyc-ah-paper-dim)\"></path><path d=\"M342 88 L378 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cyc-ah-paper-dim)\"></path><path d=\"M532 88 L568 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cyc-ah-paper-dim)\"></path><rect x=\"190\" y=\"150\" width=\"340\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">extender: uma chamada HTTP depois do filtro e da pontuação</text><path d=\"M265 118 L265 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M455 118 L455 148\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um perfil liga e desliga plugins e define os pesos deles</text></svg>", "caption": "Cada passo é um conjunto de plugins. Um perfil do scheduler escolhe quais rodam e quanto cada pontuação conta.", "same": ["Bind"]}
```

O padrão favorece espalhar. Entre os nós que passam pelos filtros, o `NodeResourcesFit` prefere o
**menos** pedido, então um pod novo tende a ir para onde há mais espaço. Isso é bom para um serviço que
quer sobreviver à queda de um nó, e errado para um lote de trabalho que preferiria encher dois nós e
deixar um autoscaler remover o terceiro.

Raramente se troca o scheduler por isso. Dá-se ao mesmo programa um segundo **perfil**, com um nome
próprio:

```schooling-example
{"language": "yaml", "file": "shop-scheduler.yaml", "parts": [{"code": "apiVersion: kubescheduler.config.k8s.io/v1\nkind: KubeSchedulerConfiguration\nclientConnection:\n  kubeconfig: /home/ana/.kube/config\nleaderElection:\n  leaderElect: false\n", "note": "**Como ele chega ao API server**, e sem eleição de líder: existe uma cópia dele, no laptop."}, {"code": "profiles:\n- schedulerName: shop-scheduler\n", "note": "**O nome do perfil é o nome do scheduler.** Um pod que define `schedulerName: shop-scheduler` é deste perfil; todos os outros são ignorados."}, {"code": "  plugins:\n    score:\n      disabled:\n      - name: NodeResourcesBalancedAllocation\n      - name: PodTopologySpread\n", "note": "**Dois plugins de pontuação desligados.** Os dois vêm ligados por padrão e os dois favorecem espalhar a carga, o oposto do propósito deste perfil."}, {"code": "  pluginConfig:\n  - name: NodeResourcesFit\n    args:\n      scoringStrategy:\n        type: MostAllocated\n        resources:\n        - name: cpu\n          weight: 1\n        - name: memory\n          weight: 1\n", "note": "**O empacotamento em si.** O `NodeResourcesFit` pontua um nó por quanto dele está pedido; o `MostAllocated` inverte o padrão, e o nó mais cheio ganha."}]}
```

```
```

O `kube-scheduler` é o mesmo binário que o control plane roda. Aqui ele roda na sua máquina ao lado do
`kubectl`, baixado e conferido do jeito que a aula 1 fez, e iniciado num segundo terminal, onde continua
rodando e escrevendo o log até o `Ctrl+C`. Antes, troque o caminho do `kubeconfig` no arquivo pela sua
própria home, `/home/ubuntu/.kube/config` na VM:

```sh
ARCH=$(dpkg --print-architecture)
curl -fsSLo kube-scheduler https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kube-scheduler
echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kube-scheduler.sha256)  kube-scheduler" | sha256sum --check
chmod +x kube-scheduler
./kube-scheduler --config shop-scheduler.yaml --secure-port=0
```

O `--secure-port=0` desliga a porta própria de saúde e métricas, que ninguém lê aqui. **Um de verdade roda no
cluster**, como um Deployment com uma ServiceAccount autorizada a ler pods e nós e a escrever bindings, e
com eleição de líder ligada para uma segunda réplica poder assumir.

O scheduler do próprio cluster poderia levar este perfil ao lado do `default-scheduler`, já que uma
configuração pode listar vários. Um cluster gerenciado não deixa editar esse arquivo, e é aí que um
segundo programa é o caminho. Alguns segundos programas são outros schedulers por inteiro, como o
Volcano, feito para jobs em lote que precisam de todos os pods posicionados de uma vez ou de nenhum.
