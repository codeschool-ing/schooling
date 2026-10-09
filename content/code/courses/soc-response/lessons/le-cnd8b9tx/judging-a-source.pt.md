---
title: Quanto acreditar, e quem pode ver
version: 1
---

Um indicador num relatório é uma afirmação feita por alguém. Três perguntas decidem quanto ele vale antes
de chegar perto de uma regra:

- **É relevante?** Um endereço que ataca sistemas de pagamento de bancos diz pouco a um escritório de
  contabilidade.
- **Está em dia?** Todo indicador tem uma vida. Um relatório deve dizer quando ele deixa de valer, e um
  indicador vencido deve sair do SIEM em vez de ficar lá.
- **Quão segura está a fonte, e qual é o histórico dela?** O STIX traz um `confidence` de 0 a 100 em cada
  objeto. Muitas equipes também avaliam a fonte e a informação em separado com o **sistema do Almirantado**:
  a fonte de **A** (totalmente confiável) a **F** (não dá para julgar), e a informação de **1** (confirmada
  por outras fontes) a **6** (não dá para julgar se é verdade). Um "B2" é uma fonte em geral confiável
  dizendo algo provavelmente verdadeiro.

Quem pode ver um relatório é decidido pelo **Traffic Light Protocol**, mantido pelo FIRST. A versão 2.0, em
uso desde 2022, tem cinco rótulos:

| rótulo | pode ser compartilhado com |
|---|---|
| **TLP:RED** | só as pessoas a quem foi entregue, nominalmente, na reunião ou na mensagem |
| **TLP:AMBER+STRICT** | só a sua própria organização |
| **TLP:AMBER** | a sua organização, e os clientes dela que precisam para se proteger |
| **TLP:GREEN** | a sua comunidade mais ampla, mas não publicado abertamente |
| **TLP:CLEAR** | qualquer pessoa (substituiu o TLP:WHITE) |

O rótulo pertence a quem escreveu o relatório, e **receber um relatório é aceitar o rótulo dele**. Colar um
relatório TLP:AMBER num chamado público ou no chat de suporte de um fornecedor quebra a confiança que tornou
o relatório possível, e grupos de compartilhamento excluem membros que fazem isso.
