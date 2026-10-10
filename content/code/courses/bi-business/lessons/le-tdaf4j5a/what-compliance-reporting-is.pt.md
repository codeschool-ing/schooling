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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Maquete do calendário de obrigações da Ipê na segunda, 12 de janeiro de 2026. Cinco linhas, cada uma com o relatório, a frequência, o responsável e a situação: os dados de crédito para o Banco Central, mensal, Fernanda, foto congelada e em revisão; a declaração mensal à Receita, financeiro, enviada e arquivada; o relatório de apetite a risco para o conselho, Fernanda, não iniciado e vencendo em 9 dias; os pedidos de titulares pela LGPD, o encarregado, 2 abertos, o mais antigo há 6 dias; a auditoria anual da carteira, financeiro, a foto de 31 de dezembro guardada.\" data-fig=\"l21-calendar\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"310.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Ipê · calendário de obrigações</text><text x=\"692.0\" y=\"40.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seg., 12/01/2026</text><text x=\"28.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">relatório</text><text x=\"290.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">frequência</text><text x=\"400.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">responsável</text><text x=\"505.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">situação</text><path d=\"M28.0 84.0 L692.0 84.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M18.0 100.0 H22.0 V116.0 H18.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"28.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Banco Central: dados de crédito (SCR)</text><text x=\"290.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mensal</text><text x=\"400.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Fernanda</text><text x=\"505.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">foto congelada, em revisão</text><text x=\"28.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Receita: declaração mensal</text><text x=\"290.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mensal</text><text x=\"400.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">financeiro</text><text x=\"505.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">enviado, arquivado</text><text x=\"28.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Conselho: relatório de apetite a risco</text><text x=\"290.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mensal</text><text x=\"400.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Fernanda</text><text x=\"505.0\" y=\"188.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não iniciado: vence em 9 dias</text><path d=\"M18.0 214.0 H22.0 V230.0 H18.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"28.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Pedidos de titulares (LGPD)</text><text x=\"290.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">quando chegam</text><text x=\"400.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">encarregado</text><text x=\"505.0\" y=\"226.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2 abertos, o mais antigo há 6 dias</text><text x=\"28.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Auditoria anual: carteira</text><text x=\"290.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">anual</text><text x=\"400.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">financeiro</text><text x=\"505.0\" y=\"264.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">foto de 31/12 guardada</text><text x=\"28.0\" y=\"304.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada relatório enviado guarda: data da foto, versão da definição, quem aprovou</text></svg>", "caption": "Um calendário de obrigações é uma tela operacional de relatórios: o que vence, de quem é e se pode ser reproduzido. As linhas que precisam de alguém nesta semana estão marcadas.", "same": ["Fernanda"]}
```
