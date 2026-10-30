---
title: "Direct Lake: um relatório que lê os arquivos"
version: 1
---

**O Power BI sempre teve dois jeitos de ler dados, e o Direct Lake é um terceiro que existe porque
os dados já são Delta no OneLake.** Esta seção é ensinada a partir da documentação da Microsoft e não
foi executada; o Power BI não tem emulador e exige um tenant.

## Import e DirectQuery

Os dois modos mais antigos são uma troca entre velocidade e frescor:

- **Import** copia os dados para o modelo semântico, o armazenamento comprimido em memória do
  próprio Power BI, num agendamento. Os relatórios são rápidos, porque os dados estão em memória no
  formato do motor, e tão velhos quanto a última atualização. Uma atualização lê cada linha de novo,
  o que numa tabela grande é o maior job da noite.
- **DirectQuery** não guarda cópia: cada visual de cada relatório manda uma consulta à origem, como
  um warehouse, enquanto alguém espera. Os relatórios são tão frescos quanto a origem e tão lentos
  quanto ela, e cada pessoa que abre uma página roda consultas nela.

## O que o Direct Lake faz no lugar

**O Direct Lake carrega colunas direto dos arquivos Parquet da tabela Delta para o motor em memória,
quando um relatório precisa delas pela primeira vez.** Não há cópia de import para atualizar nem
consulta SQL por visual. O Parquet no OneLake já é um formato de colunas, então o motor lê as colunas
que o relatório usa e deixa o resto no armazenamento, mais ou menos como o DuckDB fez com as duas
colunas da pergunta da sexta seção.

**Uma atualização no Direct Lake se chama framing, e não copia dados.** Ela aponta o modelo semântico
para a versão mais nova da tabela, que é o commit mais recente do `_delta_log`, o log que a sexta
seção baixou. O framing leva segundos onde um import leva o tempo de ler a tabela, e pode acontecer
toda vez que o job da noite termina. Entre dois framings o relatório continua mostrando a versão em
que foi enquadrado, então uma noite carregada pela metade nunca aparece num dashboard.

## Onde ele recua, e por que os arquivos decidem

**O Direct Lake tem limites por tamanho de capacidade**, que a Microsoft documenta como guardrails:
quantas linhas uma tabela pode ter, quantos arquivos Parquet e grupos de linhas, quanto o modelo pode
crescer em memória. Uma tabela que passa de um guardrail recua para DirectQuery, pelo endpoint de
análise SQL, ou falha, conforme uma configuração do modelo. Algumas coisas sempre recuam, como ler
uma view SQL em vez de uma tabela.

**O recuo é silencioso**: o relatório continua funcionando, e cada visual vira uma consulta SQL, mais
lenta e cobrada como tal. Os guardrails contam arquivos e grupos de linhas, não só linhas, então uma
tabela gravada como milhares de arquivos pequenos os alcança muito antes do que o tamanho dela
alcançaria. É ali que a conta do Fabric encontra o arranjo dos arquivos, assunto da próxima lição: a
compactação de lá é o que mantém um modelo Direct Lake em Direct Lake.

**O V-Order é a contribuição do próprio Fabric aos arquivos.** É uma otimização aplicada quando o
Parquet é escrito, ordenando e codificando os dados para que o motor em memória os leia mais rápido;
o resultado continua sendo Parquet padrão, e qualquer leitor, `deltalake` e DuckDB inclusive, o lê
como tal. A tabela que a sexta seção gravou não tem V-Order, porque só os motores do Fabric o
aplicam.
