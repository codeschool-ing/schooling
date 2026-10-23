---
title: Um ciclo, não uma varredura
version: 1
---

**Gestão de vulnerabilidades é a rotina de encontrar as falhas no que você roda e fazê-las serem
corrigidas antes que alguém as use.** A imagem comum é uma ferramenta: comprar um scanner, rodar,
ler o relatório. O scanner é um passo de cinco, e os passos que as pessoas pulam são os que vêm
depois do relatório, e é por isso que a maioria das organizações que varre com regularidade ainda tem
achados de anos atrás.

Os cinco passos dão a volta:

| passo | a pergunta que responde |
|---|---|
| **descobrir** | o que rodamos, em que máquinas, em que versões? |
| **avaliar** | que falhas publicadas se aplicam a essas versões? |
| **priorizar** | quais importam primeiro, aqui, e até quando? |
| **remediar** | corrigir, reconfigurar, remover, ou aceitar com um motivo |
| **verificar** | a falha sumiu, medida do mesmo jeito que foi encontrada? |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l16-cycle\" aria-label=\"Cinco passos em volta de um círculo: descobrir o que roda, avaliar que falhas se aplicam, priorizar e marcar uma data, remediar corrigindo, reconfigurando, removendo ou aceitando, e verificar com a mesma checagem que achou a falha, o que leva de volta a descobrir. Descobrir está marcado como aula 18 e remediar como aula 17; avaliar, priorizar e verificar são esta aula.\"><defs><marker id=\"l16-cycle-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M428.0 76.0 L481.7 96.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M531.2 152.6 L495.8 209.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M409.3 239.9 L310.7 239.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M224.2 209.9 L188.8 152.6\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><path d=\"M238.3 96.6 L292.0 76.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l16-cycle-dh-ah-paper-dim)\"></path><rect x=\"298.0\" y=\"26.0\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">descobrir</text><text x=\"360.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aula 18</text><rect x=\"487.7\" y=\"98.6\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"549.7\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">avaliar</text><text x=\"549.7\" y=\"133.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">esta aula</text><rect x=\"415.3\" y=\"215.9\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"477.3\" y=\"232.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">priorizar</text><text x=\"477.3\" y=\"250.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">esta aula</text><rect x=\"180.7\" y=\"215.9\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"242.7\" y=\"232.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">remediar</text><text x=\"242.7\" y=\"250.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aula 17</text><rect x=\"108.3\" y=\"98.6\" width=\"124.0\" height=\"48.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.3\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">verificar</text><text x=\"170.3\" y=\"133.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">esta aula</text></svg>", "caption": "A varredura é um passo de cinco. Os que vêm depois do relatório são os que ficam para trás."}
```

O primeiro passo é o assunto da aula 18, e é aquele de que todo o resto depende: um aviso sobre um
pacote que você não sabe que roda é um aviso sobre o qual ninguém age. O quarto passo é o da aula 17,
em que uma correção é distribuída sem quebrar o portal. Esta aula trata dos três do meio e do último:
**ler o que está instalado, comparar com o que se conhece, decidir o que vem primeiro e marcar uma
data até a qual tem de estar feito.**

## Por que uma data faz parte do assunto

Um achado sem prazo é um achado que espera. Toda organização tem mais vulnerabilidades que gente para
corrigi-las; o estado comum de um acúmulo é crescer. O que transforma o ciclo num programa é que cada
achado ganha um dono e uma data limite quando é encontrado, e que uma data perdida fica visível para
alguém que pode fazer alguma coisa.

**Um prazo é uma decisão sobre risco, escrita em dias.** O escritório decide, antes e por escrito,
quanto tempo cada tipo de achado pode ficar aberto. Essa decisão é a política no topo do script da
seção sobre priorização desta aula, e a última seção trata de cumpri-la.

## O laboratório desta aula

Suba o `web`, cujos pacotes você vai avaliar, e o `admin`, onde os scripts rodam:

```sh
sudo bash hostlab.sh up web admin
```

O `web` sobe do jeito que o `hostlab.sh` o monta, com o servidor FTP e os outros serviços que a aula
1 removeu de volta no lugar, porque toda aula começa com um laboratório novo. Isso acaba importando
nas próximas seções.
