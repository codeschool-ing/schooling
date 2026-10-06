---
title: Decidindo, e combinando os dois
version: 1
---

A comparação se resume a uma pergunta feita a cada coisa que você quer que o modelo faça: **isso é
conhecimento ou comportamento?** O conhecimento muda, tem de ser citado, talvez tenha de ser apagado e é
diferente para leitores diferentes; ele pertence a documentos que um sistema de recuperação põe no
prompt. O comportamento é o mesmo em toda resposta e é caro de repetir; é candidato a fine-tuning,
depois que um prompt provou que vale a pena tê-lo.

| do que você precisa | recuperação | fine-tuning |
| --- | --- | --- |
| respostas sobre os seus documentos | sim | não: fatos ficam presos de leve e não se rastreiam |
| respostas que mudam com os documentos | sim, em minutos | só depois de um retreino |
| uma fonte para cada resposta | sim, o texto recuperado | não: uma citação seria texto aprendido |
| poder apagar o que ele sabe | sim, apague as linhas | não: treine de novo a partir do modelo base |
| respostas diferentes para leitores diferentes | sim, filtre o que é recuperado | não: um modelo sabe o mesmo para todos |
| um formato rígido ou estilo da casa | em parte, por instruções | sim |
| um prompt curto em volume muito alto | não: o contexto é pago por pergunta | sim |
| uma resposta dentro de um orçamento de latência apertado | ela acrescenta uma busca | sim, para um conjunto pequeno e estável de fatos |

## Primeiro o prompt, depois a recuperação, depois o fine-tuning

A ordem em que as equipes deveriam tentá-los decorre do custo de cada um.

**Comece pelo prompt.** Instruções e alguns exemplos no prompt de sistema não custam nada para mudar, e
estabelecem se o comportamento é alcançável. O `prompt-engineering` e o `prompt-reliability` tratam de
fazer isso bem.

**Acrescente recuperação para o conhecimento.** Assim que as respostas dependem de documentos que o
modelo não viu, o que para uma empresa é quase de imediato, a recuperação é a única abordagem que se
mantém atual, cita suas fontes e consegue apagar. A maior parte deste curso trata de fazê-la bem.

**Ajuste por último, para o comportamento que os prompts não seguram.** Quando um prompt provou que um
comportamento vale a pena e ele ainda se desvia, ou custa demais repeti-lo no seu volume, um fine-tuning
nas respostas que você quer, com a recuperação ainda fornecendo os fatos, faz dele um hábito do modelo.

## Usando os dois

Os dois não são alternativas, e os sistemas mais fortes os usam juntos. Um modelo ajustado em algumas
centenas de respostas de atendimento aprende a responder primeiro, citar cada afirmação com o número da
fonte, ficar em duas frases e recusar quando as fontes se calam. Na hora da consulta, a recuperação lhe
dá as fontes. O fine-tuning ensinou **como** usar uma fonte; a recuperação decide **quais** fontes ele
tem.

O que nunca pode atravessar a linha é o conhecimento. A segunda linha do `ft.jsonl` lembra com que
facilidade ele atravessa: um conjunto de treinamento montado sem cuidado a partir de documentos ensina
os documentos, inclusive os que estavam errados, e nada depois consegue apontar a linha que causou isso.
