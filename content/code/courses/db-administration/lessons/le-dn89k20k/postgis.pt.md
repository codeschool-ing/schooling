---
title: PostGIS, de um pacote próprio
version: 1
---

**O PostGIS acrescenta ao PostgreSQL tipos geográficos e várias centenas de funções**: pontos,
linhas e áreas sobre a Terra, e perguntas como a que distância, o que está dentro e o que está mais
perto. Ele não é um módulo contrib. É um projeto separado, com lançamentos próprios, e no Ubuntu o
seu pacote é compilado para uma versão maior do servidor de cada vez, que é o detalhe que importa a
um DBA.

## Instalando

O nome do pacote carrega as duas versões, a do servidor e a do PostGIS:

```sh
sudo apt install -y postgresql-16-postgis-3
```

Isso põe o arquivo de controle, os scripts e as bibliotecas onde o servidor os procura, exatamente
como os arquivos contrib da primeira seção, e não muda nada dentro de banco nenhum. A extensão é
então criada onde é desejada:

```
ana=# CREATE EXTENSION postgis;
CREATE EXTENSION

ana=# SELECT postgis_version();
            postgis_version            
---------------------------------------
 3.4 USE_GEOS=1 USE_PROJ=1 USE_STATS=1
(1 row)

ana=# SELECT count(*) FROM pg_depend
ana-#  WHERE refobjid = (SELECT oid FROM pg_extension WHERE extname = 'postgis')
ana-#    AND deptype = 'e';
 count 
-------
   893
(1 row)
```

O `pg_depend` com `deptype = 'e'` lista todo objeto que pertence a uma extensão, e **893 objetos
chegaram com um comando**: tipos, funções, operadores, uma tabela de sistemas de coordenadas. O
registro da extensão é o que os mantém juntos. `DROP EXTENSION postgis` remove os 893, e a próxima
seção mostra que um dump escreve uma linha para eles.

## Cinco pontos e uma distância

Um ponto se escreve como texto, `POINT(longitude latitude)`. **A longitude vem primeiro**, que é a
ordem de x e y e o contrário de como a maioria dos mapas imprime uma coordenada; trocar as duas põe
São Paulo no meio do Atlântico Sul sem erro nenhum. Salve isto como `warehouses.sql`:

```sql
-- warehouses.sql: five points, longitude first
CREATE TABLE warehouses (
    name     text PRIMARY KEY,
    location geography(Point, 4326) NOT NULL
);

INSERT INTO warehouses VALUES
    ('São Paulo',    'POINT(-46.6333 -23.5505)'),
    ('Buenos Aires', 'POINT(-58.3816 -34.6037)'),
    ('Mexico City',  'POINT(-99.1332 19.4326)'),
    ('Lisbon',       'POINT(-9.1393 38.7223)'),
    ('Madrid',       'POINT(-3.7038 40.4168)');
```

`geography(Point, 4326)` diz que a coluna guarda pontos, e 4326 é o número do WGS 84, o sistema de
coordenadas que o GPS usa. Rode o arquivo e pergunte a que distância cada armazém está do Rio de
Janeiro:

```
ana@db:~$ psql -f warehouses.sql
CREATE TABLE
INSERT 0 5
```

```
ana=# SELECT name,
ana-#        round(ST_Distance(location, 'POINT(-43.1729 -22.9068)') / 1000) AS km_from_rio
ana-#   FROM warehouses
ana-#  ORDER BY km_from_rio;
     name     | km_from_rio 
--------------+-------------
 São Paulo    |         361
 Buenos Aires |        1967
 Mexico City  |        7675
 Lisbon       |        7690
 Madrid       |        8116
(5 rows)

ana=# SELECT name FROM warehouses
ana-#  WHERE ST_DWithin(location, 'POINT(-43.1729 -22.9068)', 2000000);
     name     
--------------
 São Paulo
 Buenos Aires
(2 rows)
```

O `ST_Distance` sobre um `geography` responde em metros pela superfície da Terra, então dividir por
1000 dá quilômetros: São Paulo fica a 361 km do Rio. O `ST_DWithin` pergunta *a menos de tantos
metros*, que é a pergunta que uma aplicação mais faz, e pode usar um índice onde calcular todas as
distâncias e filtrar não pode.

## geometry é outro tipo

O PostGIS tem um segundo tipo, `geometry`, que trata as coordenadas como pontos num plano. As mesmas
duas cidades como `geometry`:

```
ana=# SELECT round(ST_Distance('POINT(-46.6333 -23.5505)'::geometry,
ana(#                          'POINT(-43.1729 -22.9068)'::geometry)::numeric, 2);
 round 
-------
  3.52
(1 row)
```

**3.52 está em graus**, a distância em linha reta num desenho plano do mapa, e não é 361 km em
unidade nenhuma. O `geometry` é o certo para as ruas de uma cidade projetadas num sistema de
coordenadas plano e local, onde ele é mais rápido, e o errado para distâncias entre continentes.
Que tipo uma coluna usa é decisão do desenvolvedor; perceber que um relatório de distâncias saiu em
graus muitas vezes é tarefa do DBA.
