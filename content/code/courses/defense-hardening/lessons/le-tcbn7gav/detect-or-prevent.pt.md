---
title: Detectar, e prevenir
version: 1
---

**Um sistema de detecção de intrusão no host percebe; um sistema de prevenção de intrusão no host
age.** Os dois nomes, HIDS e HIPS, descrevem o mesmo tipo de programa em duas posições de um mesmo
botão. Os dois vigiam uma máquina atrás de sinais de que algo está errado. Um HIDS grava um alerta e
deixa a decisão para uma pessoa. Um HIPS toma a decisão sozinho, na hora: recusa o login, bloqueia o
endereço, impede o programa de abrir o arquivo.

A imagem comum é a de que prevenir é simplesmente melhor, porque não espera ninguém. **Prevenir só é
melhor onde a regra nunca erra.** Um alerta errado custa um minuto a alguém. Um bloqueio errado tranca
a diretora do lado de fora na manhã da auditoria, e um HIPS que faz isso duas vezes está desligado na
terceira semana. Então cada regra de HIPS é escolhida perguntando quão certa ela consegue ser, e as
que não conseguem ter certeza ficam do lado da detecção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-dial\" aria-label=\"Uma vigilância, duas posições. À esquerda, detecção: um evento vai para uma regra, a regra gera um alerta e uma pessoa decide. À direita, prevenção: o mesmo evento e a mesma regra, e o programa age na hora. Embaixo, uma linha de incerto a certo: regras que podem errar ficam à esquerda, e só regras que nunca erram vão para a direita. O fail2ban fica à direita; o AIDE, à esquerda.\"><defs><marker id=\"l11-dial-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"190.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">detecção (HIDS)</text><rect x=\"40.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"85.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">evento</text><path d=\"M130.0 63.0 L145.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"145.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"190.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">regra</text><path d=\"M235.0 63.0 L250.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"250.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"295.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma pessoa decide</text><text x=\"530.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">prevenção (HIPS)</text><rect x=\"380.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"425.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">evento</text><path d=\"M470.0 63.0 L485.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"485.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"530.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">regra</text><path d=\"M575.0 63.0 L590.0 63.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><rect x=\"590.0\" y=\"45.0\" width=\"90.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"635.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o programa age</text><path d=\"M60.0 140.0 L660.0 140.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-dial-dh-ah-paper-dim)\"></path><text x=\"60.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a regra pode errar</text><text x=\"660.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a regra nunca erra</text><circle cx=\"190.0\" cy=\"140.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"190.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">AIDE</text><text x=\"190.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um arquivo mudou: estava certo?</text><circle cx=\"560.0\" cy=\"140.0\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"560.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fail2ban</text><text x=\"560.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">três falhas em dez minutos</text></svg>", "caption": "Prevenção é detecção com permissão de agir sozinha, e só regras certas merecem isso."}
```

Esta aula põe um de cada no `web`:

| | o que vigia | o que faz | quão certo |
|---|---|---|---|
| **fail2ban** | o log de logins que falharam | bloqueia o endereço que insiste em falhar | muito: um cliente que falha três vezes em dez minutos está perdido ou chutando, e nos dois casos um banimento curto custa pouco |
| **AIDE** | o conteúdo e as permissões de arquivos escolhidos | informa o que mudou desde o último estado aprovado | tem certeza de que um arquivo mudou, e não faz ideia se a mudança estava certa, então só informa |

O EDR da aula 8 fica ao lado dos dois. Ele vigia comportamento, e as regras dele são onde o botão é
girado com mais cuidado, e é por isso que a resposta naquela aula foi decisão de uma pessoa.

Um terceiro tipo de prevenção age antes de qualquer coisa acontecer: o **controle de acesso
obrigatório**, que confina um programa ao que ele pode tocar, tente ele o que tentar. É o mais forte
dos três e o único que este laboratório não consegue rodar, por um motivo que a seção sobre ele
explica.

Suba o laboratório com as máquinas que esta aula usa:

```sh
sudo bash hostlab.sh up web desk
```
