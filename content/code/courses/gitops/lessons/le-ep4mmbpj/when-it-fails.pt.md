---
title: Quando uma Application falha
version: 1
---

O Argo CD informa as falhas como condições na Application, e o `argocd app get` as imprime embaixo
do resumo. Cada uma destas foi produzida de propósito, com uma Application de teste aplicada à mão e
apagada depois.

## Um repositório que ele não consegue ler

A Application cita um repositório para o qual o Argo CD não tem credenciais, aqui um que não existe:

```
ana@laptop:~/setup$ argocd app get probe-repo | sed -n '/^Sync Status/p;/^CONDITION/,/^$/p'
Sync Status:        Unknown
CONDITION        MESSAGE  LAST TRANSITION
ComparisonError  Failed to load target state: failed to generate manifest for source 1 of 1: rpc error: code = Unknown desc = failed to list refs: authentication required: Unauthorized
                 2026-10-10 02:21:02 -0300 -03
```

`ComparisonError`, e a resposta do Gitea repassada. O Argo CD não conseguiu gerar nada, então não
consegue dizer se o cluster está sincronizado: o status é `Unknown`, e não `OutOfSync`. Confira a URL
com `argocd repo list`, e se as credenciais dali conseguem lê-lo.

## Um caminho que não existe

```
ana@laptop:~/setup$ argocd app get probe-path | sed -n '/^Sync Status/p;/^CONDITION/,/^$/p'
Sync Status:        Unknown
CONDITION        MESSAGE                                                                                                                                       LAST TRANSITION
ComparisonError  Failed to load target state: failed to generate manifest for source 1 of 1: rpc error: code = Unknown desc = stagng: app path does not exist  2026-10-10 02:21:11 -0300 -03
```

Um erro de digitação em `path`, e o repo server diz exatamente isso. Nada é apagado quando o caminho
some, e isso é de propósito: **uma geração vazia nunca é tomada como "apague tudo"**.

## Duas Applications para um objeto

Uma segunda Application apontando para o mesmo caminho, aqui `probe-copy`, encontra objetos que já
pertencem à `bulletin-staging`:

```
ana@laptop:~/setup$ argocd app get probe-copy | sed -n '/^Sync Status/p;/^CONDITION/,/^$/p'
Sync Status:        OutOfSync from main (463b299)
CONDITION              MESSAGE                                                                             LAST TRANSITION
SharedResourceWarning  Deployment/bulletin is part of applications argocd/probe-copy and bulletin-staging  2026-10-10 02:21:20 -0300 -03
SharedResourceWarning  Namespace/staging is part of applications argocd/probe-copy and bulletin-staging    2026-10-10 02:21:20 -0300 -03
SharedResourceWarning  Service/bulletin is part of applications argocd/probe-copy and bulletin-staging     2026-10-10 02:21:20 -0300 -03
```

O `SharedResourceWarning` cita os dois donos. É o "duas verdades" da aula 2 pego pela ferramenta, e
não por um cluster alternando entre elas: duas Applications sincronizando o mesmo objeto
sobrescreveriam o trabalho uma da outra, e a anotação de rastreamento uma da outra, a cada passada.
**Apague uma delas**, ou aponte-as para caminhos que não se sobreponham; nada mais faz o aviso sumir.
