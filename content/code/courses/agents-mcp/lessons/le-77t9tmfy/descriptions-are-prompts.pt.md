---
title: Uma descrição é um prompt
version: 1
---

A descrição é a única explicação que o modelo recebe, e ela é lida no momento da escolha. **Escrevê-la é engenharia de prompt**, com a diferença de que uma descrição ruim não produz um parágrafo ruim; produz uma chamada errada, ou nenhuma chamada onde uma era necessária.

Compare as duas descrições do `get_order` que este curso usou:

| | descrição |
|---|---|
| aula 1 | Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents. |
| esta aula | Look up one Marginalia order by its id, which is M- followed by four digits, such as M-1042. Returns status, dates, lines and amounts in cents. |

As duas dizem o que a ferramenta faz e o que volta. A segunda também diz em palavras o formato do id, que o esquema impõe com um padrão. **Dizer na descrição previne o erro; impor no esquema o pega quando a descrição não bastou.** A seção 05 mostra a segunda metade funcionando, porque o substituto do curso foi escrito para ignorar a primeira.

## O que uma boa descrição diz

- **O que a ferramenta faz, numa frase que um colega novo entenderia.** "Consulta um pedido" em vez de "Endpoint de recuperação de pedidos".
- **Quando usá-la, e quando não**, se houver outra ferramenta parecida. Uma loja com `find_books` e uma busca de texto completo `search_catalogue` deveria dizer qual das duas responde "vocês têm mistérios em estoque?".
- **O que os argumentos significam**, além dos tipos: o formato de um id, a unidade de um valor, se uma data é inclusiva.
- **O que volta**, unidades incluídas. O `find_books` diz "prices in cents"; sem isso, 3190 parece um preço que ninguém paga por um livro de bolso.
- **O que ela muda, se muda algo.** O `issue_refund` diz que reembolsa, e diz o que uma chave repetida faz. Uma ferramenta com efeito colateral que a descrição não menciona é uma armadilha para o modelo e para quem revisa o rastro.

## O que ela não deve dizer

Instruções que são do hospedeiro. *"Só chame isto depois de confirmar com o cliente"* numa descrição é um pedido que o modelo pode atender ou não; se importa, o hospedeiro impõe (aula 17). E nada secreto: as descrições vão para o fornecedor a cada pedido e aparecem nos rastros, então uma URL interna ou uma chave numa delas foi publicada.

**Descrições também são superfície de ataque quando outra pessoa as escreve.** Uma ferramenta entregue por terceiros, como fazem os servidores MCP (aulas 11 a 16), chega com a própria descrição, e uma descrição é texto que o modelo lê como orientação. A aula 16 é sobre lê-las antes de confiar nelas.
