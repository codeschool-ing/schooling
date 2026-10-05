---
title: Três famílias lado a lado
version: 1
---

As três famílias desta aula, e a Llama da anterior, respondem de jeitos diferentes às perguntas da
aula 2. Lado a lado, a partir do que este curso conseguiu ler:

| | autor | licença dos pesos, como lida aqui | API do próprio autor | nomes a conhecer |
|---|---|---|---|---|
| Llama | Meta, EUA | própria, com limite de usuários e *Built with Llama* (aula 2) | não tratada aqui | `instruct`, `17Bx128E` |
| DeepSeek | DeepSeek, China | MIT para o R1; uma licença de modelo com restrições de uso para o V3 (aula 2) | sim, apelidos aposentados em julho de 2026 | `flash`, `pro`, `r1` |
| Qwen | Alibaba, China | Apache 2.0 para os modelos de pesos abertos da Qwen 3 | sim, com o Max não aberto | `235b-a22b`, `instruct`, `thinking` |
| Gemma | Google, EUA | termos próprios do Google, inalcançáveis do laboratório | por hosts e pelas plataformas do Google | `-it`, `A4B`, `E4B` |

Três coisas que esta tabela diz e uma lista de preços não diz.

**"Aberto" são quatro licenças diferentes.** Cada linha precisa de leitura própria, e a resposta para
uma versão não é a resposta para a seguinte, como mostra a mudança da Qwen de Tongyi Qianwen para Apache.

**Onde o autor fica é um fato sobre a API dele, não sobre os pesos.** Usar a API da própria DeepSeek ou
da Alibaba manda o e-mail da Lantern Books para uma empresa na China, o que alguns contratos e algumas
regras de dados tratam de outro jeito. Rodar os mesmos pesos num host no Brasil, ou na máquina da
própria ana, não. A aula 2 seção 07 traçou essa linha para modelos fechados; para os abertos, é na
escolha do **host** que ela é traçada.

**Mistura de especialistas virou o formato comum.** Llama 4, os modelos grandes da Qwen 3 e o `A4B` da
Gemma 4 guardam muito mais do que calculam. Os dois tamanhos da aula 10 seção 03, memória pelo total e
velocidade pela parte ativa, são a conta para todos eles.
