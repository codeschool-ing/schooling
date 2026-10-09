---
title: Os modelos de chat da Cohere
version: 1
---

A Cohere e a Mistral dividem esta aula porque cada uma é menor que as três anteriores e cada uma
vale a pena por algo particular: a Cohere por **busca**, a Mistral por **pesos abertos de uma
empresa europeia**. Nenhuma das páginas pôde ser alcançada da máquina em que este curso foi gravado,
então as duas são lidas na tabela.

Os modelos de chat da Cohere, como a tabela os registra:

```
ana@desk:~/desk$ python sheet.py provider cohere_chat
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
c4ai-aya-expanse-32b                            128,000     4000      0.5      1.5  ......
command-a-03-2025                               256,000     8000      2.5       10  .F....
command-a-plus-05-2026                          128,000    64000        0        0  VFS.R.
command-r-08-2024                               128,000     4096     0.15      0.6  .F....
command-r-plus-08-2024                          128,000     4096      2.5       10  .F....
command-r7b-12-2024                             128,000     4096   0.0375     0.15  .F....
```

A linha **Command**, em nomes datados: `command-a-03-2025` é o Command A de março de 2025, o maior
com preço aqui, a US$ 2,50 e US$ 10, e `command-r7b-12-2024` o menor, a menos de quatro centavos o
milhão de tokens de entrada. A entrada mais nova, `command-a-plus-05-2026`, tem preço **0 e 0**.

Um preço zero nesta tabela não quer dizer grátis. Veja o mesmo modelo em todos os hosts:

```
ana@desk:~/desk$ python sheet.py where command-a-plus
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
aihubmix/command-a-plus-05-2026                      aihubmix                        2.5       10
azure_ai/Cohere-command-a-plus-05-2026               azure_ai                        0.8      3.2
command-a-plus-05-2026                               cohere_chat                       0        0
openrouter/cohere/command-a-plus                     openrouter                      0.3      1.5
```

Quatro entradas, quatro preços: US$ 2,50 e US$ 10 num revendedor, US$ 0,80 e US$ 3,20 na Azure, US$
0,30 e US$ 1,50 no OpenRouter, e zero na própria Cohere. **A tabela discorda de si mesma.** Parte
disso é real, hosts definem os próprios preços para modelos de pesos abertos, e parte é a cópia de
um terceiro atrasada em relação à fonte. O `sheet.py pick` da aula 4 deixa de fora as entradas com
preço zero exatamente por isso: um zero quer dizer "desconhecido" tanto quanto "grátis".

**A regra para um número assim é ir ao autor.** A página de preços da Cohere aparece como fonte nas
entradas de rerank (próxima seção); para um modelo que a ana possa colocar em produção, essa página,
lida no dia, vale mais que qualquer cópia.

## Onde o Command entra na lista da ana

Um Command A a US$ 2,50 de entrada fica entre o Claude Sonnet e o GPT-5.4 no preço, com janela de
256.000 tokens e chamada de função mas, segundo a tabela, sem `S`: saída estruturada não está
registrada. Isso o tira da extração até ser conferido, como a DeepSeek na aula 4, e o deixa
candidato para classificar e rascunhar como qualquer outra linha.
