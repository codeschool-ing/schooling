---
title: "A vida de um requisito: rastrear, priorizar, mudar, aprovar"
version: 1
---

**Um requisito não está pronto quando é escrito. Ele é rastreado, priorizado, mudado e aprovado, e a
área de Gerenciamento do Ciclo de Vida dos Requisitos do BABOK trata de fazer isso de propósito.**
Quase tudo é a rastreabilidade da aula 6 com uma camada de governança por cima.

## Priorizando com MoSCoW

Das técnicas de priorização do guia, o **MoSCoW** é a que você mais vai ver:

- **Must have** (tem de ter): sem ele, a solução não atende à necessidade. *Cruzar pagamentos com
  cartão e Pix.*
- **Should have** (deveria ter): importante, mas há um contorno. *Cruzar reembolsos
  automaticamente*: Joana ainda consegue cruzá-los à mão por um tempo.
- **Could have** (poderia ter): desejável, feito se der tempo. *Um gráfico das divergências por
  semana.*
- **Won't have this time** (não terá desta vez): combinado como fora do escopo por enquanto, e
  escrito para não ser esquecido. *Conciliar o dinheiro das rodoviárias.*

A quarta categoria é a importante. **Escrever o que não vai ser feito** transforma uma omissão
silenciosa numa decisão que alguém pode questionar, que é o argumento da aula 5 sobre registrar as
opções rejeitadas, aplicado ao escopo.

Uma regra prática, do método DSDM, de onde vem o MoSCoW: se os Musts passam de uns 60% do esforço, o
plano não tem folga para nada dar errado.

## Controle de mudanças

Requisitos mudam, e devem mudar: um requisito que nunca muda provavelmente nunca foi examinado. O que
o BABOK pede é que **uma mudança seja avaliada antes de ser aceita**: o que ela afeta, para cima e
para baixo ao longo do rastro? Quando a empresa de pagamento anunciou o formato novo do arquivo de
liquidação, o rastro a partir de *ler o arquivo de liquidação* levou a dois requisitos de solução,
um requisito de transição e ao ADR-0019, e o custo da mudança ficou conhecido numa tarde.

## Aprovação

Cada requisito, ou cada conjunto, tem um aprovador, tirado da RACI da seção de stakeholders.
Aprovação não é uma assinatura num documento comprido; é **uma decisão registrada de que esta versão
destes requisitos é a base do trabalho**, para que uma mudança posterior apareça como mudança. Num
time que trabalha em repositório, ela pode ser tão leve quanto um pull request aceito no arquivo de
requisitos, com o aprovador como revisor, que é o mesmo mecanismo dos registros de decisão da aula 5.
