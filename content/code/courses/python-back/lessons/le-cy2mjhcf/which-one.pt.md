---
title: Qual dos dois, e por que este curso ensina ambos
version: 1
---

Escolher um framework é uma decisão de cauda longa: o código que você escreve no primeiro mês é
código que você mantém por anos. Então ela merece uma razão que continue verdadeira daqui a um ano, e
"é o mais novo" ou "ganha no benchmark" raramente são essa razão.

## Comece pelo que você está construindo

| se a aplicação é principalmente… | o que serve melhor | porque |
|---|---|---|
| páginas HTML, formulários, pessoas fazendo login | **Django** | templates, formulários, sessões e usuários vêm embutidos |
| dados que a equipe edita à mão | **Django** | o admin é um painel que você não precisa construir (aula 5) |
| uma API JSON para um front-end ou um aplicativo | qualquer um | Django com Django REST Framework (aula 6), ou FastAPI |
| um contrato tipado do qual outras equipes geram clientes | **FastAPI** | o documento OpenAPI vem das anotações de tipo (aula 8) |
| requisições que passam o tempo esperando outros serviços | **FastAPI** | ASGI e `async def` desde a primeira linha (aula 9) |
| um serviço pequeno com um trabalho só | **FastAPI** | nada nele que o serviço não use |

Duas coisas costumam decidir antes da tabela. **O que a equipe já sabe** é a especialidade mais
barata que existe: uma equipe fluente em Django entrega uma API JSON em Django mais rápido do que num
framework que está aprendendo. E **o que já está rodando** importa mais que os méritos de qualquer
framework: um segundo framework numa empresa é um segundo conjunto de respostas para cada linha da
tabela da primeira seção, mantido pelas mesmas pessoas.

## A questão da velocidade

O FastAPI tem *fast* no nome, e os benchmarks dele são reais. Mas na maioria das requisições, na
maioria das aplicações, o tempo vai para a consulta ao banco e para a rede, não para o código do
próprio framework, e uma consulta lenta é igualmente lenta nos dois. Onde o FastAPI é mais rápido de
um jeito que o usuário percebe é o caso que a tabela cita: muitas requisições esperando algo lento ao
mesmo tempo. A aula 9 mede isso, e mede um caso em que ele não compra nada.

## Como este curso está organizado

O curso constrói **uma aplicação duas vezes**, para que as escolhas de cada framework possam ser
comparadas no mesmo problema. Ela se chama **agenda**, um site pequeno para os eventos de uma
comunidade: as pessoas veem o que vai acontecer, se inscrevem num evento com um número limitado de
lugares, e quem organiza cuida dos eventos e vê quem vem.

| aulas | o que é construído |
|---|---|
| 2 a 6 | a agenda em **Django**: o projeto, as páginas, os modelos no PostgreSQL, o admin e uma API JSON com o Django REST Framework |
| 7 a 10 | a mesma API em **FastAPI**: rotas, modelos Pydantic, a documentação, async, e SQLAlchemy com Alembic no mesmo servidor de banco |
| 11 a 13 | para os **dois**: login, permissões, e trabalho feito fora da requisição com o Celery |
| 14 a 17 | para os **dois**: testes, configuração, servir em produção, e containers |

Da aula 2 em diante, toda aula continua o projeto que a anterior deixou. Toda aula que acrescenta uma
ferramenta a instala antes do primeiro comando que precisa dela, e cada uma diz no começo de onde
parte.
