---
title: Pipelines descritos como dados
version: 1
---

A camada de staging de Ana tem quinze tabelas, e a lição 2 escreveu quinze comandos quase idênticos para carregá-las.
Um warehouse com quatrocentas tabelas de origem teria quatrocentos, e o quadringentésimo primeiro seria copiado de um
dos outros, com o erro que aquele carregasse.

Um pipeline **orientado a metadados** (metadata-driven) inverte isso. As tabelas são descritas como dados, uma lista
com uma entrada por origem dizendo como se chama, de onde vem e o que tem de incomum, e **um programa genérico**
transforma a lista em cargas, gerando o código ou executando ele mesmo as cargas. Acrescentar uma origem é uma linha na
lista, não um programa novo.

A ideia é antiga e aparece com vários nomes:

- **Geração de código** escreve o SQL a partir dos metadados, para que o resultado possa ser lido, revisado e guardado
  no controle de versão. O dbt faz isso com templates SQL configurados em YAML, e as lições 11 e 12 de `pipelines-etl`
  o usam.
- **Um carregador genérico** lê os metadados em tempo de execução e executa as cargas diretamente, sem nada gerado no
  meio. As atividades de cópia que ferramentas de integração na nuvem montam a partir de uma tabela de controle
  funcionam assim.
- **Automação de Data Vault**, da lição 6: hubs, links e satélites são tão regulares que vaults inteiros são gerados a
  partir de uma descrição das chaves de negócio.

O que isso compra é consistência, e ela vale mais do que a digitação que poupa. Toda tabela de staging é carregada do
mesmo jeito, com as mesmas opções, então uma correção no template é uma correção em todas. O que custa é que **o
gerador passa a ser um programa que o time mantém**, e cada exceção o complica: a única origem com outro delimitador, a
única tabela que precisa de um tipo forçado. A próxima seção gera a camada de staging de Ana e encontra exatamente uma
exceção dessas.
