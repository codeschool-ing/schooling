---
title: Por que uma resposta inventada é um problema de segurança
version: 1
---

Um modelo gera o texto que tende a seguir a entrada dele. Se esse texto é verdadeiro não faz parte de como ele é produzido. Por isso um modelo pode afirmar uma política que não existe, citar uma fonte que ninguém escreveu ou nomear um pacote que ninguém publicou, exatamente no tom que usa para fatos. Isso
costuma se chamar **alucinação**. A visão comum é que se trata de um problema de qualidade, um incômodo
para os usuários. Dois casos mostram por que essa visão é pequena demais.

**Uma promessa que a empresa não fez, e pagou.** Em *Moffatt v. Air Canada* (2024), um cliente perguntou
ao chatbot do site da Air Canada sobre tarifas para luto. O chatbot disse que o reembolso podia ser
pedido depois do voo, o que a própria página de política da companhia não permitia. Quando o cliente o
pediu, a companhia argumentou, entre outras coisas, que o chatbot respondia pelas próprias palavras. O
Civil Resolution Tribunal da Colúmbia Britânica rejeitou isso e mandou a companhia pagar. **O que o
assistente diz a um cliente é o que a empresa diz.**

**Fontes que não existiam, protocoladas num tribunal.** Em *Mata v. Avianca* (2023), advogados em Nova
York protocolaram uma petição citando decisões judiciais que um chatbot produziu e que nunca foram
proferidas. O juiz os sancionou. Ninguém invadiu nada; uma invenção fluente passou sem conferência para
um documento em que pessoas confiaram.

Na Tarefa as mesmas formas estão à mão. Um assistente que diz a um cliente que o prazo de reembolso é de
30 dias quando é de 14 fez à Tarefa uma promessa a ser discutida. Um que inventa uma *Garantia Tarefa*
inventou um produto.

## Por que isto pertence à segurança

Três propriedades põem o assunto neste curso, e não só numa revisão de qualidade:

- **É explorável.** Quando um modelo inventa sempre o mesmo nome, como um pacote de software, alguém pode
  registrar esse nome e esperar. A terceira seção desta aula é esse caso.
- **Carrega uma autoridade que não conquistou.** Uma resposta errada de um formulário que diz
  *"respondemos em dois dias"* é visivelmente um palpite. Uma resposta errada na voz confiante do
  assistente é lida como política.
- **Não pode ser consertada dentro do modelo.** Modelos melhores inventam menos; nenhum inventa nada. A
  defesa é a mesma da aula 9: verificações em volta do modelo, escritas em código, que não dependem de o
  modelo estar certo.

A aula 5 de `prompt-engineering`, que este curso pressupõe, explicou por que modelos inventam e como um
prompt reduz isso. Esta aula trata dos casos em que errar tem um custo além da resposta, e das
verificações que impedem que eles cheguem a um cliente.
