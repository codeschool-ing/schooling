---
title: Fechar, e escalar
version: 1
---

Todo alerta termina de um de dois jeitos, e os dois ficam escritos.

**Fechar** exige um motivo tirado de uma lista curta e fixa, porque os motivos são a base dos números de
qualidade da aula 6:

| motivo | significado | o exemplo de segunda |
|---|---|---|
| **falso positivo** | a regra casou com algo que não é o que ela descreve | o erro de digitação da helena |
| **verdadeiro positivo benigno** | é exatamente o que a regra descreve, e é permitido | um teste de invasão aprovado, de um endereço listado |
| **duplicado** | já coberto por um alerta ou incidente aberto | o alerta de quinta às 03:05, juntado ao das 02:33 |

Uma nota de fechamento diz *por quê* numa frase que um estranho aceitaria: "helena, do endereço de sempre, um
erro de digitação, mesmo padrão nos outros dias" é uma nota; "FP" não é.

**Escalar** entrega o alerta a alguém com mais tempo, acesso ou autoridade, e a nota é o que faz a passagem
funcionar. Ela leva o que se sabe, o que não se sabe e o que já foi feito:

```localised
Escalação: possível comprometimento de conta, bruno, com transferência de dados
Sabido: 203.0.113.66 tentou 19 contas a partir das 02:10 (horário local, 17 set), entrou
  como bruno às 02:33:07 com senha, chegou ao files às 02:35:40 e voltou às 03:05:22
  com chave pública. O files enviou 612.408.119 bytes para 203.0.113.200:443 às 02:41:12.
  O bruno entrou normalmente de 203.0.113.17 às 08:35.
Não sabido: o que foi enviado; se o bruno compartilhou a senha; como a chave chegou lá.
Feito: nada alterado ainda. Perguntado ao gestor do bruno às 09:10 se ele trabalha à noite.
Prioridade: P1. Aberta por ana, 09:12.
```

**Escalar não é fracasso**, nem um julgamento sobre o analista. Um SOC em que a triagem nunca escala nada tem
um ambiente perfeito ou analistas com medo de escalar, e só um dos dois existe.
