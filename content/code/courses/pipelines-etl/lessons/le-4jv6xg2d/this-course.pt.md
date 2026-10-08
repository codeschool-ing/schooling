---
title: Para que serve este curso
version: 1
---

Em `warehouse-modeling` a Ana desenhou um warehouse para a Ponto Final: um esquema estrela de
vendas, uma dimensão de clientes que lembra onde as pessoas moravam antes, e um calendário. **Cada
linha dele chegou lá porque ela rodou um comando.** Ela exportou as tabelas da loja, rodou os
arquivos SQL em ordem e conferiu os totais no olho. Isso funciona uma vez. Não funciona toda noite
durante três anos, enquanto os caixas continuam vendendo e alguém lá na origem renomeia uma coluna.

Este curso é a outra metade do trabalho: **mover dados de onde eles são escritos para onde são
lidos, num horário, sem uma pessoa, e sabendo quando deu errado.** Os programas que fazem isso se
chamam pipelines, e a profissão que os escreve trata sobretudo do que acontece quando eles falham.

## O formato do curso

As dezenove lições se dividem em cinco grupos:

| lições | o que cobrem |
|---|---|
| 1–3 | os tipos de ingestão, ETL contra ELT, e os quatro tipos de origem |
| 4–7 | extrair, transformar e carregar, um passo por vez, à mão em Python e SQL |
| 8–14 | as ferramentas que rodam esses passos: Airflow, dbt, e um olhar sobre Luigi, Prefect e Dagster |
| 15–17 | idempotência, qualidade de dados e testes — as razões para se confiar num pipeline |
| 18–19 | versões e ambientes, e quanto custa uma carga grande |

A ordem é de propósito. **Você vai escrever cada passo à mão antes que uma ferramenta o faça por
você**, porque um agendador só roda o que você entrega a ele, e um passo mal escrito agendado toda
noite continua mal escrito. Quando o Airflow chegar na lição 8, ele vai rodar código que você já
entende.

## O que ele supõe

`warehouse-modeling`, porque um pipeline é definido pelo lugar onde ele carrega: fatos, dimensões,
um grão, uma dimensão que muda devagar. Quando a lição 7 carregar uma dimensão do tipo 2, ela não
vai parar para explicar o que é uma. Você também precisa de SQL suficiente para ler um join e um
`GROUP BY`, e de Python suficiente para ler um laço e uma função — os orquestradores são
configurados em Python.

## O que ele deixa pronto

Orquestração e qualidade de dados, para `ml-mlops`: um modelo treinado com dados que ninguém
conferiu, por um job que ninguém agenda, é o mesmo problema com um preço mais alto.
