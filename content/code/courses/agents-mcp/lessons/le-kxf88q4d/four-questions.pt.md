---
title: Quatro perguntas antes de construir um
version: 2
---

Antes de escrever um laço, responda quatro perguntas sobre a tarefa. Levam cinco minutos, e cada uma tem uma resposta que descarta um agente.

**1. O caminho pode ser escrito?** Liste os passos que uma pessoa dá. Se a lista é a mesma toda vez, ou se ramifica em poucas coisas que você sabe nomear, é um workflow: programe a lista, e chame um modelo só onde um passo exige ler ou escrever. Se a resposta honesta é "depende do que encontrarmos", a tarefa tem o formato que a aula 1 descreveu.

**2. Quanto custa um passo errado, e ele pode ser desfeito?** Ler o artigo errado custa um pedido. Reembolsar o pedido errado custa dinheiro e um pedido de desculpas. A seção 06 ordena as ações por quanto dá para voltar atrás; um agente que só lê pode receber muito mais liberdade que um que escreve.

**3. O resultado pode ser conferido?** A resposta de um agente vale tanto quanto a capacidade de alguém de dizer se ela está certa. Código que compila e passa nos testes é verificável. Um valor de reembolso pode ser comparado com o pedido. "Este é um bom resumo das novas condições do fornecedor?" exige uma pessoa, e se essa pessoa precisa ler as fontes de qualquer jeito, o agente poupou menos do que parecia.

**4. O volume e o prazo permitem?** Na seção 05, o agente gasta 37,4 s de tempo de modelo e 1641 tokens de entrada em três mensagens, enquanto o roteador gasta 2,0 s e 234 tokens em quatro. Para uma pergunta de pesquisa por dia isso é irrelevante. Para cada mensagem de uma fila de suporte movimentada, é a conta e é a fila.

| resposta | aponta para |
|---|---|
| o caminho é uma lista fixa | automação, ou um workflow com chamadas de modelo |
| o caminho se ramifica numa leitura da entrada | um workflow com roteamento |
| o próximo passo depende do último resultado, e o resultado pode ser conferido | um agente |
| um passo errado não pode ser desfeito | um agente só atrás da confirmação de uma pessoa (aula 17) |
| milhares de pedidos por dia com prazo | um workflow, com um agente para os casos que ele não roteia |

A última linha é comum na prática e vale dizer com todas as letras: **os dois não se excluem.** Um roteador que trata nove mensagens em dez com procedimentos fixos, e passa a décima a um agente ou a uma pessoa, fica com quase todo o custo de um workflow e quase todo o alcance de um agente.
