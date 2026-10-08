---
title: O hospedeiro decide
version: 2
---

A especificação dá ao hospedeiro uma lista de trabalhos: criar e gerenciar clientes, controlar as permissões e o ciclo de vida deles, impor políticas de segurança e consentimento, tratar as decisões de autorização da pessoa, coordenar o modelo, e juntar contexto entre clientes. Cada achado desta aula está nessa lista:

| o que foi visto | de quem é a decisão |
|---|---|
| o servidor rodou como ana, com os arquivos dela | o hospedeiro inicia o servidor; a pessoa o instala |
| ele recebeu 4 variáveis de ambiente, ou 31 com duas chaves de API | o cliente do hospedeiro, e a configuração que ele aceita |
| ele viu só os argumentos da chamada | o hospedeiro, que decide o que vai num pedido |
| os clientes declararam capacidades diferentes | cada hospedeiro, pelo que consegue fazer em nome de um servidor |
| duas ferramentas com um nome: recusadas, renomeadas ou encobertas em silêncio | o hospedeiro |

Nenhuma delas é decidida pelo protocolo, e nenhuma pelo servidor. Um servidor pode ser bem escrito e ainda assim receber as suas chaves; pode ser honesto e ainda assim ser encoberto por outro. Por isso as perguntas a fazer antes de conectar um servidor são perguntas sobre o hospedeiro:

- **O que o processo do servidor vai herdar?** Usuário, arquivos, ambiente, rede.
- **O que vai ser mandado a ele?** Só argumentos, ou mais, e de que conversas.
- **O que mais está conectado ao mesmo tempo?** Nomes, e o que a saída de um servidor pode levar o modelo a fazer com as ferramentas de outro.
- **Que chamadas precisam de uma pessoa?** O passo de aprovação do hospedeiro, das aulas 8 a 10, vale para ferramentas MCP exatamente como para as locais.

A aula 15 constrói um hospedeiro, e toma cada uma dessas decisões em código onde dá para lê-las. A aula 17 as testa contra o laboratório do curso.
