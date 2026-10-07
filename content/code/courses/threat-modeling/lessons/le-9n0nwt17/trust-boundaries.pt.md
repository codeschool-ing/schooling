---
title: Fronteiras de confiança
version: 1
---

Sem a linha tracejada, um diagrama de fluxo de dados é documentação. Com ela, o diagrama vira um
modelo de ameaças, porque **uma fronteira de confiança marca onde o nível de confiança muda, e um
fluxo que cruza uma fronteira é onde mora a maioria das ameaças.** De um lado da linha, os dados e
o código são controlados por um conjunto de pessoas e permissões; do outro lado, por outro. Tudo o
que cruza precisa ser verificado na chegada, porque o que era verdade do lado de lá não está mais
garantido.

A ideia errada comum é que existe uma fronteira só: o firewall, com o mundo lá fora e tudo o que é
confiável dentro. Esse retrato perde a maior parte das fronteiras que um sistema real tem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-boundaries-redrawn\" aria-label=\"As mesmas cinco partes desenhadas duas vezes. À esquerda, uma fronteira em volta de tudo o que a Vereda roda, a visão do firewall: o paciente fora, portal, worker e banco dentro, juntos. À direita, fronteiras onde quer que a confiança mude: o portal responde à internet, então fica numa zona própria; o banco e o worker ficam numa rede privada; o provedor de SMS é outra empresa. O fluxo do worker para o banco agora não cruza nada, e o fluxo do portal para o banco cruza uma fronteira que o desenho da esquerda escondia.\"><defs><marker id=\"l02-boundaries-redrawn-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma fronteira: dentro e fora</text><rect x=\"10.0\" y=\"73.0\" width=\"80.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"50.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Paciente</text><circle cx=\"165.0\" cy=\"90.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"165.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Portal</text><rect x=\"120.0\" y=\"205.0\" width=\"90.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M120.0 205.0 L210.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M120.0 235.0 L210.0 235.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"165.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Banco</text><circle cx=\"290.0\" cy=\"220.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"290.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Worker</text><rect x=\"255.0\" y=\"73.0\" width=\"70.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">SMS</text><path d=\"M90.0 90.0 L135.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M165.0 120.0 L165.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M260.0 220.0 L210.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M290.0 190.0 L290.0 107.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><text x=\"545.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma fronteira onde a confiança muda</text><rect x=\"380.0\" y=\"73.0\" width=\"80.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Paciente</text><circle cx=\"535.0\" cy=\"90.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"535.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Portal</text><rect x=\"490.0\" y=\"205.0\" width=\"90.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M490.0 205.0 L580.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M490.0 235.0 L580.0 235.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"535.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Banco</text><circle cx=\"660.0\" cy=\"220.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"660.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Worker</text><rect x=\"625.0\" y=\"73.0\" width=\"70.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">SMS</text><path d=\"M460.0 90.0 L505.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M535.0 120.0 L535.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M630.0 220.0 L580.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M660.0 190.0 L660.0 107.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M115.0 45.0 L335.0 45.0 L335.0 265.0 L115.0 265.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M483.0 45.0 L583.0 45.0 L583.0 130.0 L483.0 130.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M483.0 165.0 L705.0 165.0 L705.0 265.0 L483.0 265.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M625.0 45.0 L695.0 45.0 L695.0 130.0 L625.0 130.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"175.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1 fronteira, 2 fluxos a cruzam</text><text x=\"545.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 fronteiras, 3 fluxos cruzam uma</text></svg>", "caption": "O desenho da esquerda não está errado sobre o firewall. Ele se cala sobre tudo o que está atrás dele, que é onde moram as piores ameaças do portal.", "same": ["Portal", "SMS", "Worker"]}
```

### Onde a confiança muda

Uma fronteira vai onde qualquer um destes for diferente dos dois lados:

| o que difere | exemplo no portal |
|---|---|
| **quem controla a máquina** | o celular do paciente contra a nuvem da Vereda; a nuvem da Vereda contra a do gateway de pagamento |
| **quem controla o código** | o portal, que a Vereda escreveu, contra a API do provedor de SMS |
| **o privilégio com que o código roda** | o portal, que responde a qualquer um, contra o banco, que guarda todos os prontuários |
| **o alcance de rede** | a zona pública da nuvem, alcançável pela internet, contra a rede privada |
| **as pessoas** | pacientes contra a equipe da clínica, que pode ler exames de outras pessoas |

Os processos do portal ficam na nuvem da Vereda, e a nuvem não é uma zona só. O portal responde a
desconhecidos na internet. O banco responde só de dentro da rede privada. Se o portal for tomado, o
que impede o atacante de ler todos os prontuários são as verificações que estiverem no fluxo do
portal para dentro dessa rede. Desenhar uma caixa só em volta da nuvem esconde esse fluxo
justamente no lugar onde ele precisa ser examinado.

### O que uma travessia faz perguntar

Para cada fluxo que cruza uma fronteira, três perguntas vêm antes de qualquer método com nome:

- **Quem mandou isto, e como sabemos?** O webhook de pagamento cruza da zona dos fornecedores para
  a nuvem, e a aula 1 já descobriu que o portal não confere o remetente.
- **Dá para ler ou mudar no caminho?** Um PDF de exame atravessando a internet.
- **Dá para mandar demais, ou grande demais?** Um upload de qualquer um, de qualquer tamanho.

A aula 3 dá estrutura a essas perguntas, o STRIDE, e um motivo para cada uma estar na lista. Por
enquanto o hábito útil é desenhar a linha, porque uma ameaça que mora numa fronteira não desenhada
nem chega a ser perguntada.

### Uma fronteira não é um controle

Desenhar uma fronteira diz que a confiança muda ali. Não diz que alguma coisa a faz valer. O
console da equipe fica atrás de uma linha marcada "rede da clínica", e o primeiro fato da aula 1
diz que ele na verdade responde pela internet: o desenho mostra a intenção, e o sistema não bate
com ela. **Desenhe fronteiras onde a confiança deveria mudar, e depois verifique se alguma coisa
faz cada uma valer.** Uma linha sem nada que a faça valer já é um achado, e dos bons.
