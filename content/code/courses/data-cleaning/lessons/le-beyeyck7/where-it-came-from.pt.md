---
title: Anotando de onde veio
version: 1
---

Uma tabela de referência que chegou sem nenhuma nota é um passivo: um ano depois ninguém sabe se era
oficial, de quando é ou se pode ser compartilhada. Por isso esta aula escreve à mão um arquivo
pequeno ao lado das referências, uma linha por fonte:

```
file,publisher,document,obtained,valid_for,terms
ref/ibge_states.csv,IBGE,codes of the 27 federative units,typed from the published list,stable since 1988,public data; cite IBGE
ref/ibge_cities.csv,IBGE,7-digit municipal codes,typed from the published list,stable; a new municipality gets a new code,public data; cite IBGE
ref/holidays_2025.csv,federal government,holiday laws and the 2025 calendar of optional days,typed from the published calendar,2025 only,laws are not subject to copyright
```

Cada coluna responde a uma das quatro perguntas da primeira seção, e cada uma tem motivo para
estar lá:

- **`publisher` e `document`** dizem quem responde pelos valores. Os códigos de estado e de cidade
  são do IBGE, o instituto nacional de estatística, que é a autoridade neles. Os feriados vêm das
  leis federais que os criam e do calendário do governo federal para o ano, que também lista os
  pontos facultativos.
- **`obtained`** diz como o arquivo chegou aqui. Aqui os valores foram digitados a
  partir das listas publicadas, o que é honesto e mais fraco que um download: um valor digitado
  pode ter erro, e só uma comparação com a fonte mostraria.
- **`valid_for`** diz quando os valores valem. Feriados são o caso mais claro: 20 de novembro, Dia
  Nacional de Zumbi e da Consciência Negra, só virou feriado nacional a partir de 2024, pela Lei
  14.759 de 2023. Uma lista de feriados de 2023 marcaria o fechamento das lojas nesse dia como dado
  faltante.
- **`terms`** diz o que você pode fazer com eles. Dado público de fonte governamental em geral é de
  uso livre com a fonte citada, mas "em geral" é o motivo para ler os termos da fonte de verdade em
  vez de supô-los.

**O arquivo de fontes faz parte da análise**, tanto quanto o código. Ele viaja com os resultados, é
o que um revisor lê primeiro, e é o que a aula 17 vai pôr sob controle de versão ao lado dos
scripts.
