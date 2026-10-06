---
title: O que o protocolo cobre
version: 1
---

O MCP padroniza a conversa entre um cliente e um servidor, e pouco além disso. Um servidor pode oferecer três tipos de coisa, que a especificação chama de **primitivas**:

| primitiva | o que é | quem decide usar |
|---|---|---|
| **ferramentas** (*tools*) | funções que o modelo pode pedir para chamar, com um esquema de entrada | o modelo pede; o hospedeiro permite ou recusa |
| **recursos** (*resources*) | dados endereçados por uma URI, como um arquivo ou um registro, para o hospedeiro ler e dar ao modelo como contexto | o hospedeiro ou a pessoa |
| **prompts** | modelos que uma pessoa escolhe, como um comando de barra, com argumentos | a pessoa |

O servidor desta aula oferece uma ferramenta. A aula 14 constrói um servidor com as três.

Um servidor também pode precisar de algo do cliente no meio de um pedido: uma confirmação da pessoa, uma escolha, uma credencial. Na revisão 2026-07-28 isso é feito por **pedidos de várias idas e voltas** (*multi round-trip requests*): em vez de um resultado, o servidor devolve um do tipo `input_required` listando o que precisa, e o cliente repete o pedido com as respostas. A aula 13 mostra um. Revisões anteriores faziam isso com pedidos do servidor para o cliente, o que exigia uma conexão que ficasse aberta; tornar o protocolo sem estado foi o que mudou isso.

Alguns recursos estão de saída, e a especificação mantém um registro deles. Na revisão 2026-07-28 estes estão **obsoletos**: **roots** (o cliente dizendo ao servidor que diretórios ele pode usar), **sampling** (o servidor pedindo ao modelo do cliente que gere texto), **logging** como recurso do protocolo, o registro dinâmico de clientes, e o velho **transporte HTTP+SSE**. Obsoleto quer dizer que implementações novas não devem adotá-los e as existentes devem migrar; nenhum foi removido ainda. Cursos e artigos escritos em 2025 descrevem roots e sampling como recursos centrais, o que eram na época.

Os transportes são dois: **stdio**, para um servidor que o hospedeiro inicia como programa local, e **Streamable HTTP**, para um servidor em outro lugar. As aulas 13 e 16 usam os dois.
