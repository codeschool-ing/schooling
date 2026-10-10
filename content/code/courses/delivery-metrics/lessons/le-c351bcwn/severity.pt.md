---
title: Severidade, decidida pelo impacto
version: 1
---

Um nível de severidade responde uma pergunta para todo mundo ao mesmo tempo: **quanto do resto deve parar por causa disso?** Ele decide quem é acordado, quem é avisado, com que frequência saem atualizações e se outros trabalhos param. É por isso que precisa ser decidido rápido, por uma regra simples, e revisto sem cerimônia.

## Uma escala para o time de Billing

A maioria das organizações usa quatro ou cinco níveis, numerados a partir do pior. Aqui está uma escala que o time de Billing poderia usar; as palavras exatas importam menos do que tê-las escritas antes do primeiro incidente.

| nível | a experiência dos usuários | exemplos para Billing | resposta |
|---|---|---|---|
| **SEV1** | muitos usuários prejudicados, dinheiro ou dados em risco, sem contorno | lojas cobradas duas vezes; faturas emitidas com valores errados | todos os necessários, agora; liderança avisada; atualizações a cada 30 minutos |
| **SEV2** | muitos usuários afetados e existe contorno, ou poucos usuários seriamente prejudicados | pagamentos com cartão falhando para uma bandeira; extratos atrasados | plantão e o time dono; atualizações a cada hora |
| **SEV3** | uma funcionalidade degradada, a maioria dos usuários não é afetada | a exportação dos extratos do ano passado está lenta | tratado no horário de trabalho; uma atualização quando resolvido |
| **SEV4** | cosmético ou interno | um erro de digitação no rodapé da fatura | um ticket normal, não um incidente |

## Impacto, não causa

A escala não diz nada sobre **por que** algo quebrou, e isso é deliberado. A severidade é decidida nos primeiros minutos, quando a causa é desconhecida; amarrá-la à causa significaria esperar. Ela também é uma afirmação sobre os usuários, o que mantém a resposta voltada para eles: um erro de configuração de uma linha que cobra as lojas em dobro é um SEV1; uma falha elaborada num job em lote interno do qual ninguém depende é um SEV3.

## Decida rápido, reveja à vontade

**Na dúvida, escolha o nível mais alto.** Rebaixar um SEV1 para SEV2 depois de dez minutos custa a algumas pessoas uma noite interrompida. Elevar um SEV3 para SEV1 depois de uma hora custa aos usuários essa hora sem as pessoas certas trabalhando nele.

A severidade é revista conforme os fatos chegam, e cada revisão é registrada com o horário. Um incidente que começa como "uma loja diz que foi cobrada duas vezes", SEV2, vira SEV1 quando a contagem chega às dezenas. Isso não é um erro na primeira decisão; é o processo funcionando.

## A severidade nos números

A severidade também liga esta parte do curso às métricas DORA. A aula 5 pediu que os times decidissem **o que conta como falha** antes de olhar a taxa de falha de mudanças, e uma resposta comum é "qualquer deploy que cause um incidente SEV2 ou pior". A aula 7 mostrou o que acontece quando essa linha é traçada depois. Escreva isso junto com a escala.
