---
title: Cinco propostas na Marginalia
version: 1
---

Cinco ideias chegam à equipe da ana na mesma semana. Aqui está cada uma passada pelas quatro perguntas da seção 03, com a decisão e o motivo que a fechou.

**"Um agente que responde perguntas sobre senha."** O caminho é um artigo de ajuda, o `h26`, toda vez. Uma busca e um modelo de texto resolvem, ou um link na página de entrada. **Não é agente**: a primeira pergunta falha, e qualquer coisa a mais acrescenta pedidos a um problema de resposta fixa.

**"Dizer aos clientes onde está o pedido."** Uma consulta pelo id do pedido, uma frase montada a partir do status. O único julgamento é ler o id dentro de uma mensagem, o que uma expressão regular ou uma chamada de modelo faz. **Um workflow**, o roteador da seção 05 com um modelo de texto melhor.

**"Tratar as mensagens que o roteador passa para uma pessoa."** Essas são, por construção, os casos que nenhum ramo cobre: reclamações, problemas misturados, pedidos estranhos. O caminho depende do que cada consulta devolve, e a resposta pode ser conferida contra o pedido e a central de ajuda. **Um agente, com ferramentas só de leitura**, cuja saída uma pessoa revisa antes do envio. Rascunho primeiro; agir depois, quando houver evidência de com que frequência os rascunhos acertam.

**"Deixar o agente emitir reembolsos de livros danificados."** A política é clara (`h12`: fotos em até 14 dias, troca sem custo), então a maior parte do caminho pode ser escrita. A ação custa dinheiro para reverter. **Um workflow para a verificação, e o reembolso atrás da confirmação de uma pessoa**, que é o desenho da aula 17. Dar ao agente a ferramenta de reembolso para que ele decida sozinho se uma foto mostra dano põe o erro mais caro no lugar menos verificável.

**"Escrever o relatório noturno de estoque."** Uma consulta, uma tabela, um e-mail para duas pessoas. Nenhuma leitura de texto livre. **Automação**: um modelo não acrescenta nada aqui além de um jeito de os números saírem errados.

## O que as cinco têm em comum

Só uma das cinco virou agente, e é aquela que existe porque as outras foram construídas antes. **O ramo "other" do roteador é de onde vem o trabalho de um agente**: ele junta, todo dia, as mensagens que um caminho fixo não conseguiu tratar, e o tamanho dele é a medida honesta de quanto um agente é necessário. A aula 7 constrói esse agente direito, e as aulas 8 a 10 o reconstroem com os kits de três fornecedores.
