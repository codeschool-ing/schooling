---
title: Dois estilos, comparados no que importa
version: 1
---

A aula 10 construiu um serviço gRPC ao lado de uma API HTTP, e os dois respondem as mesmas perguntas a
partir do mesmo store. Isso deixa a comparação concreta. **Nenhum estilo é melhor em geral; cada um é
melhor em coisas específicas**, e o erro das equipes é escolher um para tudo porque ele foi a escolha certa
uma vez.

| | REST com JSON | gRPC com Protocol Buffers |
|---|---|---|
| o contrato | opcional, um documento OpenAPI se alguém escrever | obrigatório, o `.proto`, e os dois lados gerados a partir dele |
| o que trafega | texto que qualquer um lê | binário que precisa do contrato para ser lido |
| tamanho no fio | maior, a seção 03 mede | menor, a seção 03 mede |
| navegadores | nativo: `fetch`, um formulário, um link | não diretamente, seção 05 |
| ferramentas para cutucar | `curl`, um navegador, toda biblioteca HTTP | `grpcurl` e bibliotecas gRPC, seção 04 |
| streaming | um sentido por vez, com maquinaria extra, aula 13 | quatro tipos de chamada, embutidos |
| erros | status HTTP mais um formato de corpo que você escolhe | um conjunto fixo de códigos, o mesmo em toda linguagem |
| cache por proxies e CDNs | embutido no HTTP, para `GET` | nenhum: toda chamada é um `POST` por baixo |
| prazos | seus para mandar e respeitar | mandados em toda chamada e propagados |
| clientes gerados | possível a partir de OpenAPI | sempre, em toda linguagem suportada |

**Leia a tabela como uma lista de perguntas sobre quem chama**, não como um placar. Quem chama este
serviço? Um navegador, um app móvel, o script de um parceiro, ou outro serviço da sua própria equipe? Qual o
tamanho das respostas, com que frequência são mandadas, e quanto custa um mal-entendido sobre o contrato?
As próximas quatro seções pegam as linhas que mais são decididas errado, com medições onde existe medição.
