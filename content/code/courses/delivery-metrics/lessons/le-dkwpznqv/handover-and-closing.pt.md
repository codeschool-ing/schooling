---
title: Passar o comando, e saber quando acabou
version: 1
---

A maioria dos incidentes acaba em uma ou duas horas. Alguns não, e a última parte de conduzir um incidente é saber mantê-lo andando entre pessoas e horas, e como encerrá-lo direito.

## Passando o comando

Ninguém toma boas decisões na quinta hora de um incidente, e não se deveria esperar isso de ninguém. **Num incidente longo, o comandante do incidente passa o comando**, normalmente a cada poucas horas, e a passagem é ela mesma um pequeno procedimento:

1. **O IC que sai escreve um resumo no canal**: o que se sabe, o que foi feito, o que está em andamento, qual é a próxima decisão e quando ela vence.
2. **O IC que entra lê, faz perguntas, e diz em voz alta que assumiu o comando.** "Estou no comando" tira qualquer dúvida sobre quem decide.
3. **O escriba registra a passagem**, com o horário, como qualquer outro evento.
4. **O IC que sai sai de fato.** Ficar "para ajudar" divide o comando de novo.

O mesmo vale para o líder técnico e para o escriba. Uma escala para um incidente longo é montada cedo, enquanto as pessoas ainda estão descansadas o bastante para planejá-la, e não quando todo mundo está exausto.

## Quando acabou

Um incidente tem dois fins, e a linha do tempo de 30 de setembro registra os dois: **restaurado** às 18:15, quando não aconteciam mais cobranças duplicadas, e **resolvido** às 21:10, quando toda duplicata tinha sido estornada.

É razoável rebaixar um incidente quando ele está restaurado. Um SEV1 que não está mais prejudicando ninguém pode virar um SEV3 enquanto a limpeza corre no horário comercial, e quem não é necessário para a limpeza pode ser dispensado. É um erro **fechá-lo** antes de estar resolvido, porque fechar diz a todo mundo, suporte incluído, que não há mais nada a dizer às pessoas afetadas.

## Fechando direito

Quando o incidente está resolvido, o comandante do incidente faz quatro coisas antes de fechá-lo:

- **publica uma atualização final** para cada público, dizendo o que aconteceu nos termos dos usuários, que acabou, e o que acontece em seguida para quem foi afetado;
- **garante que as evidências sejam guardadas**: logs, gráficos, o canal, a linha do tempo, antes que as políticas de retenção os apaguem;
- **marca o postmortem**, para dali a poucos dias úteis, enquanto as lembranças estão frescas, como a atualização final de Caio em 30 de setembro fez para sexta-feira, 2 de outubro;
- **abre um ticket para qualquer sobra** que não seja urgente: a correção de verdade do `BIL-218`, neste caso, em vez do rollback.

Esse último ticket é a ponte para a aula 15. O rollback mitigou o incidente; a correção virá de entendê-lo, e entender é para que serve o postmortem.
