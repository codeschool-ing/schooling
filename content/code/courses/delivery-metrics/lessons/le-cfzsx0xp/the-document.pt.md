---
title: O que o documento de postmortem contém
version: 1
---

Um postmortem é primeiro um documento e depois uma reunião. O documento é escrito antes da reunião, a partir da linha do tempo do escriba e do canal do incidente, por uma pessoa, normalmente o comandante do incidente ou um voluntário do time, e a reunião o revisa. A maioria das organizações usa um modelo; este é um formato comum, preenchido para 30 de setembro.

## As seções

| seção | o que diz | para 30 de setembro |
|---|---|---|
| **resumo** | três frases que um estranho entende | O deploy D047 acrescentou uma nova tentativa às cobranças no cartão. Sob a carga de fim de mês, ele cobrou 167 lojas duas vezes, 212 cobranças ao todo, durante 54 minutos. Um rollback o interrompeu; toda cobrança foi estornada até as 21:10. |
| **impacto** | quem foi afetado, quanto, por quanto tempo, em números | 167 lojas, 212 cobranças duplicadas, 54 minutos de dano, 229 minutos até o estorno completo; o suporte atendeu 31 ligações |
| **linha do tempo** | as linhas do escriba, levemente editadas | a linha do tempo da aula 14 |
| **fatores contribuintes** | todos os fios, não uma causa raiz | os seis da seção anterior |
| **o que deu certo** | vale manter, e vale dizer | o suporte perguntou em três minutos; papéis nomeados numa só mensagem; o rollback levou onze minutos |
| **o que foi difícil** | onde a resposta teve dificuldade | dezesseis minutos para decidir pelo rollback; ninguém conhecia o padrão de carga do fim de mês |
| **itens de ação** | específicos, com dono, com data | a próxima seção |
| **lições** | o que o time agora acredita e antes não acreditava | novas tentativas de pagamento precisam de chaves de idempotência, sempre; o fim do mês é um momento arriscado para fazer deploy |

## Escrevendo bem

**Escreva para alguém que não estava lá.** Uma pessoa nova no time daqui a um ano, outro time com um sistema parecido. Isso quer dizer nenhum jargão sem explicação, horários num só fuso, e o impacto nos termos dos usuários antes de qualquer coisa técnica.

**Separe a linha do tempo da análise.** A linha do tempo diz o que aconteceu; os fatores dizem por que foi possível. Misturadas, a análise vaza para a linha do tempo como retrospectiva: "17:20 o deploy defeituoso foi feito" não se sabia defeituoso às 17:20.

**Ponha os nomes nas ações e tire-os das falhas.** "Rafa vai acrescentar uma chave de idempotência, até 9 de outubro" pertence ao documento. "A nova tentativa de Rafa causou o incidente" não pertence, pelos motivos da segunda seção desta aula.

**Publique.** No mínimo dentro do time, e idealmente na organização toda. Um postmortem que ninguém mais lê ensina um time; o mesmo documento lido por cinco times com sistemas de pagamento ensina cinco. Algumas organizações fazem uma sessão regular em que os times leem os postmortems uns dos outros, e é uma das formas mais baratas de aprendizado que existem.

## Quando escrever um

Não para todo incidente. Uma regra comum é **todo SEV1 e SEV2, e qualquer incidente para o qual alguém peça um**, mais os quase acidentes que assustaram as pessoas. A escala da aula 13 decide a maioria dos casos; a regra do pedido pega o resto, e ela deve ser honrada mesmo quando o incidente pareceu pequeno, porque quem pede normalmente viu algo que a escala não viu.
