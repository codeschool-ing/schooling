---
title: Mostrando o que muda
version: 1
---

**A maioria das apresentações de arquitetura é sobre uma mudança, e a plateia precisa ver o que é
diferente sem comparar duas figuras caixa por caixa.** A aula 8 desenhou a linha de base, o alvo e as
transições entre eles; esta seção trata de pôr isso na frente das pessoas.

## Mantenha as posições

A regra mais útil de todas: **desenhe o antes e o depois com cada elemento no mesmo lugar**. Se o
sistema de venda de passagens está no meio da primeira figura, está no meio da segunda. Aí o olho
acha a diferença sozinho, do jeito que acha a diferença entre duas fotos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l14-before-after\" aria-label=\"Antes e depois, lado a lado, com cada elemento no mesmo lugar. Antes: o guichê da rodoviária, ligado por uma linha ao sistema de venda de passagens, com o back office da rodoviária embaixo do guichê e o banco de reservas embaixo do sistema de venda. Depois: os mesmos quatro elementos nas mesmas posições; o back office está tracejado e cinza com a palavra aposentado, e uma segunda linha, grossa e âmbar, do guichê até o sistema de venda tem o rótulo novo: 2º link.\"><defs><marker id=\"l14-before-after-am-fill-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-before-after-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"34.0\" width=\"330.0\" height=\"226.0\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">antes</text><rect x=\"195.0\" y=\"87.0\" width=\"130.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"103.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Venda de</text><text x=\"260.0\" y=\"116.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">passagens</text><rect x=\"40.0\" y=\"87.0\" width=\"120.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"103.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Guichê da</text><text x=\"100.0\" y=\"116.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">rodoviária</text><path d=\"M160.0 104.0 L195.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-before-after-am-fill-paper-dim)\"></path><rect x=\"40.0\" y=\"190.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"203.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Back office</text><text x=\"100.0\" y=\"216.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Container]</text><path d=\"M100.0 133.0 L100.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"195.0\" y=\"190.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Banco de reservas</text><path d=\"M260.0 133.0 L260.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"370.0\" y=\"34.0\" width=\"330.0\" height=\"226.0\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">depois</text><rect x=\"545.0\" y=\"87.0\" width=\"130.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"103.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Venda de</text><text x=\"610.0\" y=\"116.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">passagens</text><rect x=\"390.0\" y=\"87.0\" width=\"120.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"103.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Guichê da</text><text x=\"450.0\" y=\"116.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">rodoviária</text><path d=\"M510.0 104.0 L545.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-before-after-am-fill-paper-dim)\"></path><rect x=\"390.0\" y=\"190.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\"></rect><text x=\"450.0\" y=\"203.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Back office</text><text x=\"450.0\" y=\"216.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">aposentado</text><path d=\"M510.0 120.0 L545.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\" marker-end=\"url(#l14-before-after-am-fill-amber)\"></path><text x=\"527.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">novo: 2º link</text><rect x=\"545.0\" y=\"190.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Banco de reservas</text><path d=\"M610.0 133.0 L610.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">mesmos lugares: o olho acha a diferença sozinho</text></svg>", "caption": "Nada se mexeu além do que mudou, e cada mudança traz uma palavra além de uma cor.", "same": ["Back office", "[Container]"]}
```

Uma ferramenta que dispõe os diagramas automaticamente, como a maioria das da aula 12, vai mover
elementos quando um for acrescentado ou removido. Para um par antes e depois, fixe a disposição à
mão, ou desenhe a figura do depois uma vez e tire os elementos novos para fazer a do antes.

## Marque a mudança duas vezes

Os elementos que mudaram precisam se destacar, e **a cor sozinha não basta**: um homem em cada doze
não distingue vermelho de verde, um projetor desbota o âmbar, e uma cópia impressa pode sair em
cinza. Marque cada mudança duas vezes, com cor e com uma palavra ou uma forma:

- um elemento novo na cor de destaque, com o rótulo **novo**;
- um aposentado tracejado e cinza, com o rótulo **aposentado**, em vez de simplesmente sumir, para
  que ninguém fique se perguntando se ele foi esquecido;
- um elemento que muda, com uma nota curta sobre o que muda, *agora também vende no guichê*.

Na segunda-feira, os diretores viram o back office das rodoviárias tracejado e cinza com
*aposentado* ao lado, e o segundo link móvel em âmbar com *novo, 12 rodoviárias, antes do São João*.
Ninguém precisou perguntar o que tinha mudado.

## Mostre os passos, não só as pontas

Uma mudança que leva um ano tem estados no meio, e é neles que as pessoas vão viver. A aula 8 os
chamou de **arquiteturas de transição**. Para o programa de embarque digital, a pergunta que o time
de produto fez não era sobre o alvo, e sim *como fica uma rodoviária em maio, no meio do caminho?* Uma
apresentação de uma mudança longa mostra **pelo menos a próxima transição**, com a data, e marca
quais capacidades cada passo acrescenta ou remove.

## Diga o que não muda

As pessoas ouvem *mudança de arquitetura* e imaginam a parte delas se mexendo. **Dizer o que fica
igual faz parte de mostrar a mudança**: *o app do passageiro, os pagamentos e o app de embarque não
são tocados.* Na Carcará, foi essa a frase que encerrou as perguntas do time de Pagamentos antes
que elas começassem.
