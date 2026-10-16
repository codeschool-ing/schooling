---
title: Duas filosofias, e o que cada uma supõe
version: 1
---

Os dois frameworks são bons, e os dois são usados por empresas grandes em trabalho sério. **A
pergunta útil não é qual é melhor. É o que cada um supõe sobre a aplicação que você está
construindo**, porque um framework é rápido de usar exatamente onde as suposições dele valem, e
desajeitado onde não valem.

## O Django supõe um site com um banco de dados atrás

O Django foi escrito em 2003 e 2004 num jornal do Kansas, o *Lawrence Journal-World*, e publicado
como código aberto em 2005. O trabalho dele era publicar: páginas HTML montadas a partir de linhas
num banco, editadas pela equipe por formulários, com prazo. Tudo o que ele supõe vem daí.

- **Existe um banco relacional**, e o Django é dono das tabelas: você as descreve como classes
  Python e ele escreve o SQL e as migrações (aula 4).
- **O servidor monta o HTML.** Os templates vêm embutidos (aula 3), e os formulários também.
- **Pessoas fazem login.** Usuários, senhas, sessões e permissões vêm na caixa (aulas 11 e 12).
- **Alguém precisa editar os dados.** O admin, um painel completo gerado a partir dos seus modelos,
  vem na caixa também (aula 5).
- **Um projeto são vários apps**, cada um uma pasta com seus modelos, views e templates, que um
  arquivo de configuração liga.

O lema dele é "the web framework for perfectionists with deadlines", o framework para perfeccionistas
com prazo, e o prazo é a metade que explica o desenho. Quando a maior parte dessas suposições vale,
uma equipe quase não escreve nada que não seja sobre o próprio problema.

## O FastAPI supõe uma API, e anotações de tipo como contrato

O FastAPI foi publicado em 2018 por Sebastián Ramírez. Ele é construído sobre outras duas
bibliotecas: o **Starlette**, que cuida do HTTP e do ASGI, e o **Pydantic**, que valida dados contra
anotações de tipo do Python. O trabalho dele é a outra metade da web de hoje: JSON para um front-end
em JavaScript, um aplicativo de celular ou outro serviço.

- **A resposta é JSON**, não uma página. Não há templates na caixa, nem formulários.
- **As anotações de tipo são a especificação.** `name: str` na assinatura de uma função é o que o
  FastAPI lê para interpretar a requisição, validar e descrever o endpoint para o mundo (aulas 7
  e 8).
- **Você escolhe a camada de banco.** Nada é suposto; este curso usa SQLAlchemy e Alembic (aula 10).
- **Esperar é o caso comum.** Uma rota pode ser um `async def`, e o servidor atende outras
  requisições enquanto uma espera uma resposta da rede (aula 9).
- **Uma aplicação é um módulo**, que cresce para um pacote quando você quiser.

## As mesmas suposições, lado a lado

| | Django | FastAPI |
|---|---|---|
| a resposta típica | uma página HTML, ou JSON com o Django REST Framework | JSON |
| dados | ORM e migrações próprios | o que você instalar |
| validação | formulários e serializers | modelos Pydantic a partir das anotações de tipo |
| login | embutido | bibliotecas que você escolhe |
| um painel administrativo | o admin, embutido | nenhum |
| o contrato com o servidor | WSGI, e ASGI desde a versão 3.0 | ASGI |
| documentação da API | uma biblioteca, `drf-spectacular` ou parecida | OpenAPI, gerado, embutido |

**Leia as células vazias como trabalho, não como liberdade.** "O que você instalar" é uma decisão,
uma versão para manter atualizada e um conjunto de respostas com que a equipe precisa concordar. Em
troca, não há nada ali que a aplicação não use.

## Um terceiro que você vai encontrar

O **Flask** fica entre os dois: um núcleo pequeno como o do FastAPI, síncrono como o Django clássico,
estendido com plug-ins. Ele é mais antigo que o FastAPI e continua comum, e quase tudo o que este
curso diz sobre o roteamento do FastAPI, sobre o SQLAlchemy e sobre servir em produção vale para ele
sem mudança. O curso ensina os dois que ficam nas pontas, porque ver as duas pontas é o que torna o
meio legível.
