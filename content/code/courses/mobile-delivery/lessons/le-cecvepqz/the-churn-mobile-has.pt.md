---
title: O churn que um app mobile tem de verdade
version: 1
---

**Na web e numa assinatura, churn é um evento: alguém cancela. Num celular, é a ausência de um.** As
pessoas raramente desinstalam com raiva; elas param de abrir o app, e um dia, precisando de espaço
para fotos, apagam o ícone em que não tocam há semanas. O app não manda evento nenhum na saída,
porque não está rodando.

## Os jeitos de sair que você nunca vê

- **Param de abri-lo.** A única evidência são as linhas que não estão na tabela de coortes.
- **Desligam as notificações dele.** O lembrete da lição 15 para de chegar, e com ele o motivo mais
  eficaz que elas tinham para voltar. As duas plataformas deixam o app perguntar se as notificações
  estão ligadas, na abertura seguinte.
- **Desinstalam.** Nenhuma plataforma avisa o próprio app. O Firebase consegue informar um evento
  `app_remove` no Android, onde o sistema avisa o Google Play services; no iOS não há equivalente.
  Uma notificação push que já não pode ser entregue costuma ser o primeiro sinal, pela resposta do
  serviço de push.
- **Desinstalam para liberar espaço**, o que a lição 18 mostra não ser um motivo raro: os apps
  maiores que a pessoa pouco usa são os primeiros a ir embora.

## Definir churn para poder contá-lo

Como nada marca o momento, o churn é definido por uma regra: **uma pessoa saiu quando está inativa
há N dias**, com N escolhido para combinar com o uso do app. Para o planner, cujas pessoas estudam
algumas vezes por semana, 14 dias sem um `app_open` é uma linha sensata: longa o bastante para não
contar uma semana de férias, curta o bastante para perceber dentro do mês. Um app de mensagens usaria
muito menos dias, um app anual de imposto de renda muito mais.

**A taxa de churn é então a fração das pessoas ativas do período anterior que cruzou essa linha**, e é
sempre uma estimativa: algumas dessas pessoas voltam depois do dia 15, e a regra as chama de perdidas
e depois de ressuscitadas.
