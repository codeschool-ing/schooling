---
title: Automação, assistente, agente
version: 1
---

As três palavras são usadas como se fossem degraus de uma escada de inteligência, com a automação embaixo e os agentes no alto. **Elas não são uma escada.** Um script pode ser a resposta certa para um problema que um agente pioraria, e um agente pode rodar no mesmo modelo que um assistente. O que separa os três é uma pergunta, e ela é sobre controle, não sobre esperteza: **quem decide o próximo passo, e quando?**

- **Automação.** O programador decidiu cada passo antes de o programa rodar. O programa lê um pedido, confere uma regra, imprime uma linha. Diante de uma entrada que ninguém previu, ele para ou faz a coisa errada, porque nada dentro dele consegue escolher outro caminho.
- **Assistente.** Um modelo produz uma resposta, e uma pessoa a lê e decide o que acontece. O modelo pode ser muito capaz; mesmo assim, nunca age. A decisão fica com quem lê o rascunho.
- **Agente.** O modelo escolhe o próximo passo, um programa o executa, o resultado volta para o modelo, e o modelo escolhe de novo, até decidir responder. **A decisão fica dentro de um laço, e quem a tem é o modelo.**

A definição não diz nada sobre quão bom é o modelo, quantas ferramentas ele tem ou se um cliente fala com ele diretamente. São perguntas reais, e as aulas 2 a 6 voltam a elas, mas nenhuma muda qual dos três um sistema é. Um laço com uma ferramenta, em que o modelo decide quando chamá-la e quando parar, é um agente. Um pipeline que chama o melhor modelo do mercado cinco vezes numa ordem fixa é automação com chamadas de modelo dentro.

## Um teste que se aplica ao código

Página de produto não resolve, porque "agente" é palavra que vende. O código resolve. Ache a linha que decide o que o programa faz em seguida e pergunte se ela lê a resposta do modelo:

- `for order in orders: close_window(order)`: o próximo passo é o próximo pedido. Automação.
- `print(reply.text)` e nada depois: uma pessoa decide. Assistente.
- `if reply.stop_reason == "tool_use": run(reply.tool_calls)`: o próximo passo é o que o modelo pediu. Agente.

O `agent.py` do laboratório, que a seção 03 executa, tem quarenta linhas, e esse `if` é a linha que faz dele um agente.

## Por que a distinção merece uma aula

Cada um dos três falha de um jeito, custa de um jeito e é testado de um jeito, e a aula 2 é sobre escolher entre eles. A falha de uma automação é um caminho que ninguém escreveu. A falha de um assistente é um rascunho errado, e uma pessoa costuma pegá-lo. **A falha de um agente é uma ação**, tomada por um programa, com base no erro de um modelo, muitas vezes antes de alguém ler uma palavra. Essa última propriedade é o que as aulas 5, 17 e 18 passam o tempo contendo.
