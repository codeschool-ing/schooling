---
title: Famílias, depreciação e a imagem que você vai receber
version: 1
---

Uma família é o motivo de um disco de boot criado na segunda e outro criado na sexta poderem ser
diferentes sem ninguém mudar uma linha. **Uma família sempre aponta para a sua imagem mais nova que
não está depreciada, e esse ponteiro se move toda vez que uma imagem nova é publicada nela.** Isso é
uma vantagem quando você quer patches de segurança e um perigo quando quer duas máquinas idênticas.

## O ponteiro, e o que o move

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A família shop-web à esquerda, com uma seta para a imagem shop-web-v2. Três imagens em fila por idade: shop-web-v1, depreciada; shop-web-v2, ativa; shop-web-v3, a mais nova, depreciada depois de quebrar algo. A família pula a v3 e aponta para a v2, então todo disco de boot novo sai da v2.\"><defs><marker id=\"l2f-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"24\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais antiga</text><text x=\"696\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais nova</text><path d=\"M250 30 L470 30\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"40\" y=\"150\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web</text><text x=\"115.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a família</text><rect x=\"230\" y=\"60\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web-v1</text><text x=\"300.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DEPRECATED</text><rect x=\"390\" y=\"60\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web-v2</text><text x=\"460.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ACTIVE</text><rect x=\"550\" y=\"60\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"620.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-web-v3</text><text x=\"620.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DEPRECATED</text><path d=\"M190 165 L455 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2f-ah)\"></path><text x=\"560\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a mais nova, mas quebrou</text><text x=\"560\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">algo: é pulada</text><text x=\"300\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">todo disco de boot novo sai da v2</text></svg>", "caption": "Uma família aponta para a imagem mais nova que não está depreciada. Depreciar uma versão ruim faz o ponteiro voltar, e esse é o rollback."}
```

Toda imagem carrega um **estado de depreciação**, e é o estado que a família lê. Os quatro estados
estão documentados na própria ajuda do gcloud, que funciona sem conta:

```
ana@laptop:~/gcp$ gcloud compute images deprecate --help | sed -n '/^     --state=STATE/,/^OPTIONAL/p'
     --state=STATE
        The deprecation state to set on the image. STATE must be one of:

         ACTIVE
            The image is currently supported.
         DELETED
            New uses result in an error. Setting this state will not
            automatically delete the image. You must still make a request to
            delete the image to remove it from the image list.
         DEPRECATED
            Operations which create a new DEPRECATED resource return
            successfully, but with a warning indicating that the image is
            deprecated and recommending its replacement.
         OBSOLETE
            New uses result in an error.

OPTIONAL FLAGS
```

**Repare no que a ajuda diz sobre `DELETED`**: definir um estado não remove a imagem. A imagem fica,
e continua sendo cobrada pelo armazenamento, até alguém apagá-la. A depreciação é um rótulo para as
pessoas e as ferramentas que o leem, e a família é uma dessas ferramentas.

Então uma família se move de dois jeitos. Publicar uma imagem mais nova nela empurra o ponteiro para
a frente, e depreciar a imagem mais nova o faz voltar para a anterior. O segundo é o rollback: se a
imagem de sexta quebrar alguma coisa, marcá-la como `DEPRECATED` faz toda máquina nova subir com a
de quinta de novo, sem editar template nenhum.

## Fixar, ou seguir

Saem daqui dois hábitos, e uma equipe precisa escolher um por ambiente:

- **Seguir a família** em desenvolvimento, para toda máquina nova receber os últimos patches sem
  ninguém precisar lembrar de olhar.
- **Fixar o nome datado** onde duas máquinas precisam ser idênticas: num grupo gerenciado, onde a
  lição 4 mostra que um template de instância fixa a imagem, e onde um relatório de incidente
  precisar dizer exatamente o que estava rodando.

Fixar custa uma decisão a cada imagem nova publicada, que é o trabalho que a família poupa. A família
custa a certeza de que duas máquinas são iguais, que é o que fixar compra. Nenhum dos dois é de
graça, e nenhum está errado.

## As suas próprias famílias

Uma família não é só para imagens públicas. Quando você constrói as suas, como mostra a seção 04,
dar a todo build a mesma família o transforma num canal de lançamento: `shop-web` aponta para o
build mais novo da imagem web da loja, depreciar um build ruim faz o rollback, e um template de
instância pode nomear `projects/planner-dev/global/images/family/shop-web` do mesmo jeito que nomeia
`debian-cloud/debian-12`. O comando que faz o rollback é `gcloud compute images deprecate` com
`--state=DEPRECATED`; ele precisa de conta e não é executado aqui.
