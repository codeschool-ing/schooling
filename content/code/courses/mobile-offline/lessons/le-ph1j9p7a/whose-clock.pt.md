---
title: O relógio de quem decide
version: 1
---

**"Última" precisa de um relógio, e cada relógio disponível dá uma resposta diferente.** A execução
da seção anterior usou os relógios dos próprios aparelhos, e só funcionou porque os dois estavam
certos. O relógio de um celular é acertado pela rede na maior parte do tempo e pela pessoa parte do
tempo, e nada impede que esteja errado por minutos ou por horas. A aula 11 encontrou o mesmo
problema com um cursor; aqui ele decide quem vence.

## Um celular duas horas adiantado

Dê ao celular um relógio duas horas adiantado. O programa recebe o adiantamento como argumento, em
minutos:

```
ana@dev:~/planner/lww$ node lww.ts device-clock phone=120
policy: device-clock, phone=120
10:05 phone   edits s3: minutes 20 -> 30, stamped 12:05
10:20 tablet  edits s3: done false -> true, stamped 10:20
10:40 tablet  syncs: 10:20 is newer than the server's row, kept
11:00 phone   syncs: 12:05 is newer than the server's row, kept
server s3: minutes 30, done false
```

A edição do celular foi feita às 10:05 e carimbada 12:05, então venceu a marcação do tablet, feita
um quarto de hora depois. Desta vez, quem se perde é `done`. **O aparelho com o relógio errado
vence todo conflito até alguém perceber o relógio**, e a dona desse celular nunca vai ver nada de
estranho: as edições dela sempre ficam.

## O relógio do servidor

O conserto óbvio é parar de confiar nos aparelhos e carimbar cada escrita quando ela chega. O
servidor tem um relógio só, ele é mantido certo, e ninguém consegue acertá-lo por um celular:

```
ana@dev:~/planner/lww$ node lww.ts server-clock
policy: server-clock
10:05 phone   edits s3: minutes 20 -> 30, stamped 10:05
10:20 tablet  edits s3: done false -> true, stamped 10:20
10:40 tablet  syncs: 10:40 is newer than the server's row, kept
11:00 phone   syncs: 11:00 is newer than the server's row, kept
server s3: minutes 30, done false
```

O adiantamento deixa de importar, e a resposta continua arbitrária. **O relógio do servidor ordena
as escritas pela chegada, que é quando cada aparelho por acaso achou rede.** O celular estava num
trem; chegou por último, então os 30 minutos dele venceram e a marcação se perdeu. Em outra manhã o
tablet sincroniza por último e é o outro campo que vai embora. A hora de chegada mede conexão, não
intenção.

| carimbo | quem vence | errado quando |
|---|---|---|
| o relógio do aparelho | a edição feita por último, pela conta daquele aparelho | um relógio está errado, ou foi acertado à mão |
| o relógio do servidor | o aparelho que sincronizou por último | os aparelhos ficaram offline por tempos diferentes |

Nenhum carimbo responde a pergunta que importa, que é a do começo da aula: quem escreveu por
segundo tinha visto a primeira escrita? Um relógio não sabe dizer. Um número de versão sabe, e a
aula 14 começa por aí. O que a tabela resolve é qual erro você prefere, e para a maioria dos apps o
relógio do servidor é o melhor dos dois: não dá para trapacear com ele, os erros dele não se acumulam
numa pessoa só, e ele é o mesmo para todo mundo.
