---
title: Rastreando um requisito até a sua decisão e o seu teste
version: 1
---

**Rastreabilidade é a capacidade de seguir um requisito para a frente, até as decisões e o código
que o atendem e o teste que o prova, e para trás, de qualquer decisão até o requisito a que ela
serve.** Parece burocracia e é sobretudo um hábito: dê um id a tudo, e escreva os ids onde a coisa
seguinte se refere a eles.

## Uma cadeia, de ponta a ponta

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 150\" role=\"img\" data-fig=\"l06-trace\" aria-label=\"Uma cadeia de rastreabilidade do embarque sem sinal, quatro caixas ligadas da esquerda para a direita pelos seus ids: o requisito QS-02, o registro de decisão ADR-0006, os elementos do modelo app de embarque e sincronização, e o teste de leitura sem rede.\"><defs><marker id=\"l06-trace-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><text x=\"95.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">requisito</text><rect x=\"15.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">QS-02</text><text x=\"95.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">leitura sem sinal, 1 s</text><text x=\"275.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">decisão</text><rect x=\"195.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"275.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ADR-0006</text><text x=\"275.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">lista no celular</text><text x=\"455.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">modelo</text><rect x=\"375.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">app de embarque, sinc.</text><text x=\"455.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">visão de implantação</text><text x=\"635.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">verificação</text><rect x=\"555.0\" y=\"45.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"635.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teste sem rede</text><text x=\"635.0\" y=\"86.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">a cada versão</text><path d=\"M175.0 80.0 L195.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-trace-am-fill-paper)\"></path><path d=\"M355.0 80.0 L375.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-trace-am-fill-paper)\"></path><path d=\"M535.0 80.0 L555.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-trace-am-fill-paper)\"></path><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada elo é uma referência por id, então renomear um título não quebra nada</text></svg>", "caption": "Para a frente, do requisito à prova, e para trás, de qualquer teste à razão de ele existir.", "same": ["ADR-0006", "QS-02"]}
```

Para o embarque sem sinal, a cadeia na Carcará é:

1. **QS-02** nos requisitos: leituras aceitas ou recusadas em até um segundo, sem sinal.
2. **ADR-0006** no log de decisões: *cada celular guarda a lista de passagens da viagem*, com a
   sincronização a cada 15 minutos e a regra da passagem desatualizada entre as suas consequências.
3. **O serviço de sincronização do embarque** e o **armazenamento local** no diagrama de
   implantação, cada um com ADR-0006 na sua descrição.
4. **Um teste** que roda o app de embarque com a rede desligada e lê 200 passagens, e falha se
   alguma conferência levar mais de um segundo.

Cada elo é só uma referência por id. **Os ids são o que faz a cadeia sobreviver a uma renomeação**:
a aula 1 deste curso e as próprias regras da plataforma defendem o mesmo ponto, de ligar as coisas
por ids estáveis e não por títulos.

## A matriz, e quando manter uma

Uma matriz de rastreabilidade põe os requisitos nas linhas e as coisas que os atendem nas colunas.
Num domínio regulado, como dispositivos médicos, aviação ou alguns contratos públicos, ela é
obrigatória. Para a Carcará, uma tabela pequena no documento de arquitetura basta, e ela cobre só os
requisitos significativos:

| requisito | decisões | onde no modelo | verificado por |
| --- | --- | --- | --- |
| QS-01 compras no pico | ADR-0009, ADR-0012 | API de passagens, store de assentos | teste de carga antes de todo São João |
| QS-02 embarque sem sinal | ADR-0006 | app de embarque, sincronização do embarque | teste de leitura sem rede, a cada versão |
| QS-03 failover do banco | ADR-0002 | banco de reservas | simulação de failover, a cada trimestre |
| QS-04 novo meio de pagamento | ADR-0011 | adaptador de pagamento, `PaymentPort` | o último meio levou 7 dias |
| QS-05 auditoria de estorno | ADR-0015 | log de auditoria | amostra de auditoria trimestral |

## Lendo uma matriz em busca de lacunas

A matriz é útil principalmente pelo que ela não tem:

- **um requisito sem decisão** é um para o qual ninguém projetou ainda;
- **uma decisão sem requisito** ou serve a um requisito que ninguém escreveu, e que deveria ser
  escrito, ou não serve a nenhum, o que a torna candidata a ser removida;
- **um requisito sem verificação** é uma esperança. *O último meio levou 7 dias* é uma evidência
  fraca, mas é evidência; uma célula vazia não é nenhuma.

A aula 11 volta à verificação com as **funções de aptidão** (fitness functions), verificações
automatizadas que mantêm uma qualidade verdadeira à medida que o sistema muda, e a aula 13 usa esta
tabela como ponto de partida de uma revisão.
