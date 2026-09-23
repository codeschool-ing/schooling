---
title: Discordar bem, e saber quando parar
version: 1
---

Às vezes quem revisou está errado, e dizer isso faz parte do trabalho. Um pull request em que quem escreveu
aceitou todos os comentários para evitar atrito não é uma boa revisão. É uma revisão em que só uma pessoa
pensou.

## Discorde uma vez, com um motivo

Suponha que a Ana tivesse escrito *"blocking: use uma lista de horários em vez de um campo de hora."* O
Bruno acha o campo melhor, porque uma lista de trinta opções é lenta de usar no celular. A resposta que
funciona:

> Fui no campo de hora porque uma lista com cada meia hora são trinta opções, e a maioria dos pedidos vem
> do celular. Com `min` e `max` não dá para sair do horário de funcionamento. Isso cobre o que te
> preocupava?

Ela diz **o que ele escolheu, por quê, e pergunta qual era a preocupação**. Talvez a preocupação da Ana
fosse gente digitando 7:13; aí a resposta é `step="1800"`, e os dois tinham parte da razão. Uma resposta
que diz *"prefiro o campo"* não dá nada para ela pesar, e a conversa dá outra volta.

## Quando parar de digitar

Duas rodadas de respostas que não convergem são o sinal. Uma terceira rodada escrita raramente resolve, e
cada mensagem fica um pouco mais curta e um pouco mais fria. **Conversem**: uma ligação de cinco minutos,
ou uma conversa na mesa ao lado. Depois escreva o resultado na conversa em uma linha, para o registro dizer
o que foi decidido e por quê, para quem ler depois.

## Quem decide

- **Um defeito que bloqueia** (não funciona, perde dados, não é seguro): corrigido antes do merge, e quem
  revisa não deve aprovar até estar.
- **Uma preferência rotulada como bloqueio**: quem escreveu pode discordar, como acima. Se é preferência
  dos dois lados e nada está em jogo, **o mais barato muitas vezes é simplesmente fazer** e gastar a energia
  em outra coisa. Uma vez. Se o assunto volta sempre, já não é uma questão de revisão.
- **Um padrão que volta sempre** (duas pessoas que discordam da mesma coisa em todo pull request) é da
  equipe, não da conversa. Decidam uma vez e escrevam, no mesmo `CONTRIBUTING.md` que a aula 9 sugeriu.
  Depois disso, a resposta ao comentário é um link.

## Depois

Agradeça, de verdade. Alguém passou meia hora lendo o seu trabalho para um cliente não ter de achar os bugs
dele. Depois repare no que apareceu. Se três revisões seguidas acham um `required` faltando, isso é um item
de checklist para o próximo formulário, e a quarta revisão não vai precisar dizer.
