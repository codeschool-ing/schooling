---
title: O que é relatório regulatório
version: 1
---

Todo relatório deste curso até aqui foi pedido por alguém de dentro da empresa, e a empresa escolheu
as definições, o prazo e se ia produzi-lo ou não. **O relatório regulatório é o que alguém de fora
exige: a definição é dele, o prazo é dele, e errar qualquer um dos dois tem multa.** Isso muda mais o
jeito de fazer o trabalho do que o trabalho em si, e esta aula é sobre essa mudança.

As aulas 17 a 20 leram quatro setores com as quatro perguntas da aula 17. O regulatório não é um
setor; é uma camada que todo setor tem. Então esta aula faz as perguntas uma vez para essa camada:

| a pergunta da aula 17 | para o relatório regulatório |
|---|---|
| as decisões tomadas sem parar | nenhuma é da empresa: a decisão é de um regulador, de um auditor ou do fisco, e a empresa fornece a evidência |
| os indicadores que servem a elas | o que a regra define, nas palavras da regra, e nada que a empresa possa redefinir |
| os dados, e o que eles têm de estranho | precisam ser os dados **como estavam numa data**, e precisa ser possível mostrá-los de novo anos depois |
| a armadilha típica | dois números com um nome só, o de fora e o de dentro, levados em silêncio a concordar |

## Quem pede, por setor

Os exemplos abaixo estão no nível do que toda empresa do setor sabe. As regras em si são longas,
mudam com frequência e são trabalho do jurídico e da área de compliance da empresa; a parte do
analista de BI é produzir os números que elas exigem, sempre do mesmo jeito.

- **Todo mundo presta contas ao fisco.** No Brasil, é a Receita Federal, e as empresas mandam os seus
  registros fiscais e contábeis eletronicamente pelo Sistema Público de Escrituração Digital, o SPED.
  As vendas, as compras e a folha de pagamento da Varanda acabam todas ali. Um número nesses arquivos
  que não bate com a contabilidade não é um erro de relatório para corrigir no mês seguinte; é um
  problema fiscal.
- **Uma financeira presta contas ao Banco Central.** A Ipê Crédito, da aula 17, manda dados sobre os
  empréstimos dos seus clientes ao Sistema de Informações de Crédito do Banco Central, o SCR, e o
  Banco Central define como os empréstimos são classificados e o que conta como atraso nesses
  relatórios.
- **Um hospital presta contas às autoridades de saúde.** O Jacarandá, da aula 19, precisa notificar
  casos de certas doenças à vigilância em saúde, e informa o que faz pelos pacientes do Sistema Único
  de Saúde, o SUS, que é também como recebe por eles.
- **Quem guarda dados pessoais responde à LGPD**, fiscalizada pela ANPD: a Varanda pelos clientes e
  funcionários, a Ipê pelos tomadores de crédito, o Jacarandá pelos pacientes. A LGPD pede menos
  relatórios periódicos que os outros e mais respostas sob demanda, que é o assunto da seção desta
  aula sobre a lei.

## O que muda para o analista

**A definição não é sua para escolher.** O cartão de KPI da aula 10 tem uma linha para a fórmula, e
num KPI interno a empresa a escreve. Num relatório regulatório, a linha é copiada da regra, palavra
por palavra, com o nome e a versão da regra ao lado. Se a regra for ambígua, a resposta vem da área de
compliance ou do regulador, por escrito, e a resposta escrita fica guardada.

**O prazo não é meta.** Um e-mail mensal de vendas que chega às onze em vez das nove é um incômodo.
Um arquivo regulatório que chega um dia atrasado pode render multa, e o trabalho é planejado de trás
para frente a partir da data, com a foto dos dados congelada e a revisão feita dias antes.

**E o relatório é evidência.** Um painel interno que estava errado em março passado é corrigido e
esquecido. Um relatório mandado a um regulador em março passado continua mandado, e se alguém
perguntar por ele daqui a dois anos a empresa precisa mostrar como cada número foi produzido. **Essa
exigência sozinha faz do relatório regulatório a forma mais estrita do BI definido na aula 1**:
registros transformados em respostas sempre do mesmo jeito, e capazes de provar isso.

A Ipê mantém todas as suas obrigações numa página só, que é uma tela operacional no sentido da aula
14, para relatórios em vez de entregas:

@@fig:l21-calendar@@
