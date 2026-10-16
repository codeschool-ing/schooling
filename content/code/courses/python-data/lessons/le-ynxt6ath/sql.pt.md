---
title: SQL, e deixar o banco fazer o trabalho
version: 1
---

**O pandas lê o resultado de uma consulta SQL num DataFrame**, e isso muda a pergunta de "como carrego
esta tabela" para "de quais linhas e colunas eu preciso de verdade". O curso `sql-databases` ensina
SQL; aqui basta ver a passagem de mão.

O SQLite é um banco de dados num arquivo só, e o Python traz o módulo `sqlite3` para usá-lo, então
nada precisa ser instalado. Ponha as viagens num:

```python
con = sqlite3.connect("bikes.db")
trips.to_sql("trips", con, index=False, if_exists="replace")
```

```
33337
```

`to_sql` cria a tabela, insere cada linha e devolve o número de linhas que gravou.
`if_exists="replace"` deixa a célula segura para rodar de novo. Agora faça uma pergunta ao banco:

```python
pd.read_sql("SELECT plan, bike, COUNT(*) AS trips FROM trips GROUP BY plan, bike", con)
```

```
     plan      bike  trips
0  annual   classic  15226
1  annual  electric   8212
2     day   classic   6456
3     day  electric   3443
```

Quatro linhas voltaram em vez de 33.337. **A contagem aconteceu no banco**, e só a resposta passou
para o Python. Num banco com cem milhões de viagens, essa é a diferença entre uma consulta que volta
em um segundo e um notebook que fica sem memória; a aula 20 volta a isso.

## Parâmetros, nunca formatação de string

Uma consulta que depende de um valor recebe o valor como parâmetro, com um `?` no SQL:

```python
pd.read_sql("SELECT trip_id, started_at FROM trips WHERE start_station = ? LIMIT 3", con, params=["S07"])
```

```
   trip_id           started_at
0        1  2025-01-01 12:22:38
1       32  2025-01-01 15:00:50
2       42  2025-01-01 12:17:37
```

O driver põe o valor com segurança. **Montar o SQL colando um valor na string**, com uma f-string,
funciona até o valor ter uma aspa, e com um valor vindo de um usuário deixa esse usuário reescrever a
consulta. `params` não custa nada e fecha as duas portas.

```python
pd.read_sql("SELECT * FROM trips LIMIT 1", con).dtypes["started_at"]
```

```
<StringDtype(na_value=nan)>
```

O SQLite não tem um tipo datetime próprio, então os horários voltaram como texto, como de um CSV. Um
banco com tipos de verdade, o PostgreSQL por exemplo, devolve datetimes, e o `read_sql` tem um
argumento `parse_dates` para quando não devolve.

```python
con.close()
```
