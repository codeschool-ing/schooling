---
title: Onde começa a doer
version: 1
---

Um monólito deixa de ser a opção barata de alguns jeitos identificáveis. Cada um é uma força, e uma
divisão só vale o custo extra quando uma delas é forte o bastante para pagá-lo. **Dar nome à força é
a habilidade inteira**: "vamos para microsserviços" sem uma força nomeada é moda, e a conta chega do
mesmo jeito.

**Toda mudança implanta tudo.** Mudar uma linha de `payments_charge` reconstrói a imagem e substitui o
único contêiner, então o catálogo, que não mudou, cai e volta junto. Com uma equipe, são alguns
segundos de risco. Com cinco equipes, vira um trem de releases: as mudanças esperam uma data
compartilhada, um defeito no código de uma equipe segura as outras quatro, e implantar fica mais raro
e, por isso, mais arriscado.

**Escalar copia tudo.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três cópias do monólito lado a lado atrás de um balanceador de carga. Cada cópia tem os quatro módulos. Em todas, só o módulo de catálogo aparece ocupado; estoque, pagamentos e pedidos estão ociosos mas foram copiados mesmo assim.\"><defs><marker id=\"l1-scale-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"260\" y=\"24\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">balanceador de carga</text><rect x=\"40\" y=\"90\" width=\"190\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cópia 1</text><rect x=\"52\" y=\"120\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">catálogo: ocupado</text><rect x=\"52\" y=\"148\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estoque: ocioso</text><rect x=\"52\" y=\"173\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pagamentos: ocioso</text><rect x=\"52\" y=\"198\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos: ocioso</text><path d=\"M360 60 L135 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-scale-ah-wire)\"></path><rect x=\"265\" y=\"90\" width=\"190\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cópia 2</text><rect x=\"277\" y=\"120\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">catálogo: ocupado</text><rect x=\"277\" y=\"148\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estoque: ocioso</text><rect x=\"277\" y=\"173\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pagamentos: ocioso</text><rect x=\"277\" y=\"198\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos: ocioso</text><path d=\"M360 60 L360 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-scale-ah-wire)\"></path><rect x=\"490\" y=\"90\" width=\"190\" height=\"136\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cópia 3</text><rect x=\"502\" y=\"120\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">catálogo: ocupado</text><rect x=\"502\" y=\"148\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estoque: ocioso</text><rect x=\"502\" y=\"173\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pagamentos: ocioso</text><rect x=\"502\" y=\"198\" width=\"166\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pedidos: ocioso</text><path d=\"M360 60 L585 88\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-scale-ah-wire)\"></path></svg>", "caption": "Escalar um monólito é copiar ele inteiro. Quando só o catálogo está ocupado, os outros três módulos são copiados à toa, com a memória e as conexões deles."}
```

Se o catálogo recebe mil vezes o tráfego do resto, o único jeito de dar mais processos a ele é rodar
mais cópias do programa inteiro, cada uma com a memória, o tempo de partida e as conexões de banco de
todos os módulos. Funciona, e para muitas lojas é mais barato do que qualquer outra coisa. Para de
funcionar quando um módulo precisa de algo que os outros não precisam, uma máquina com GPU ou vinte
vezes a memória, e toda cópia tem de pagar por isso.

**Uma falha em qualquer lugar é uma falha em todo lugar.** Um vazamento de memória num relatório, um
laço que nunca termina, uma exceção não tratada que mata o processo: num processo só, cada um deles
derruba o checkout junto com o código que causou o problema. A aula 12 mostra como cercar uma falha,
e algumas dessas cercas funcionam dentro de um processo.

**O build e os testes crescem com o todo.** Quando a suíte de testes leva quarenta minutos, a equipe
roda menos, e uma mudança que levava uma hora passa a levar um dia.

**Uma tecnologia para tudo.** O programa inteiro está numa linguagem, num runtime, com uma versão de
cada biblioteca. Um módulo que ficaria muito melhor em outra linguagem, ou que precisa de uma versão
de biblioteca que o resto não aceita, tem de esperar todo mundo.

## Lendo as forças

| força | o que ela pede | o primeiro passo mais barato |
| --- | --- | --- |
| equipes travando o deploy umas das outras | implantação independente | um monólito modular, com donos por módulo e um pipeline mais rápido |
| um módulo com carga muito diferente | escalá-lo à parte | mais cópias do todo, com um cache na frente da parte quente |
| um módulo com necessidades diferentes de hardware ou runtime | rodá-lo à parte | tirar esse módulo, e só ele |
| uma falha numa parte derrubando o resto | isolamento | timeouts e bulkheads dentro do processo, aula 12 |

**A coluna da direita está ali de propósito.** A maioria dessas forças tem uma resposta que mantém o
monólito, e é a resposta para tentar primeiro. Quando ela não basta, a divisão que ela aponta é
pequena: um módulo, tirado por um motivo. A aula 2 trata de fazer isso direito, e do que a divisão vai
custar desde o primeiro dia.

Antes de sair da aula, pare a loja e remova o volume dela:

```sh
docker compose down -v
```
