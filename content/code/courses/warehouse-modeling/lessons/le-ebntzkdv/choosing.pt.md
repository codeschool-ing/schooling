---
title: Escolhendo um
version: 1
---

A escolha entre warehouses raramente se decide por benchmarks. Benchmarks publicados são rodados por
fornecedores em cargas que os favorecem, e no tamanho da maioria das empresas todos esses produtos respondem em
segundos. O que decide costuma ser uma lista curta de perguntas, mais ou menos nesta ordem:

1. **Onde os dados já estão?** Mover terabytes entre nuvens custa dinheiro a cada gigabyte que sai, e tempo.
   Uma empresa na AWS tende ao Redshift ou ao Snowflake na AWS; uma no Google Cloud, ao BigQuery.
2. **Que forma tem a carga?** Muitas consultas pequenas e imprevisíveis de muita gente combinam com pagar por
   consulta ou por segundo, com escala rápida; uma carga pesada e constante, o dia todo, combina com capacidade
   reservada, paga por hora, que custa menos por unidade quando é usada.
3. **Quanta operação o time quer?** O BigQuery pede quase nenhuma; o Snowflake pede warehouses dimensionados e
   suspensos; o Redshift provisionado pede nós, chaves e manutenção.
4. **Como fica a conta quando alguém erra?** Sob demanda, um `SELECT *` descuidado sobre uma tabela grande é uma
   conta grande sozinho; por segundo, um warehouse esquecido ligado é. Todo produto tem limites e alertas, e a
   lição 10 de `cloud`, sobre orçamentos, vale aqui diretamente.
5. **Que língua fala o resto da pilha?** As ferramentas de relatório, os pipelines e o que as pessoas sabem.

**E a primeira pergunta honesta, da lição 7: precisa mesmo ser alugado?** O warehouse da Ana é um arquivo de 46
MB que responde a toda pergunta deste curso em milissegundos numa máquina de quatro núcleos. Uma rede deste
tamanho pode rodar DuckDB ou PostgreSQL por anos antes de qualquer um desses produtos valer a conta, e um
projeto construído sobre o modelo dimensional das lições 2 a 6 vai para qualquer um deles quando precisar.
