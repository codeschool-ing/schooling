---
title: Qual ferramenta para qual imagem
version: 1
---

As três ferramentas desta aula não são degraus de uma escada em que o VLM é simplesmente melhor. Cada uma responde a uma pergunta diferente a um custo diferente, e a escolha certa costuma ser a mais barata que responde à sua.

| a imagem, e a pergunta | a ferramenta | por quê |
|---|---|---|
| um PDF com camada de texto: *o que ele diz?* | nenhum modelo; leia a camada de texto | exato e de graça (aula 1) |
| um escaneado impresso de layout conhecido: *quais são os campos?* | OCR, depois regras, depois conferências | 0,4% de CER no escaneado deste laboratório, em milissegundos, na máquina |
| uma foto: *há uma pessoa, um carro, um cachorro, e onde?* | um detector | geometria, velocidade e nenhum custo por chamada, se a classe está na lista |
| uma foto ou página com pergunta aberta: *o que é isto, há algo errado?* | um modelo de visão e linguagem | vocabulário aberto, layout, raciocínio |
| letra à mão, um recibo amassado, um layout que muda toda vez | um modelo de visão e linguagem, conferido | a suposição de linhas do OCR deixa de valer |
| qualquer coisa que termine em dinheiro ou numa decisão sobre uma pessoa | qualquer um dos acima **e uma conferência que não seja um modelo** | o dígito mal lido é idêntico a um certo |

Dois padrões desta aula combinam as linhas.

**Barato primeiro, caro na dúvida.** Rode o OCR; se as conferências aritméticas passarem, o trabalho acabou; se falharem, mande a mesma página a um VLM ou a uma pessoa. Com um fornecedor que manda PDFs limpos, o caminho caro quase nunca roda.

**Um modelo para o sentido, uma ferramenta mais barata para a prova.** Um VLM consegue ler um recibo amassado que o OCR não lê, e o total que ele devolve ainda pode ser conferido contra os itens que ele também devolve. A conferência não precisa de modelo nenhum.

A pergunta com que esta aula começou é a que vale continuar fazendo: *qual é a ferramenta mais barata que lê esta imagem bem o bastante, e como vou saber quando ela não leu?*
