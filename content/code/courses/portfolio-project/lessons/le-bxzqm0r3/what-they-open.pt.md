---
title: O que abrem primeiro, na sua área
version: 1
---

Em todas as áreas vale uma regra: **quem avalia abre o que está mais perto do trabalho que daria a você
na primeira semana.** O que isso é muda muito de uma área para outra. Abaixo está a parte da sua trilha;
a escolha ao lado mostra as outras.

::: track frontend
**Front-end.** O link no ar, primeiro, e muitas vezes no celular. Depois as ferramentas de
desenvolvimento do navegador: carrega rápido, o layout continua são em 320 pixels, dá para usar o
formulário só com o teclado? Só então o código, e ali se olha como o estado circula e se os estados de
carregamento, vazio e erro existem. Um bom projeto é **uma interface para dados reais com todos os
estados desenhados**, não a cópia de um site famoso que só funciona no caminho feliz.
:::

::: track mobile
**Mobile.** Raramente vão instalar o seu app, então a primeira coisa é **um vídeo curto num aparelho de
verdade** e um jeito de experimentar se quiserem: uma página na loja, um build de teste, um APK. Depois as
telas: o que acontece sem rede, como as permissões são pedidas, se segue as convenções da plataforma. No
código olham estado e navegação. Um bom projeto **faz bem uma tarefa no celular**, com a rede faltando
metade do tempo.
:::

::: track backend
**Back-end.** A seção de API do README, com requisições de exemplo e as respostas que elas recebem, erros
incluídos. Depois os testes, e se a regra que mais pode quebrar tem um. Depois como rodaria:
configuração, uma migração, um health check. Um bom projeto é **um serviço com uma regra de verdade**,
como algo que não pode acontecer duas vezes, e um relato claro do que ele recusa e por quê. O loanbook é
isso.
:::

::: track ai
**Engenharia de IA.** Não a tela de chat. Procuram **a avaliação**: um conjunto de entradas de teste, o
que conta como boa resposta, e os resultados anotados, antes e depois de uma mudança. Depois custo e
latência, medidos e não chutados, e o que a aplicação faz quando a resposta do modelo está errada ou
malformada. Um bom projeto **usa um modelo para uma tarefa e mostra com que frequência ele acerta**.
:::

::: track prompt
**Engenharia de prompt.** Os prompts, versionados como código, e **o conjunto de testes em que foram
medidos**. Quem avalia quer ver duas versões de um prompt comparadas nas mesmas entradas, as falhas
listadas em vez de escondidas, e a proteção que trata os casos em que o prompt erra. Um bom projeto
**pega uma tarefa real e documenta como o prompt dela foi melhorado**, com os números.
:::

::: track data
**Engenharia de dados.** O pipeline, e o diagrama dele no README. Depois as perguntas que separam um
script de um pipeline: o que acontece quando ele roda duas vezes, o que acontece quando a fonte manda
algo malformado, onde estão as verificações de qualidade dos dados. Um bom projeto **leva um conjunto de
dados público de verdade, num agendamento, para algo consultável**, e sobrevive a rodar de novo.
:::

::: track data-science
**Ciência de dados.** O resultado primeiro: um relatório ou notebook renderizado que enuncia uma
pergunta e a responde. Depois o método por trás: uma linha de base a superar, como o modelo foi
validado, o que os números não mostram. Um notebook de duzentas células sem explicação é lido como
rascunho. Um bom projeto **responde a uma pergunta específica com limites honestos**, e roda de novo a
partir de um ambiente limpo.
:::

::: track bi
**Business intelligence.** O painel, por um link público ou capturas de tela claras. Depois as
definições: o que exatamente cada métrica conta, de onde vêm os dados, e que decisão o painel deve
apoiar. Um bom projeto **responde a uma pergunta que alguém num negócio faria**, com métricas definidas
por escrito e uma página, não doze.
:::

::: track devops
**DevOps e SRE.** O arquivo do pipeline, e o que ele faz de um commit até algo rodando. Depois como o que
roda é observado: um health check, uma métrica, um alerta que dispara. A gravação de um deploy, e melhor
ainda de um que falhou e foi revertido, diz mais do que um diagrama. Um bom projeto **implanta uma carga
pequena de forma repetível e percebe quando ela quebra**.
:::

::: track devsecops
**DevSecOps.** O pipeline, e em especial os portões de segurança dele: análise de dependências, busca de
segredos, análise estática, e o que o build faz quando um deles encontra algo. Procuram **um achado que
foi triado**: corrigido, ou aceito com um motivo escrito. Um bom projeto **põe verificações de segurança
num pipeline de verdade e mostra um achado tratado de ponta a ponta**.
:::

::: track cloud-engineering
**Engenharia de nuvem.** A infraestrutura como código, e um diagrama de arquitetura que bate com ela.
Depois as anotações em volta: quanto custaria para rodar, e como é desmontada. Quem avalia confere que
nada foi criado à mão. Um bom projeto **constrói uma arquitetura pequena a partir de código, documenta o
custo e se destrói de forma limpa**, para nunca virar uma conta.
:::

::: track it-support
**Suporte de TI.** Documentação, primeiro: um runbook que outra pessoa conseguiria seguir, com capturas
de tela. Depois a evidência de que o ambiente por trás funciona: usuários e permissões configurados, um
backup e, acima de tudo, **uma restauração que foi testada**. Um bom projeto **é o ambiente de um pequeno
escritório que você montou num laboratório e documentou bem o bastante para um colega reconstruir**.
:::

::: track networks-infra
**Redes e infraestrutura.** O diagrama da topologia, e as configurações sob controle de versão. Depois os
testes: alcance entre segmentos, o que acontece quando um enlace cai. Um bom projeto **é uma rede de
laboratório construída a partir de arquivos de configuração, com um diagrama e um teste que prova o
failover**, tudo reproduzível por outra pessoa.
:::

::: track dba
**Administração de bancos de dados.** O relato de uma investigação: uma consulta lenta, o plano antes e
depois, o índice ou a reescrita que resolveu, medido. Depois os procedimentos: um backup, e uma
restauração feita de verdade. Um bom projeto **é um esquema real sob dados realistas, com um problema de
desempenho encontrado e resolvido por escrito**.
:::

::: track qa
**QA.** Os relatos de bug, primeiro: passos claros, resultado esperado e obtido, evidência. Depois a suíte
de testes e uma execução dela no CI, e o plano de testes que explica por que esses casos e não outros. Um
bom projeto **testa a aplicação ou API real de outra pessoa, encontra defeitos reais e os relata bem**.
:::

::: track security
**Segurança.** Uma avaliação escrita: escopo, método, achados com severidade e evidência, e o que fazer
com cada um. Tudo é feito **só contra sistemas que você tem autorização para testar**, como uma aplicação
de prática deliberadamente vulnerável no seu próprio laboratório, e o relatório diz isso na primeira
página. Um bom projeto **se lê como um relatório sobre o qual um cliente conseguiria agir**.
:::

::: track *
**Qualquer que seja a área**, descubra o que ela abre perguntando a duas pessoas que trabalham nela, e
lendo os anúncios de vaga do jeito que a próxima seção descreve. Depois construa a coisa mais próxima de
uma tarefa da primeira semana.
:::
