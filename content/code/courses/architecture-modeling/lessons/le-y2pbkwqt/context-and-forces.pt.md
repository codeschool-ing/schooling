---
title: O contexto, escrito como forças
version: 1
---

**A seção de contexto descreve a situação que tornou uma decisão necessária, como um conjunto de
forças: fatos, restrições e pressões, algumas puxando em direções opostas.** É a parte de que um
leitor futuro mais precisa, porque é ela que diz se a decisão ainda se sustenta: se as forças
mudaram, a decisão talvez tenha de mudar também.

## Forças, não uma história

Um contexto fraco conta a história da reunião. Um forte lista o que era verdade:

> **Fraco.** Tivemos muitos problemas com reservas em dobro perto do São João e, depois de
> conversar, o time sentiu que a abordagem atual não estava funcionando, então olhamos algumas
> alternativas.

> **Forte.**
> - Os assentos ficam bloqueados como linhas no banco de reservas enquanto o passageiro paga.
> - No pico, são criados 1.800 bloqueios por minuto; 70% expiram sem pagamento.
> - Criar e expirar bloqueios é 40% da carga de escrita do banco no pico, e o banco fica em 85% de
>   CPU na semana antes do São João.
> - Um bloqueio tem de ser exclusivo: dois passageiros nunca podem bloquear o mesmo assento.
> - Perder um bloqueio é aceitável: o passageiro escolhe de novo. Perder uma reserva não é.
> - O time de Plataforma já roda Redis para sessões.

Cada linha da versão forte é um fato que alguém poderia conferir, e juntas elas explicam por que uma
mudança era necessária e o que qualquer opção tinha de respeitar. Duas delas, *um bloqueio tem de
ser exclusivo* e *perder um bloqueio é aceitável*, são as forças que a decisão final equilibra.

## A solução disfarçada

O defeito mais comum num contexto é defender a resposta. *Precisamos de um store em memória rápido
para os bloqueios* não é uma força; é a decisão, escrita antes da hora. Os leitores percebem, e um
contexto que só sustenta uma opção faz a seção de opções parecer teatro. **Escreva o contexto de
modo que um leitor consiga, só a partir dele, imaginar uma escolha diferente.** Se as forças só
permitem uma resposta, talvez nem tenha havido uma decisão a registrar.

## Números e datas

As forças envelhecem, e os números são como o leitor sabe o quanto. *O banco está ocupado* não quer
dizer nada daqui a dois anos. *85% de CPU no pico em junho de 2025* pode ser comparado com o que o
painel mostrar no dia em que alguém reabrir a pergunta. É também por isso que um registro traz a
data em que foi aceito, perto do status.

## Links, não cópias

O contexto deve ser legível sozinho, numa página. Ele aponta para as evidências em vez de colá-las:
o painel, o relatório do incidente da sexta-feira antes do São João, o documento de design. Um
leitor que confia no resumo não precisa segui-los; um que não confia pode.
