---
title: Atributos de qualidade como cenários
version: 1
---

**Um atributo de qualidade vira requisito quando é escrito como cenário: uma situação, o que
acontece e uma medida que diz se o sistema deu conta.** As aulas 6 e 7 de `architecture-role`
apresentaram a forma em seis partes; esta seção a usa para modelar as qualidades mais importantes da
Carcará, e para mostrar como um cenário é desenhado.

## As seis partes, desenhadas

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-scenario\" aria-label=\"As seis partes de um cenário de atributo de qualidade, desenhadas para o embarque sem sinal. A fonte, um motorista, manda o estímulo, lê a passagem, ao artefato, o app de embarque, dentro de um ambiente tracejado, na estrada e sem sinal. A resposta, aceita ou recusa, leva à medida de resposta, em até um segundo para toda leitura.\"><defs><marker id=\"l06-scenario-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"200.0\" y=\"40.0\" width=\"330.0\" height=\"160.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"6 4\"></rect><text x=\"212.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">ambiente: na estrada, sem sinal</text><circle cx=\"80.0\" cy=\"91.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"105.0\" width=\"92.0\" height=\"44.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Motorista</text><path d=\"M128.0 125.0 L240.0 125.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-scenario-am-fill-paper)\"></path><text x=\"184.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">lê a passagem</text><rect x=\"240.0\" y=\"95.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">App de embarque</text><text x=\"320.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">artefato</text><path d=\"M400.0 125.0 L560.0 125.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-scenario-am-fill-paper)\"></path><text x=\"470.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">aceita ou recusa</text><rect x=\"560.0\" y=\"95.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">em até 1 s,</text><text x=\"630.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">toda leitura</text><text x=\"80.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">fonte</text><text x=\"184.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">estímulo</text><text x=\"470.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">resposta</text><text x=\"630.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">medida de resposta</text><text x=\"320.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">artefato</text></svg>", "caption": "O ambiente é desenhado em volta do artefato porque é a condição sob a qual a resposta tem de valer. Mude o ambiente, e é outro cenário."}
```

| parte | o que diz | o cenário do embarque |
| --- | --- | --- |
| **fonte** | quem ou o que causa o estímulo | um motorista |
| **estímulo** | o evento que chega | lê a passagem de um passageiro na porta |
| **ambiente** | as condições no momento | na estrada, sem sinal de celular, depois da última sincronização |
| **artefato** | que parte do sistema é estimulada | o app de embarque no celular do motorista |
| **resposta** | o que o sistema faz | aceita uma passagem Paga para esta viagem, recusa qualquer outra coisa |
| **medida de resposta** | como alguém sabe que foi bom o bastante | em até um segundo, sem rede, em 100% das leituras |

Numa frase só, que é como ele entra num documento:

> **QS-02.** Quando um motorista lê uma passagem na porta sem sinal de celular, o app de embarque a
> aceita ou recusa em até um segundo a partir da sua lista local, em toda leitura.

## Os cenários significativos da Carcará

Cinco cenários saíram da lista de conferência e das conversas com Celeste e Otávio:

| id | atributo | o cenário |
| --- | --- | --- |
| QS-01 | desempenho | Na semana antes do São João, com 2.000 compras começando por minuto, 95% das compras terminam em até 2 segundos, sem contar o tempo do gateway de pagamento. |
| QS-02 | disponibilidade | Sem sinal de celular, o app de embarque aceita ou recusa uma leitura em até um segundo, em toda leitura. |
| QS-03 | disponibilidade | Se o primário do banco de reservas falhar, a venda de passagens volta em até 5 minutos, sem perder nenhuma reserva paga. |
| QS-04 | modificabilidade | Um novo meio de pagamento entra em produção em até 10 dias úteis, sem mudar o serviço de reservas. |
| QS-05 | segurança | Todo estorno acima de R$ 500 é rastreável até a pessoa que o aprovou, por cinco anos. |

## O que faz um cenário ser bom

- **O ambiente é específico.** *No pico* é melhor do que nada; *na semana antes do São João, com
  2.000 compras começando por minuto* é algo que um teste de carga consegue reproduzir.
- **A medida tem número e escopo.** *95% em até 2 segundos* diz que fatia pode ser lenta, o que uma
  média esconderia.
- **Diz o quê, não o como.** O QS-02 não diz *um banco SQLite local*. Isso é o projeto, e pertence a
  um registro de decisão, onde pode ser contestado.
- **Pode falhar.** Se nenhum sistema plausível pudesse errar a medida, o cenário não restringe nada.
