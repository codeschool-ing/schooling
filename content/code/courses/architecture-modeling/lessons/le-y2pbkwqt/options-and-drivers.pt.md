---
title: Direcionadores de decisão e as opções que você não escolheu
version: 1
---

**Um registro que só nomeia a opção escolhida diz ao leitor o que foi feito; um que nomeia as opções
consideradas diz o que se sabia.** O segundo é o que impede um sucessor de "descobrir" a alternativa
que já foi tentada, e é o que deixa o leitor julgar a decisão em vez de aceitá-la por confiança.

O formato original de Nygard dobra as opções para dentro do contexto. O **MADR**, *Markdown Any
Decision Records*, um template muito usado e mantido desde 2017, dá a elas seções próprias, e vale a
pena tomar emprestada a estrutura dele mesmo que você mantenha os títulos de Nygard:

- **direcionadores de decisão**: as poucas forças que vão decidir entre as opções, escritas como
  critérios;
- **opções consideradas**: cada uma nomeada, numa linha;
- **prós e contras de cada opção**, medidos contra os direcionadores;
- **resultado da decisão**: a opção escolhida, e a razão, numa frase, por que ela vence.

As versões recentes do MADR também perguntam como a decisão vai ser **confirmada**: que revisão,
teste ou medição vai mostrar que ela foi seguida. A aula 11 volta a essa ideia.

## Primeiro os direcionadores

Os direcionadores são escolhidos **antes** de comparar as opções, a partir das forças do contexto.
Para os bloqueios de assento da Carcará, saíram quatro:

1. **D1 exclusividade**: dois passageiros nunca bloqueiam o mesmo assento;
2. **D2 carga**: o tráfego de bloqueios tem de sair do banco de reservas;
3. **D3 operação**: nada que o time de Plataforma não consiga operar numa sexta à noite;
4. **D4 custo da mudança**: semanas de trabalho, não meses.

Fixá-los antes importa porque, do contrário, a comparação vai escorregando para o que o autor já
preferia: cada opção é julgada pelo critério em que por acaso ela ganha.

## Comparando três opções com honestidade

| | D1 exclusividade | D2 carga | D3 operação | D4 mudança |
| --- | --- | --- | --- | --- |
| **A. manter os bloqueios no PostgreSQL, ajustar os índices** | sim, por restrição de unicidade | não: continua 40% das escritas | sim, nada novo | sim, dias |
| **B. bloqueios no Redis, uma chave por assento com expiração de 10 minutos** | sim, por set-if-absent | sim: nenhum chega ao banco | sim: a Plataforma já roda Redis | sim, umas três semanas |
| **C. um serviço de inventário de assentos à parte, com banco próprio** | sim | sim | não: um serviço e um store novos para operar | não, um trimestre |

Dois hábitos deixam uma tabela assim honesta:

- **Escreva a defesa da opção perdedora como os defensores dela escreveriam.** A opção A não é *não
  fazer nada*; é *o sistema mais simples, sem nenhuma peça nova*, e essa é uma força real que a
  tabela deve mostrar.
- **Diga quanto cada opção custa, não só o que ela ganha.** A opção B abre mão de algo para o qual a
  tabela acima nem tem coluna: os bloqueios passam a viver num store que pode perder dados ao
  reiniciar. Isso pertence às consequências, e a próxima seção é sobre escrever isso.

## Quando só havia uma opção

Às vezes havia de fato uma só, porque uma regulação, um contrato ou uma decisão anterior a fixou.
Diga isso, e aponte para o que a fixou: *usamos a empresa de pagamento escolhida no ADR-0003; nenhuma
outra foi considerada*. Um registro sem opções não tem problema; um registro que finge ter opções que
nunca pesou tem.
