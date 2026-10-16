---
title: O programa driver e a sua sessão
version: 1
---

**Todo programa Spark é um driver**, o papel que a aula 2 nomeou: um processo Python comum que
descreve o trabalho e o entrega ao cluster. A primeira linha de trabalho de verdade é sempre a mesma:

```python
spark = SparkSession.builder.appName("explore").getOrCreate()
```

**A `SparkSession` é a conexão do programa com o cluster.** Criá-la inicia a metade Java do driver,
pede executores ao master indicado no `spark-defaults.conf` e abre a página na porta 4040 que as
aulas 2 e 3 leram. Tudo depois passa por ela: `spark.read` para ler dados, `spark.sql` para fazer
uma pergunta em SQL, `spark.sparkContext` para a API mais antiga da próxima seção. Um programa tem
uma sessão, e quando o programa termina, a aplicação termina junto.

Há dois jeitos de rodar um driver, e o curso usa o primeiro:

- **`spark-submit programa.py`**, como toda aula fez até aqui. O programa roda de cima a baixo e
  termina. É assim que jobs rodam em produção, por um agendador como os de `pipelines-etl`, e é o
  que toda transcrição deste curso consegue mostrar por inteiro.
- **`pyspark`**, um shell Python interativo com o `spark` já criado. Digite uma linha, veja um
  resultado. É como a maioria das pessoas explora dados, e tudo nesta aula funciona nele linha a
  linha: digite `pyspark` e cole o corpo de qualquer programa abaixo, depois da linha `getOrCreate()`.

Notebooks, como o Jupyter, são o mesmo driver interativo num navegador. Eles mantêm uma sessão
aberta enquanto o notebook roda, e com ela os executores: um notebook esquecido aberto à noite segura
a sua fatia do cluster, que é o `WAITING` da aula 2 com outra causa.

**O Python que você escreve roda em dois lugares.** As linhas do driver rodam no driver. Uma função
que você passa ao Spark, como o `lambda` de um `filter`, é serializada, enviada aos executores e
rodada lá, num processo Python que cada executor inicia ao lado de si. O código da próxima seção tem
os dois tipos, e a aula 7 diz quanto o segundo custa.
