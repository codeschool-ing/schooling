---
title: Quando o pandas é a ferramenta errada
version: 1
---

**O pandas guarda a tabela inteira na memória e roda cada operação num núcleo do processador.** Dentro
desses dois limites ele é a ferramenta mais flexível para tabelas em Python, e este curso o usou para
tudo. Passando deles, a resposta honesta é outra ferramenta, e saber onde ficam os limites poupa um dia
brigando com eles.

Primeiro o limite de memória. Uma regra grosseira a partir das medições desta aula: a tabela precisa
mais ou menos do tamanho do arquivo depois de tipada, e de mais que isso enquanto ainda é texto. Numa
máquina com 16 GB, um CSV de um ou dois gigabytes é tranquilo, dez gigabytes é um projeto, e cinquenta é
a ferramenta errada. Antes de buscar outra, os passos baratos desta aula vêm primeiro, nesta ordem:

1. **Leia menos colunas**, com `usecols` ou o `columns` do Parquet.
2. **Dê os tipos às colunas** na leitura, com `dtype` e `parse_dates`.
3. **Guarde como Parquet** o que você vai ler mais de uma vez.
4. **Leia em pedaços** quando a pergunta se soma.
5. **Trabalhe numa amostra** enquanto escreve a análise, e rode no todo no fim.

Uma amostra de um décimo, reproduzível por causa da semente da aula 8:

```python
sample = typed.sample(frac=0.1, random_state=2025)
len(sample), round(sample["bike"].eq("electric").mean(), 3), round(typed["bike"].eq("electric").mean(), 3)
```

```
(3334, np.float64(0.345), np.float64(0.35))
```

Um décimo das linhas dá a fração de elétricas com meio ponto percentual de diferença, e toda célula do
notebook roda dez vezes mais rápido enquanto você ainda decide o que calcular.

## As ferramentas depois do limite

Quando esses passos não bastam, três tipos de ferramenta assumem. Nenhuma delas está instalada no
laboratório deste curso, e nenhuma é necessária para os dados dele; elas são nomeadas aqui para que, no
dia em que um arquivo não couber, você saiba o que procurar.

| ferramenta | o que é | por que ajuda |
|---|---|---|
| **DuckDB** | um banco de dados que roda dentro do seu processo Python, consultado em SQL | lê CSV e Parquet direto do disco, usa todos os núcleos, e não precisa da tabela na memória |
| **Polars** | uma biblioteca de DataFrames com interface diferente da do pandas | usa todos os núcleos, e o modo preguiçoso planeja a consulta inteira antes de ler o arquivo |
| **um servidor de banco de dados** | PostgreSQL e parecidos | os dados moram lá, e só a resposta vem para o seu notebook |

As três respondem certo a pergunta da mediana da última seção num arquivo maior que a memória, porque
conseguem ordenar e contar sem guardar tudo de uma vez. Cada uma tem o seu jeito de escrever uma
consulta, e o `read_sql` da aula 10 é como um resultado volta para o pandas quando a parte pesada acaba.

**O pandas continua sendo a ferramenta do último passo**: a tabela que cabe, o gráfico, o notebook que
uma pessoa lê. A habilidade é perceber quando o passo antes dele pertence a outro lugar.
