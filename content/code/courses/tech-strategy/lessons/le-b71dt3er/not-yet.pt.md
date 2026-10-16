---
title: Ainda não, e a condição que muda isso
version: 1
---

"Ainda não" é a resposta mais útil que uma estratégia dá, e a mais fácil de usar mal. **Ela só é
honesta quando nomeia uma condição que outra pessoa consegue conferir e uma data em que alguém vai
olhar.** Sem essas duas coisas, é um não que foge da conversa, e o pedido volta em toda reunião de
planejamento até alguém dar a ele uma resposta de verdade.

## Três respostas que soam parecidas

Um tech lead tem mais de duas respostas para um pedido, e as do meio são onde mora a maior parte do
problema.

| resposta | o que promete | o que quem pede ouve |
|---|---|---|
| "não" | isso não vai acontecer sob a estratégia atual | uma decisão que pode aceitar ou escalar |
| "mais para frente" | nada | um sim sem data, então planeja em cima dele |
| "ainda não, quando…" | um sim no dia em que uma condição declarada se cumprir | uma decisão com um caminho de volta |

"Mais para frente" é a perigosa, porque parece gentil para quem fala. Quem pede ouve um sim, diz ao
festival que algo está vindo, e descobre no planejamento seguinte que nada foi agendado. **Um "mais
para frente" que ninguém anotou é um não entregue com meses de atraso**, depois que quem pediu já
gastou a própria credibilidade com ele.

Um não puro também tem seu lugar. A estratégia da Coreto diz com todas as letras que a migração para
microsserviços não começa este ano, e a aula 3 pôs isso na página, no que a empresa não vai fazer.
Um pedido para começar a extrair um serviço recebe um não, citando a página, e sem condição, porque
não há nada que o time possa observar este ano que mude a resposta, a não ser mudar a estratégia.

## Uma condição que outra pessoa consegue conferir

A ideia errada mais comum é que uma condição amacia o não. Ela faz o contrário: **uma condição
compromete o time com um sim no dia em que ela se cumpre**, e quem pediu pode cobrar. É por isso que
uma condição vaga é tentadora, e por isso que ela não vale nada.

Uma condição conferível tem três propriedades. Ela é observável — alguém pode olhar e ver se é
verdade. Ela não depende do humor nem da carga de quem fala. E ela tem um dono, que vai dizer quando
ela foi cumprida.

| vaga | conferível |
|---|---|
| "quando as coisas acalmarem" | "quando o teste de carga passar numa reprodução de abertura com reservas de grupo" |
| "quando tivermos capacidade" | "depois da remoção das travas, planejada para terminar em agosto" |
| "quando a plataforma estiver pronta" | "quando toda chamada do Checkout ao caminho da reserva passar pela nova interface" |

Leia a coluna da direita como Júlia leria. Cada linha diz a ela o que acompanhar e a quem perguntar.
A primeira diz até algo em que ela pode ajudar: se os tamanhos dos grupos do festival forem
conhecidos, o time de Reservas pode colocá-los no teste de carga agora, para que a reprodução de
agosto teste aquilo que ela quer.

## A data para olhar de novo

Algumas condições vêm com data porque a estratégia já tem uma: a remoção das travas termina em
agosto, então setembro é quando a questão das reservas de grupo pode ser decidida. Outras não vêm.
Um teste de carga pode falhar, e o time não consegue prometer o dia em que ele vai passar.

Quando a condição não tem data, dê a data em que alguém vai conferi-la. "Vamos olhar isso no
planejamento da primeira sprint de setembro, e o Mateus traz o resultado do teste de carga" é um
compromisso que o time consegue cumprir seja qual for o resultado. **A data de revisão é o que
impede um "ainda não" de se degradar num "mais para frente"**: ela põe a pergunta de volta na frente
de uma pessoa com nome, num dia com data.

## Guarde a lista onde a estratégia mora

Um "ainda não" é fácil de lembrar. Os de um trimestre inteiro, espalhados por sete times, não são, e os esquecidos viram
exatamente o "mais para frente" contra o qual esta seção alerta. Davi os guarda numa tabela curta ao
lado da página da estratégia:

| pedido | pedido por | condição | revisão | dono |
|---|---|---|---|---|
| reservas de grupo para o festival | Júlia | o teste de carga passa numa reprodução de abertura com reservas de grupo | primeira sprint de setembro | Mateus |

A tabela faz um segundo trabalho. Se três pedidos num trimestre esperam pela mesma condição, a
condição está custando algo ao negócio, e isso é evidência para a próxima revisão da própria
estratégia. A aula 20 trata dessa revisão, em que uma estratégia tem de defender suas escolhas para
quem paga por elas.

## Quando o "ainda não" é um disfarce

Um "ainda não" pode ser desonesto de um jeito que passa em todos os testes acima no dia em que é
dito. **A condição é definida depois do fato, ou muda cada vez que é cumprida.** O teste de carga
passa, e agora a condição é um segundo teste de carga; agosto chega, e agora é o fim do ano. Cada
mudança tem um motivo plausível, e juntas elas são um não que ninguém teve coragem de dizer.

Se você perceber que quer uma condição impossível de cumprir, diga não e dê o motivo. Quem pediu
pode escalar um não. Não pode escalar uma condição que vive se afastando, e vai deixar de acreditar
na próxima que você der, inclusive nas honestas.
