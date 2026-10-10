---
title: Escolher tecnologia, o problema primeiro
version: 1
---

**Uma tecnologia é escolhida contra um problema e um time, nunca contra um ranking.** O jeito comum de
dar errado é começar pela ferramenta: o que as maiores empresas usam, o que estava no palco da última
conferência, o que é "a melhor". A melhor ferramenta para uma empresa que guarda petabytes é uma
ferramenta ruim para a Roda Livre, cujos sensores das docas produzem alguns gigabytes por ano, porque
ela traz junto os custos dos petabytes.

Sete critérios cobrem a maioria das escolhas, e a ordem importa: os dois primeiros podem descartar uma
opção antes que valha a pena discutir os outros.

## O problema

O que precisa ser verdade quando isto funcionar? As perguntas da seção de habilidades dão a resposta:
Marta precisa da contagem por estação antes de duas saídas da van por dia, com dados de uma ou duas
horas. Isso ainda não descarta nada, e já faz um processador de fluxos responder a uma pergunta que
ninguém fez.

## O time

**Uma ferramenta só está tão disponível quanto as pessoas que sabem consertá-la.** O time da Roda Livre
tem duas pessoas. Um sistema que só Davi entende é um sistema com uma pessoa de plantão, toda noite,
enquanto ele existir. O que o time já sabe conta como um ativo de verdade, porque aprender custa meses,
e os primeiros meses numa ferramenta nova são quando ela falha de jeitos que ninguém reconhece.

## O custo total

A conta é uma linha dele. O resto são as horas que as pessoas gastam mantendo a coisa funcionando, e o
que custaria sair dela. Uma seção no fim desta aula faz a conta.

## Gerenciado ou hospedado por conta própria

**Gerenciado** quer dizer que um fornecedor roda o software e você paga pelo que usa: nenhum servidor
para atualizar, menos controle, e uma conta que cresce com o uso. **Hospedado por conta própria** quer
dizer que você roda em máquinas que controla: uma conta menor e mais horas. Nenhum dos dois é mais
barato em geral. Para um time de dois, as horas costumam ser o recurso mais escasso, e para um time de
vinte com uma conta grande o equilíbrio pode pender para o outro lado.

## Aprisionamento

Aprisionamento (*lock-in*) é o custo de sair, e toda escolha tem algum. Ele cresce com cada coisa que só
funciona num lugar: um dialeto de SQL com funções que ninguém mais tem, dados guardados num formato
que só um produto lê, jobs escritos contra a interface de um único fornecedor. **Formatos abertos o
reduzem**: dados brutos guardados como arquivos Parquet, que a aula 6 apresenta, podem ser lidos por
dezenas de motores, então o motor pode mudar e o dado fica. Aprisionamento não é motivo para recusar
todo serviço gerenciado. É um preço para conhecer antes de assinar.

## Maturidade

Há quanto tempo está em uso em produção, quantas pessoas o usam, e quando falha, uma busca pela
mensagem de erro encontra alguém que já viu aquilo? Uma versão numerada 0.x está avisando que os
autores ainda esperam mudá-la de jeitos que quebram o seu código. Maturidade não é só idade; é o
tamanho da população que já topou com os problemas que você está prestes a topar.

## Reversibilidade: portas de mão única e de mão dupla

A carta de Jeff Bezos aos acionistas da Amazon referente a 2015 dividiu as decisões em dois tipos.
Uma **porta de mão dupla** permite voltar: se a decisão estava errada, você a desfaz a um custo
modesto, então ela deve ser tomada rápido, por quem está mais perto dela. Uma **porta de mão única**
não permite, ou só a um custo alto, e merece reflexão lenta e cuidadosa. O erro nas duas direções é
comum: agonizar um mês diante de uma porta de mão dupla, e atravessar uma porta de mão única numa
tarde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um eixo horizontal vai das portas de mão dupla, baratas de desfazer e decididas rápido, às portas de mão única, impossíveis de desfazer e decididas devagar. Ao longo dele: a ferramenta de painéis, uma semana para refazer os gráficos; o formato dos arquivos brutos, todo arquivo guardado reescrito; o banco analítico, meses para mudar cada consulta e carga; apagar os arquivos brutos depois de trinta dias, o que não pode ser desfeito.\" data-fig=\"doors\"><defs><marker id=\"doors-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"40\" y1=\"120\" x2=\"684\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#doors-ah)\"></line><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">mão dupla: decida rápido</text><text x=\"684\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">mão única: decida devagar</text><circle cx=\"110\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></circle><rect x=\"28\" y=\"22\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"40.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">a ferramenta de painéis</text><text x=\"110.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma semana de gráficos</text><line x1=\"110\" y1=\"74\" x2=\"110\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><circle cx=\"280\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><rect x=\"198\" y=\"166\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"184.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">o formato dos brutos</text><text x=\"280.0\" y=\"199.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reescrever cada arquivo</text><line x1=\"280\" y1=\"127\" x2=\"280\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><circle cx=\"450\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></circle><rect x=\"368\" y=\"22\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"40.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">o banco analítico</text><text x=\"450.0\" y=\"55.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">meses: toda consulta muda</text><line x1=\"450\" y1=\"74\" x2=\"450\" y2=\"113\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><circle cx=\"612\" cy=\"120\" r=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><rect x=\"530\" y=\"166\" width=\"164\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"612.0\" y=\"184.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">apagar brutos após 30 dias</text><text x=\"612.0\" y=\"199.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não pode ser desfeito</text><line x1=\"612\" y1=\"127\" x2=\"612\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line></svg>", "caption": "Quatro decisões desta aula, posicionadas pelo custo de desfazê-las. Só a última não pode ser desfeita de jeito nenhum, e é a mais barata de tomar."}
```

**A maioria das decisões de tecnologia é mais reversível do que parece, e algumas são menos.** Trocar a
ferramenta de painéis custa uma semana refazendo gráficos. Apagar os arquivos brutos depois de trinta
dias para economizar armazenamento não custa nada para decidir e não pode ser desfeito de jeito
nenhum: uma pergunta feita no ano que vem sobre este ano não tem mais nada que a responda. A segunda
decisão é a que precisa da reunião.
