---
title: O que os containers de um pod compartilham
version: 1
---

**Um pod não é um container com outro nome.** É um pequeno grupo de containers que o kubelet sempre
inicia no mesmo nó e envolve nos mesmos namespaces, para eles se comportarem como processos numa
pequena máquina: uma interface de rede, um endereço, um hostname e os volumes que você der a eles. A
maioria dos pods tem um container só, e então a diferença é invisível. Este tem três, para ela
aparecer:

```schooling-example
{"language": "yaml", "file": "pod.yaml", "parts": [{"code": "apiVersion: v1\nkind: Pod\nmetadata:\n  name: web\n  labels:\n    app: web\n", "note": "**Um Pod solto**, escrito à mão, sem nada acima dele. O resto desta lição explica por que isso é incomum."}, {"code": "spec:\n  initContainers:\n  - name: greet\n    image: busybox:1.37\n    command: [\"sh\", \"-c\", \"echo 'hello from the init container' > /work/greeting\"]\n    volumeMounts:\n    - name: work\n      mountPath: /work\n", "note": "**Um container de inicialização roda primeiro, até terminar, antes de qualquer outro começar.** Este escreve um arquivo no volume compartilhado e sai."}, {"code": "  containers:\n  - name: shop\n    image: shop:1.0\n    env:\n    - name: CONFIG_FILE\n      value: /work/greeting\n    volumeMounts:\n    - name: work\n      mountPath: /work\n", "note": "**A loja**, avisada por `CONFIG_FILE` a ler a saudação do arquivo que o container de inicialização deixou, no mesmo caminho do mesmo volume."}, {"code": "  - name: sidecar\n    image: busybox:1.37\n    command: [\"sh\", \"-c\", \"while true; do wget -qO- localhost:8080; sleep 5; done\"]\n", "note": "**Um segundo container no mesmo pod.** Ele pede uma página à loja a cada cinco segundos, em `localhost`, porque os dois compartilham um namespace de rede."}, {"code": "  volumes:\n  - name: work\n    emptyDir: {}\n", "note": "**O volume que eles compartilham**, um `emptyDir`: criado vazio junto com o pod, no disco do nó, e apagado com ele."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f pod.yaml
pod/web created
ana@laptop:~/shop$ kubectl get pod web -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
web    2/2     Running   0          3s    10.244.1.2   shop-worker   <none>           <none>
```

`READY 2/2` conta os dois containers que ficam rodando. O container de inicialização não entra na
conta, porque não era para ele estar rodando; o próprio status diz que terminou:

```
ana@laptop:~/shop$ kubectl get pod web -o custom-columns=INIT:.status.initContainerStatuses[0].state.terminated.reason,IP:.status.podIP
INIT        IP
Completed   10.244.1.2
```

## Um endereço, um hostname

O log do sidecar são as respostas da loja, buscadas em `localhost`:

```
ana@laptop:~/shop$ kubectl logs web -c sidecar
shop 1.0 on web
shop 1.0 on web
```

**`localhost` dentro de um pod é o pod, não o container**, então o sidecar chega à porta 8080 da loja
sem saber endereço nenhum. Os dois containers também informam o mesmo hostname, o nome do pod:

```
ana@laptop:~/shop$ kubectl exec web -c sidecar -- hostname
web
```

O outro lado é que dois containers de um pod não podem escutar na mesma porta, exatamente como dois
programas numa máquina não podem.

## Um volume, dois containers

```
ana@laptop:~/shop$ kubectl exec web -c sidecar -- wget -qO- localhost:8080/config
GREETING=
/work/greeting: hello from the init container
```

A loja leu `/work/greeting`, um arquivo que ela nunca escreveu: o container de inicialização o
escreveu no `emptyDir` antes de a loja subir. `GREETING=` está vazio porque este pod não define essa
variável; a lição 13 a preenche a partir de um ConfigMap.

## Quando um segundo container pertence ao pod

Ponha dois containers num pod **só quando eles precisam viver e morrer juntos**: um ajudante que
prepara algo antes de a aplicação subir (um container de inicialização), ou um que serve a aplicação
de perto, compartilhando a rede ou os arquivos dela (um sidecar). Um banco de dados e a aplicação web
que o usa não são isso: escalam de jeitos diferentes, falham de jeitos diferentes e são atualizados
em momentos diferentes, então são dois Deployments, não dois containers de um pod.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O pod web, no nó shop-worker, desenhado como uma caixa com um endereço, 10.244.1.2, e um hostname, web. Dentro dele, o container de inicialização greet roda primeiro e sai, escrevendo um arquivo no volume emptyDir work. Depois shop e sidecar rodam lado a lado: o sidecar chega à loja em localhost:8080, e a loja lê o arquivo do mesmo volume.\"><defs><marker id=\"pod-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pod-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"40\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pod web · em shop-worker</text><text x=\"680\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.244.1.2</text><text x=\"680\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um endereço, um hostname</text><rect x=\"40\" y=\"80\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"115.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">greet</text><text x=\"115.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roda primeiro, depois sai</text><rect x=\"270\" y=\"80\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"355.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:8080</text><rect x=\"510\" y=\"80\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sidecar</text><text x=\"595.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wget</text><path d=\"M510 105 L442 105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pod-ah-paper-dim)\"></path><text x=\"476\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">localhost:8080</text><rect x=\"200\" y=\"196\" width=\"320\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work</text><text x=\"360.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">emptyDir, apagado com o pod</text><path d=\"M115 132 L115 218 L198 218\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pod-ah-amber)\"></path><text x=\"120\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">escreve a saudação</text><path d=\"M355 194 L355 132\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pod-ah-amber)\"></path><text x=\"362\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">lê a saudação</text></svg>", "caption": "Tudo dentro da linha tracejada é compartilhado: o endereço, o hostname, o volume. O container de inicialização termina antes de os outros dois começarem."}
```
