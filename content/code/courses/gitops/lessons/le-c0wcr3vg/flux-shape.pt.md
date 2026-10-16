---
title: O Flux é um conjunto de controladores
version: 1
---

**O Argo CD tem uma ideia central, a Application. O Flux tem várias pequenas, cada uma um tipo de
recurso com um controlador próprio**, e um deploy é o que se obtém encadeando-as. A divisão segue a
mesma linha que a aula 3 traçou dentro do Argo CD, entre buscar e aplicar, e a torna visível nos
objetos que você escreve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"A cadeia do Flux: um GitRepository é buscado pelo source controller e vira um artefato; uma Kustomization pega um caminho desse artefato, e o kustomize controller o monta e aplica no cluster. O notification controller recebe webhooks que fazem o source controller buscar na hora.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"280\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"110\" width=\"110\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"75.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"75.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">fleet</text><rect x=\"170\" y=\"110\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"245.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">GitRepository</text><text x=\"245.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">source controller</text><rect x=\"360\" y=\"110\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"435.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">artefato</text><text x=\"435.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">arquivos de uma revisão</text><rect x=\"550\" y=\"110\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"625.0\" y=\"130.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Kustomization</text><text x=\"625.0\" y=\"148.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">kustomize controller</text><rect x=\"550\" y=\"210\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"625.0\" y=\"230.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><text x=\"625.0\" y=\"248.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">objetos</text><rect x=\"170\" y=\"20\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"245.0\" y=\"40.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Receiver</text><text x=\"245.0\" y=\"58.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">notification controller</text><line x1=\"130\" y1=\"135\" x2=\"158.0\" y2=\"135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"166,135 158.0,130.5 158.0,139.5\" fill=\"var(--paper-dim)\"/><line x1=\"320\" y1=\"135\" x2=\"348.0\" y2=\"135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"356,135 348.0,130.5 348.0,139.5\" fill=\"var(--paper-dim)\"/><line x1=\"510\" y1=\"135\" x2=\"538.0\" y2=\"135.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"546,135 538.0,130.5 538.0,139.5\" fill=\"var(--paper-dim)\"/><line x1=\"625\" y1=\"160\" x2=\"625.0\" y2=\"198.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\"/><polygon points=\"625,206 629.5,198.0 620.5,198.0\" fill=\"var(--phosphor)\"/><line x1=\"245\" y1=\"70\" x2=\"245.0\" y2=\"98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"245,106 249.5,98.0 240.5,98.0\" fill=\"var(--paper-dim)\"/><text x=\"330\" y=\"48\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">um push: buscar agora</text><text x=\"20\" y=\"250\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">a cada minuto: buscar</text><text x=\"360\" y=\"250\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">a cada dez minutos: aplicar</text></svg>", "caption": "A cadeia de objetos do Flux. Buscar e aplicar são dois recursos com dois intervalos, e só o kustomize controller escreve no cluster.", "same": ["Git", "fleet", "GitRepository", "source controller", "Kustomization", "kustomize controller", "cluster", "Receiver", "notification controller"]}
```

- **O source controller** busca. Um `GitRepository` diz: clone este repositório, neste branch, a
  cada minuto. O controlador faz isso e guarda o resultado dentro do cluster como um **artefato**,
  uma cópia compactada dos arquivos numa revisão, que outros controladores baixam. `OCIRepository`,
  `HelmRepository` e `Bucket` são a mesma ideia para outros lugares onde o estado desejado pode morar.
- **O kustomize controller** aplica. Uma `Kustomization` (o recurso do Flux, que não se confunde com o
  arquivo `kustomization.yaml` do Kustomize) diz: pegue este caminho do artefato daquela fonte,
  monte com o Kustomize e aplique, a cada dez minutos, podando o que sumiu. É o application
  controller da aula 3, e o único destes que escreve objetos comuns no cluster.
- **O helm controller** instala charts do Helm como releases do Helm de verdade, a partir de um
  `HelmRelease`. A aula 6 o usa.
- **O notification controller** manda eventos para fora, para um chat ou para o status de commit de
  um servidor Git, e recebe webhooks, para que um push dispare uma busca na hora. Esta aula monta um.
- **Os controladores de imagem**, opcionais, observam um registry atrás de tags novas e escrevem a
  tag nova de volta no Git. A aula 7 é o lugar deles.

Não há interface web, nem API server próprio, nem usuários: **a interface do Flux é a API do
Kubernetes**. Tudo o que ele sabe está no status dos objetos dele, que o `kubectl` e o comando `flux`
leem. Isso o deixa menor e deixa as perguntas de quem pode fazer o quê para as permissões do próprio
Kubernetes, que são o assunto da aula 11.
