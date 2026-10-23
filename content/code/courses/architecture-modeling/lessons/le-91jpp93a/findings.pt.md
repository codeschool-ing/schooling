---
title: Escrevendo achados sobre os quais alguém vai agir
version: 1
---

**Uma revisão é julgada pelo que muda depois, e o que muda depende de como os achados são
escritos.** Um achado que nomeia uma impressão, *a sincronização do embarque parece frágil*, é
discutido e esquecido. Um achado que nomeia um cenário, uma causa, uma evidência e um próximo passo
ganha um responsável.

## A forma de um achado

| parte | o que diz | o achado da sincronização do embarque |
| --- | --- | --- |
| **título** | o risco numa linha | *Dois celulares enviando leituras de uma passagem podem os dois embarcá-la* |
| **cenário** | que cenário de qualidade está em risco | QS-02, embarque sem sinal, e a regra de que uma passagem embarca uma vez |
| **causa** | a decisão ou a lacuna por trás dele | o serviço de sincronização aceita cada envio como chega; nada concilia duas leituras de uma passagem |
| **evidência** | o que faz dele mais que um palpite | quatro revisores o levantaram cada um por conta própria; um teste com dois celulares e uma passagem embarcou duas vezes |
| **gravidade** | probabilidade e impacto | probabilidade média (um passageiro com um print), impacto alto (fraude, e um assento contado duas vezes) |
| **recomendação** | o que fazer, não como programar | decidir qual leitura vale e alertar na segunda; acrescentar o caso à tabela de estados da aula 4 |
| **responsável e data** | quem e até quando | time de Embarque, antes da versão do São João |

## Ordenação

Um relatório de revisão abre com os **temas de risco**, depois os achados ordenados por gravidade,
depois os não riscos com sua evidência. Catorze achados de peso igual não são um relatório; são uma
lista que deixa a ordenação para o leitor, que é a pessoa com menos contexto.

## O que o autor ouve

Os achados são sobre o design, e as pessoas que o fizeram estão na sala. Três hábitos mantêm isso
produtivo, todos conhecidos da aula 11 de `architecture-role` e dos postmortems sem culpados de
`architect-communication`:

- **Diga o cenário primeiro, depois o risco.** *O QS-02 pode falhar quando…* é sobre o sistema;
  *você esqueceu…* é sobre uma pessoa.
- **Separe achados de preferências.** Uma preferência, *eu teria usado outro broker*, é identificada
  como tal ou fica de fora.
- **Diga o que está bom.** Os não riscos com sua evidência fazem parte do relatório, e são o que o
  time vai citar quando alguém propuser mudar algo que funciona.

## Acompanhamento

Os achados de uma revisão vão para o mesmo tracker do resto do trabalho do time, com seus
responsáveis e datas, e a próxima revisão começa por lê-los. Na Carcará, os seis achados da internet
das rodoviárias foram fechados antes do São João; o achado da sincronização do embarque virou o
ADR-0022 e uma função de aptidão. **Uma revisão cujos achados não são acompanhados é uma reunião**, e
a próxima vai encontrar os mesmos riscos.
