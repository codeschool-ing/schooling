---
title: X a XII, paridade, logs e tarefas administrativas
version: 1
---

## X, paridade entre desenvolvimento e produção

O texto dos doze fatores aponta três distâncias entre desenvolvimento e produção: **tempo**, código
escrito hoje e implantado semanas depois; **pessoas**, quem programa e quem implanta; e **ferramentas**,
SQLite no laptop e PostgreSQL em produção. As duas primeiras se fecham com implantação contínua e
equipes que rodam o que constroem. A terceira é a que uma aula consegue mostrar.

O laboratório roda `postgres:17` porque a produção rodaria. Um laptop com SQLite passaria em todos os
testes e ainda assim seria diferente exatamente nos lugares que doem: o SQLite aceita texto numa coluna
inteira a não ser que a tabela seja declarada `STRICT`, e as regras de lock dele sob escritas
concorrentes são só dele. **Contêineres baratearam este fator**: a mesma imagem do mesmo serviço de apoio roda num
laptop em segundos, então não há mais um bom motivo para desenvolver contra um substituto mais leve.

## XI, logs como fluxo

O catálogo escreve uma linha por requisição na saída padrão e nunca abre um arquivo de log. Ele não sabe
para onde vão os logs, e é essa a ideia: no laboratório o Docker os coleta, e
`docker compose logs` os lê de volta, de todas as cópias, num fluxo só:

```
ana@vm:~/lab/twelve$ docker compose logs catalogue --no-log-prefix | grep GET
a3b89e5e7e5f "GET /hits HTTP/1.1" 200 -
a3b89e5e7e5f "GET /hits HTTP/1.1" 200 -
a3b89e5e7e5f "GET /hits HTTP/1.1" 200 -
4ed40453cdac "GET /hits HTTP/1.1" 200 -
4ed40453cdac "GET /products HTTP/1.1" 200 -
280702d81305 "GET /hits HTTP/1.1" 200 -
```

Em produção a plataforma manda o mesmo fluxo para um armazenamento de logs, onde dá para buscar em
todos os processos e todos os serviços, e o id de requisição da aula 2 é o que junta as linhas de uma
requisição. Um programa que escreve em `/var/log/catalogue.log` dentro do contêiner escreve num disco
que some com o contêiner, e que ninguém está lendo. **Escreva um evento por linha, e prefira um formato
estruturado como JSON** quando algo além de uma pessoa for ler os logs; a aula 7 de `scale` leva isso
adiante.

## XII, tarefas administrativas como processos avulsos

A tabela foi criada por `python catalogue.py migrate`, rodado com `docker compose run --rm`: um
processo avulso, da mesma imagem, com a mesma configuração, que sai quando termina. Qualquer tarefa
administrativa funciona do mesmo jeito, inclusive uma olhada nos dados com o cliente do próprio banco:

```
ana@vm:~/lab/twelve$ docker compose exec db psql -U quitanda -c "SELECT sku, price_cents FROM products ORDER BY price_cents DESC LIMIT 3"
  sku   | price_cents 
--------+-------------
 coffee |        3290
 cheese |        2450
 bread  |         990
(3 rows)
```

**A regra é que a tarefa vai junto com o código e roda no ambiente da release.** Um script de migração
guardado no laptop de alguém roda, mais cedo ou mais tarde, contra a versão errada do esquema, com as
dependências erradas.

## O que doze deixa de fora

A lista é de 2011, e algumas coisas que ela não menciona viraram tão básicas quanto o resto: métricas e
traces para cada serviço, health checks que dizem à plataforma quando um processo está pronto,
segurança da cadeia de suprimentos, e projetar a API antes do código. O livro *Beyond the Twelve-Factor
App*, de Kevin Hoffman, em 2016, acrescentou três: API primeiro, telemetria, e autenticação e
autorização. Os doze continuam sendo o piso, não o teto.

Pare os serviços da aula:

```sh
docker compose down -v
```
