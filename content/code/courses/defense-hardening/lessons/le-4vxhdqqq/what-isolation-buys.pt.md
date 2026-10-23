---
title: O que o isolamento compra
version: 1
---

**Uma sandbox roda um programa num mundo menor do que a máquina em que ele está.** Dentro dela, o
programa vê menos arquivos, menos dispositivos, menos da rede e menos dos poderes do sistema, e o que
ele faz ali não alcança o que não recebeu. É a resposta a uma pergunta que quem defende encontra toda
semana: chegou um arquivo que alguém precisa abrir, e ninguém sabe dizer se é seguro.

A imagem comum é a de uma caixa com tampa: ou o programa está dentro, e seguro, ou não está. Na
prática há camadas de caixas, e elas diferem na espessura das paredes e no custo de construí-las:

| camada | o que separa o programa | parede | custo |
|---|---|---|---|
| **um processo confinado** | namespaces e filtros num mesmo kernel: a sua própria visão dos arquivos, da rede, das chamadas de sistema | fina: um bug no kernel compartilhado a atravessa | nenhum: começa em milissegundos, e o systemd a monta para todo serviço que você pedir |
| **um contêiner** | os mesmos mecanismos, aplicados a um sistema inteiro | o mesmo kernel, então a mesma espessura | pequeno: este laboratório é sete deles |
| **uma máquina virtual** | um hipervisor e um kernel próprio | grossa: o programa precisaria de uma falha no hipervisor | real: um segundo sistema operacional, com memória e disco |
| **outro computador** | nada compartilhado | a mais grossa | uma máquina que você pode jogar fora |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-layers\" aria-label=\"Quatro camadas de isolamento lado a lado, a borda de cada caixa tão grossa quanto a parede. Um processo confinado divide o kernel com todo o resto. Um contêiner também divide esse kernel. Uma máquina virtual tem kernel próprio sobre um hipervisor. Outro computador não divide nada. O custo cresce da esquerda para a direita junto com a força da parede.\"><defs><marker id=\"l12-layers-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">processo confinado</text><text x=\"105.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kernel dividido</text><rect x=\"202.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"277.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">contêiner</text><text x=\"277.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kernel dividido</text><rect x=\"374.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"3.0\"></rect><text x=\"449.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">máquina virtual</text><text x=\"449.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kernel próprio</text><rect x=\"546.0\" y=\"50.0\" width=\"150.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"4.6\"></rect><text x=\"621.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">outro computador</text><text x=\"621.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada dividido</text><path d=\"M40.0 210.0 L680.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-layers-dh-ah-paper-dim)\"></path><text x=\"40.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parede mais fina, quase de graça</text><text x=\"680.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parede mais grossa, custo real</text><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a espessura de cada borda é a da parede</text></svg>", "caption": "Escolha a camada pelo que você teme: uma falha num programa confiável, ou um arquivo feito para escapar."}
```

**A camada certa se decide pelo que você teme.** Um programa em que você confia e que deve fazer um
trabalho, o portal, cabe num processo confinado, para que uma falha nele alcance o mínimo possível.
Um arquivo de origem desconhecida, que pode ter sido escrito para escapar do que o segura, cabe numa
máquina virtual ou numa máquina separada para isso, e a aula 19 acrescenta os serviços que rodam esses
arquivos no computador de outra pessoa. Esta aula trabalha na ponta fina, que é a que a maioria dos
servidores usa e a que menos gente configura.

Toda parede desta aula é feita do que o systemd e o kernel já oferecem no `web`. Suba o laboratório
com as máquinas que esta aula usa:

```sh
sudo bash hostlab.sh up web trap
```

O `trap` está ali só para ser um endereço que o arquivo suspeito pode tentar alcançar.
