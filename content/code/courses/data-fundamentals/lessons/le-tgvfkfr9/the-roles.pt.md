---
title: Cinco cargos com "dados" no nome
version: 1
---

**A imagem comum é uma escada: o analista vira cientista de dados, e o engenheiro de dados é um
cientista de dados que escreve mais código.** Está errada nas duas metades. Os cargos não são degraus,
são respostas diferentes para *o que você entrega*, e uma pessoa passa de um para outro de lado.

## O que cada um entrega

| cargo | o que entrega | quem lê | o que dá errado quando falta |
|---|---|---|---|
| **engenheiro de dados** | dado que chega, na hora, correto, num formato que dá para consultar | os outros quatro, e os sistemas que eles constroem | toda análise começa com uma semana copiando arquivo à mão |
| **engenheiro de analytics** | as tabelas e as definições que o negócio aceita: o que é uma "viagem" ou um "cliente ativo" | analistas e painéis | dois painéis dão dois números para a mesma coisa |
| **analista de dados** | respostas a perguntas que foram feitas: um número, um gráfico, uma recomendação | gestores, operação, financeiro | as decisões saem da opinião mais alta |
| **cientista de dados** | modelos e experimentos: uma previsão, uma estimativa do que causou o quê | produto e operação | ninguém sabe dizer se o preço novo funcionou |
| **engenheiro de machine learning** | um modelo rodando em produção, alimentado e monitorado | o aplicativo | o modelo funciona num notebook e em nenhum outro lugar |

Dois dos cinco merecem um segundo olhar, porque o nome engana.

**O engenheiro de analytics** fica entre o primeiro e o terceiro: alguém que escreve SQL com os hábitos
de um engenheiro de software, versionado e testado, para que as definições do negócio morem num lugar
só. O título tem uns dez anos, e muitas empresas dão esse trabalho a quem dos outros dois tiver tempo.
`warehouse-modeling` é a maior parte desse ofício.

**O engenheiro de machine learning** é um engenheiro de software cujo produto por acaso contém um
modelo. O cientista de dados decide *o que* o modelo deve prever e prova que ele prevê; o engenheiro
de ML faz o modelo responder em cinquenta milissegundos, sempre, e percebe quando as previsões começam a
desviar.

## Onde o engenheiro de dados é diferente

Os outros respondem perguntas. **O engenheiro de dados constrói a coisa a quem as perguntas são
feitas**, e isso muda o formato do trabalho de três jeitos:

- **É software, e roda todo dia.** Uma análise termina quando é entregue. Um pipeline nunca termina:
  roda hoje à noite, e amanhã à noite, contra uma fonte que mudou de formato sem avisar ninguém.
- **Os usuários são, na maioria, outros sistemas e outras pessoas de dados.** Marta nunca vê o trabalho
  de Davi, só a falta dele.
- **As falhas são silenciosas.** Um gráfico errado está errado onde alguém pode ver. Um pipeline que
  carrega o arquivo de ontem duas vezes produz um gráfico de aparência perfeita, e dobra cada número
  dele.

## As sobreposições são reais

Numa empresa do tamanho da Roda Livre, duas pessoas fazem os cinco trabalhos. Davi escreve os pipelines
e também o SQL que define uma viagem; Caio treina um modelo e também o põe em produção. **Os cargos são
um jeito de dar nome ao trabalho, não um jeito de dividir pessoas**, e uma vaga que pede os cinco de uma
vez está pedindo um time pequeno, por engano ou de propósito.

O que não se sobrepõe é a pergunta de que cada cargo parte. O analista pergunta *o que aconteceu*. O
cientista de dados pergunta *o que vai acontecer, e por quê*. O engenheiro de dados pergunta **o dado
vai estar lá, vai estar certo e vai chegar na hora, amanhã e todo dia depois** — e é dessa pergunta que
trata o resto deste curso.
