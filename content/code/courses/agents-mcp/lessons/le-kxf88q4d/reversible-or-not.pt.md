---
title: A ação pode ser desfeita?
version: 1
---

A pergunta que decide quanta liberdade um agente recebe não é quão esperto é o modelo dele. É quanto custa o pior passo errado, e se ele tem volta. Ordene toda ferramenta que um agente possa ter por esse critério, antes de escrever qualquer uma:

| tipo de ação | exemplo da Marginalia | desfeita por |
|---|---|---|
| **leituras** | `get_order`, `search_help`, `get_book` | nada: ler de novo não custa |
| **rascunhos** | escrever uma resposta para uma pessoa enviar | a pessoa não enviar |
| **escritas reversíveis** | anotar um pedido, colocá-lo em espera | apagar a nota, tirar a espera |
| **escritas com custo para reverter** | emitir um reembolso, cancelar um pedido | outra transação, e um pedido de desculpas |
| **irreversíveis ou externas** | mandar um e-mail, publicar algo, apagar os dados de um cliente | nada: já aconteceu |

Um agente cujas ferramentas estão todas nas duas primeiras linhas pode errar à vontade, porque nada do que ele faz chega ao mundo antes de uma pessoa. **A questão de desenho começa na terceira linha**, e a resposta fica mais rígida a cada linha: a ferramenta de reembolso da aula 17 confere os próprios limites, registra quem aprovou e pergunta a uma pessoa antes de rodar.

## A direção do erro importa

Dois erros são possíveis com qualquer ferramenta arriscada, e eles não custam o mesmo. Recusar um reembolso devido custa ao cliente uma segunda mensagem e à loja um pouco de boa vontade. Emitir um reembolso indevido custa dinheiro que raramente volta. Um desenho que pende para um lado de propósito é melhor que um que finge que os dois erros pesam igual: **para escritas com custo, o agente que para e pergunta é a falha mais barata.**

## Desfazer é uma funcionalidade que se constrói

"Reversível" não é propriedade de uma ação em abstrato. Apagar um arquivo é reversível num sistema que tem lixeira e irreversível num que não tem. Um reembolso só é reversível se o sistema de pagamento permite estornar. Então parte de tornar um agente seguro é construir o desfazer nas ferramentas que ele chama: exclusões lógicas, esperas em vez de cancelamentos, rascunhos em vez de envios. **Subir uma ferramenta na tabela costuma sair mais barato que protegê-la onde está.**
