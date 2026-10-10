---
title: Do que o Argo CD é feito
version: 1
---

**O Argo CD é o laço da aula 1 dividido em partes que precisam ser boas, cada uma, numa coisa só.**
O script em shell buscava, gerava, comparava e aplicava num processo só e não guardava nada. O Argo
CD dá cada um desses trabalhos a um componente próprio e guarda o estado dele como objetos do
Kubernetes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Os componentes do Argo CD: o repo server clona o Git e gera os manifestos, o application controller os compara com o cluster e aplica, o API server atende a interface web e a CLI, e o Redis faz cache para os dois.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"300\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"120\" width=\"110\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"75.0\" y=\"140.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git</text><text x=\"75.0\" y=\"158.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">fleet</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"265.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">repo server</text><text x=\"265.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">clonar e gerar</text><rect x=\"190\" y=\"200\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"265.0\" y=\"220.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Redis</text><text x=\"265.0\" y=\"238.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">cache</text><rect x=\"400\" y=\"120\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"485.0\" y=\"140.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">application controller</text><text x=\"485.0\" y=\"158.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">comparar e aplicar</text><rect x=\"610\" y=\"120\" width=\"90\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"655.0\" y=\"140.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">cluster</text><text x=\"655.0\" y=\"158.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">API</text><rect x=\"400\" y=\"230\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"485.0\" y=\"250.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">API server</text><text x=\"485.0\" y=\"268.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">web, CLI argocd</text><line x1=\"130\" y1=\"135\" x2=\"180.5\" y2=\"80.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"186,75 177.3,77.8 183.8,83.9\" fill=\"var(--paper-dim)\"/><line x1=\"340\" y1=\"75\" x2=\"412.9\" y2=\"112.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"420,116 414.9,108.3 410.8,116.4\" fill=\"var(--paper-dim)\"/><line x1=\"340\" y1=\"225\" x2=\"390.5\" y2=\"170.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"396,165 387.3,167.8 393.8,173.9\" fill=\"var(--paper-dim)\"/><line x1=\"570\" y1=\"145\" x2=\"598.0\" y2=\"145.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\"/><polygon points=\"606,145 598.0,140.5 598.0,149.5\" fill=\"var(--phosphor)\"/><line x1=\"485\" y1=\"226\" x2=\"485.0\" y2=\"182.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"485,174 480.5,182.0 489.5,182.0\" fill=\"var(--paper-dim)\"/><text x=\"600\" y=\"105\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--phosphor)\">o único que escreve</text><text x=\"190\" y=\"22\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">sem credenciais do cluster aqui</text></svg>", "caption": "As partes do Argo CD. Só o application controller escreve no cluster; o repo server, que roda o que um repositório pedir para gerar, nunca guarda as credenciais do cluster.", "same": ["Git", "fleet", "repo server", "Redis", "cache", "application controller", "cluster", "API", "API server"]}
```

- **O repo server** clona repositórios e transforma um caminho em manifestos simples. Para uma pasta
  de YAML isso é ler arquivos; para Kustomize ou Helm, de que a aula 6 trata, ele roda a ferramenta.
  Ele não tem credencial nenhuma do cluster, e isso importa, porque é o componente que roda o que um
  repositório pedir para gerar.
- **O application controller** é o laço. Para cada Application ele pede ao repo server os manifestos
  desejados, lê os objetos vivos do cluster, compara os dois e registra o resultado. Quando mandado,
  aplica a diferença. É o único componente com acesso de escrita ao cluster.
- **O API server** atende a interface web e o comando `argocd`. Ele não aplica nada; pede ao
  controller que aplique.
- **O Redis** guarda em cache o que o repo server gerou e o que o controller viu, para que uma
  comparação a cada poucos minutos não clone e gere tudo de novo.
- **O Dex**, o controlador de ApplicationSet e o controlador de notificações são partes opcionais:
  login único, gerar muitas Applications a partir de um modelo, e mandar mensagens quando algo
  acontece. A aula 5 usa um ApplicationSet; a aula 12, as notificações.

## A Application, a unidade de tudo

O Argo CD acrescenta um tipo de recurso ao cluster, `Application`, e **uma Application é uma seta de
um lugar no Git para um lugar no cluster**: este repositório, nesta revisão, neste caminho, vai para
este namespace deste cluster. Tudo o que o Argo CD informa é informado por Application: se está
sincronizada, se está saudável, em que commit está, o que fez e quando.

Como uma Application é ela própria um objeto do Kubernetes, ela pode ser descrita em YAML e guardada
no Git como qualquer outra coisa. O fim desta aula faz exatamente isso, e o Argo CD termina cuidando
da própria lista de aplicações a partir do repositório.
