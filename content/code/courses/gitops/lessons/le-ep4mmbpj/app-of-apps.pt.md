---
title: Applications no Git, também
version: 1
---

**A Application vive em `~/setup`, na sua máquina, aplicada à mão**, que é exatamente a situação que
este curso vem tirando de todo o resto. Se o seu notebook sumir, ninguém mais sabe como o staging
está ligado ao repositório. A correção é a óbvia: pôr a Application no `fleet` e deixar o Argo CD
aplicá-la.

Isso pede uma Application aplicada à mão, uma vez, cujo trabalho é aplicar as outras. Ela se chama
**app de apps**, ou raiz. Salve isto como `~/setup/root.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitea:3000/ana/fleet.git
    targetRevision: main
    path: argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Ela aponta para uma pasta `argocd/` no `fleet`, e todo manifesto de Application nessa pasta é um dos
objetos dela. Leve a Application do staging para lá, por um pull request, e aplique a raiz:

```
ana@laptop:~/fleet$ git switch --quiet -c app-of-apps
ana@laptop:~/fleet$ mkdir argocd && cp ~/setup/bulletin-staging.yaml argocd/
ana@laptop:~/fleet$ git add argocd
ana@laptop:~/fleet$ git commit --quiet -m "argocd: the staging application lives in Git"
ana@laptop:~/fleet$ kubectl apply -f ~/setup/root.yaml
application.argoproj.io/root created
ana@laptop:~/fleet$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    default  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  staging  main
argocd/root              https://kubernetes.default.svc  argocd     default  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  argocd   main
```

As duas estão `Synced`. A raiz achou o `argocd/bulletin-staging.yaml` no Git, comparou com a
Application que já existia e a adotou. Daqui em diante, **acrescentar uma aplicação ao cluster é um
pull request que acrescenta um arquivo em `argocd/`**, e remover uma é um pull request que o apaga,
com a poda da seção anterior fazendo o resto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 260\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"O app de apps. Uma Application root, aplicada uma vez à mão, aponta para a pasta argocd no Git. Essa pasta guarda a Application bulletin-staging, que aponta para a pasta staging, cujos objetos vão para o namespace staging.\"><rect x=\"0\" y=\"0\" width=\"640\" height=\"260\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"30\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"105.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">root</text><text x=\"105.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">aplicada uma vez, à mão</text><rect x=\"240\" y=\"30\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"325.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">fleet/argocd/</text><text x=\"325.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">arquivos de Application</text><rect x=\"240\" y=\"140\" width=\"170\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"325.0\" y=\"160.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">bulletin-staging</text><text x=\"325.0\" y=\"178.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">uma Application</text><rect x=\"460\" y=\"140\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"540.0\" y=\"160.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">fleet/staging/</text><text x=\"540.0\" y=\"178.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">manifestos</text><rect x=\"460\" y=\"30\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"540.0\" y=\"50.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">namespace staging</text><text x=\"540.0\" y=\"68.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">os objetos</text><line x1=\"190\" y1=\"55\" x2=\"228.0\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"236,55 228.0,50.5 228.0,59.5\" fill=\"var(--paper-dim)\"/><line x1=\"325\" y1=\"80\" x2=\"325.0\" y2=\"128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"325,136 329.5,128.0 320.5,128.0\" fill=\"var(--paper-dim)\"/><line x1=\"410\" y1=\"165\" x2=\"448.0\" y2=\"165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"456,165 448.0,160.5 448.0,169.5\" fill=\"var(--paper-dim)\"/><line x1=\"540\" y1=\"140\" x2=\"540.0\" y2=\"92.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"540,84 535.5,92.0 544.5,92.0\" fill=\"var(--phosphor)\"/><text x=\"320\" y=\"240\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">tudo abaixo da root está no Git</text></svg>", "caption": "Uma Application aplicada à mão, e todo o resto lido do repositório. Acrescentar ou remover uma aplicação é um pull request em fleet/argocd/.", "same": ["root", "fleet/argocd/", "bulletin-staging", "fleet/staging/", "namespace staging"]}
```

O que sobra fora do Git é o `~/setup/root.yaml` e a instalação do próprio Argo CD. Isso é o bootstrap,
e todo arranjo GitOps tem um: algo precisa existir antes que o agente consiga ler o repositório.
Mantê-lo em dois arquivos que você aplica em um minuto é o objetivo. A aula 5 volta a isso, com o
Flux, cujo bootstrap faz commit de si mesmo no repositório.
