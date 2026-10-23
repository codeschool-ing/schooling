---
title: Um registro inteiro, a partir do pagamento tardio
version: 1
---

**A tabela de estados da aula 4 achou uma célula que ninguém tinha decidido: um pagamento aprovado
para uma passagem que já tinha expirado.** A decisão que Tainá escreveu na tabela virou este
registro. Ele aparece inteiro, e depois desmontado.

```localised
# 14. Estornar automaticamente um pagamento aprovado depois que o bloqueio expirou

Status: Aceito, 2025-07-03
Decisores: Tainá (arquitetura), time de Pagamentos, time de Vendas

## Contexto e forças

- Um assento fica bloqueado por dez minutos enquanto o passageiro
  paga (ADR-0009).
- O gateway de pagamento confirma alguns pagamentos com atraso: 0,4%
  das aprovações chegam mais de dez minutos depois de a cobrança ser
  pedida, por webhook (ADR-0011).
- Quando o bloqueio expirou, o assento pode já ter sido vendido a
  outra pessoa. Em 20 de junho de 2025, isso pôs dois passageiros no
  assento 14 do ônibus das 18:40 para Feira de Santana.
- O código não tinha regra para esse caso; marcava a reserva como paga.
- Um passageiro nunca pode pagar por um assento que não recebeu.
- Os agentes da rodoviária não conseguem passar por cima de um
  assento vendido na porta.

## Direcionadores de decisão

1. Ninguém paga sem assento.
2. Ninguém perde um assento que já tem.
3. Nenhum trabalho manual para agentes ou motoristas.

## Opções consideradas

A. Marcar a reserva como paga e trocar o outro passageiro de lugar.
B. Estender todo bloqueio para 30 minutos, para que aprovações
   tardias fiquem raras.
C. Estornar automaticamente, manter a passagem Expirada e oferecer
   os assentos livres mais próximos na mesma viagem.

## Decisão

Escolhemos C. Quando chega uma aprovação para uma passagem Expirada,
o serviço de reservas pede o estorno integral, com o id da reserva
como chave de idempotência, mantém a passagem Expirada e manda ao
passageiro um e-mail e uma notificação push oferecendo os três
assentos livres mais próximos na mesma viagem, bloqueados por dez
minutos.

## Consequências

- Nenhum passageiro é cobrado por um assento que não recebeu
  (direcionador 1).
- Nenhum passageiro que já tem um assento é trocado de lugar
  (direcionador 2).
- Cerca de 35 estornos por semana com tráfego normal, 140 na semana
  antes do São João, cada um custando a taxa de estorno do gateway.
- Um passageiro que pagou tarde pode perder um assento que queria, e
  pode encontrar a viagem lotada. Aceitamos isso; a opção B custaria
  a todo passageiro um bloqueio de 30 minutos em assentos que outros
  abandonam.
- A opção A foi rejeitada: troca de lugar um passageiro que não fez
  nada de errado.
- A máquina de estados ganha uma transição, Expirada --pagamento
  aprovado / estorno--> Expirada, e um teste a cobre.
```

## Lendo como revisor

- **O título é a decisão.** Quem passa os olhos pelo índice fica sabendo o que foi decidido sem abrir
  o arquivo.
- **Toda força pode ser conferida**, e duas apontam para registros anteriores, de modo que o log se
  lê como uma corrente.
- **O incidente está no contexto como um fato com data**, não como uma história. O leitor fica
  sabendo que ele aconteceu e quanto custou, numa linha.
- **A opção B está escrita com justiça**: ela funcionaria na maior parte das vezes. O custo dela
  aparece entre as consequências, onde pode ser pesado.
- **A consequência negativa é específica**: uma taxa de estorno, um número de estornos por semana, um
  passageiro que pode encontrar a viagem lotada. Cada uma pode ser conferida no extrato do gateway do
  mês seguinte.
- **A última consequência aponta de volta para o modelo.** Uma decisão que muda o comportamento deve
  mudar os diagramas que o descrevem, e dizer isso.

**Desenhe você mesmo.** Escreva o registro para um dos pontos de interrogação que você preencheu na
tabela de estados da aula 4, como *Embarcada × pagamento aprovado*. Mantenha numa página: forças,
direcionadores, pelo menos duas opções, a decisão e as consequências, incluindo pelo menos uma que
você preferia não escrever.
