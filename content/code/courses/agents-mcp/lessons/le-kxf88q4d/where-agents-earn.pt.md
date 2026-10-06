---
title: Onde um agente justifica o custo
version: 1
---

A imagem errada é a de que um agente é a versão avançada de qualquer programa que usa um modelo, e por isso uma equipe que leva IA a sério constrói agentes. As medições da seção 05 dizem outra coisa para a maior parte do que uma loja como a Marginalia precisa. **Um agente é a ferramenta certa para um formato de problema: o caminho até a resposta não pode ser escrito antes de o trabalho começar.**

Esse formato aparece em alguns lugares reconhecíveis:

- **Casos de suporte abertos.** "Meu pacote aparece como entregue, meu vizinho tem uma caixa com meu nome e fui cobrado duas vezes" são três problemas, e qual consultar primeiro depende do que cada consulta devolve. Uma árvore de decisão para cada combinação fica maior que o código que deixaria um modelo escolher.
- **Pesquisa em várias fontes.** Responder "quais fornecedores nossos mudaram as condições este ano" exige ler uma coisa, decidir o que ler em seguida e parar quando a pergunta estiver respondida. O número de documentos é desconhecido no começo.
- **Mudanças de código.** Descobrir por que um teste falha exige ler arquivos escolhidos pelo que o último arquivo disse. Assistentes de código que editam e rodam código num laço são os agentes mais usados que existem, porque nenhum script fixo acha um bug desconhecido.
- **Triagem de operações.** Um alerta dispara; a próxima consulta depende do último gráfico. Um runbook cobre as causas conhecidas e deixa de ajudar na primeira desconhecida.

Em cada caso, uma pessoa fazendo o trabalho também decidiria o próximo passo olhando o último resultado. **Esse é um bom teste para saber se a tarefa tem o formato: um procedimento escrito que um funcionário novo e competente seguiria sem julgamento é um procedimento que um workflow também segue.**

## Onde é exagero

A maioria dos pedidos na Marginalia tem caminho conhecido. *"Onde está meu pedido?"* é uma consulta e uma frase. *"Como redefino minha senha?"* é um artigo. O relatório noturno de estoque é uma consulta e um modelo de texto. Embrulhar isso num laço acrescenta pedidos, tokens, segundos e um jeito novo de errar, e devolve a mesma resposta que um caminho fixo daria, quando funciona. A seção 05 mede exatamente quanto se acrescenta.

Há também um meio-termo que a palavra "agente" esconde. Muitos sistemas úteis dão ao modelo **uma** decisão, como qual ramo seguir ou o que extrair, e mantêm o resto no código. Eles parecem produtos de IA e são workflows. A seção 04 dá nome aos mais comuns.
