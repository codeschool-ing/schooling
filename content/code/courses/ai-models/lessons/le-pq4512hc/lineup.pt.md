---
title: A linha
version: 1
---

As páginas do próprio Google não puderam ser alcançadas da máquina em que este curso foi gravado,
então esta aula lê a família inteira na tabela do LiteLLM. Toda entrada do Gemini ali cita a página
de preços do Google como fonte:

```
ana@desk:~/desk$ sheet show gemini/gemini-3.5-flash | grep -E "^(source|rpm|tpm)"
rpm                                        2000
source                                     https://ai.google.dev/gemini-api/docs/pricing
tpm                                        800000
```

Essa linha `source` é a tabela dizendo de onde copiou os números. O `rpm` e o `tpm` ao lado são
requisições e tokens por minuto, os limites do nível de conta que quem mantém a tabela registrou; a
aula 21 trata de limites como esses, e os de uma conta nova costumam ser menores.

A linha atual, como a tabela a tem:

```
ana@desk:~/desk$ sheet compare gemini/gemini-3.5-flash-lite gemini/gemini-3.5-flash gemini/gemini-3.1-pro-preview gemini/gemini-flash-latest gemini/gemini-pro-latest
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
gemini/gemini-3.5-flash-lite                  1,048,576    65536      0.3      2.5  VFSCRP
gemini/gemini-3.5-flash                       1,048,576    65536      1.5        9  VFSCRP
gemini/gemini-3.1-pro-preview                 1,048,576    65536        2       12  VFSCRP
gemini/gemini-flash-latest                    1,048,576    65536     0.75     3.75  VFSCRP
gemini/gemini-pro-latest                      1,048,576    65536        2       12  VFSCRP
```

**Três faixas de novo**, com nomes de velocidade: **Flash-Lite**, a mais barata, **Flash** e **Pro**.
Todas têm janela de 1.048.576 tokens, um milhão em binário, e escrevem até 65.536. A janela é a mesma
em todo preço, que é a primeira coisa que separa esta família da aula anterior, em que o modelo mais
barato tinha um quinto da janela.

## Números de versão que não se alinham

Duas características dos nomes pegam qualquer um que escolha por uma lista:

- **As faixas não compartilham versão.** Neste commit Flash e Flash-Lite estão na 3.5 e o Pro na
  3.1, e ainda `preview`. "O Gemini mais novo" são três números diferentes.
- **Os nomes `-latest` são apelidos**, o tipo móvel da aula 2 seção 06, e não apontam para onde os
  números sugerem. O `gemini-flash-latest` custa US$ 0,75 e US$ 3,75, o preço de outra entrada Flash,
  e não do `gemini-3.5-flash`, a US$ 1,50 e US$ 9. Um apelido chamado "latest" é o que o Google estiver
  servindo com esse nome no momento, e o preço diz que não é a entrada 3.5 logo acima.

Para a ana isso significa uma regra da aula 2 aplicada à risca: **avaliar e fixar o identificador
numerado**, `gemini/gemini-3.5-flash-lite`, nunca o `flash-lite-latest`. O rascunho dela custou US$
8,02 por mês com cache no Flash-Lite na aula 4, menos da metade dos US$ 18,72 do Haiku, e a nota dele nos casos dela
é a única coisa que pode dizer se isso é uma pechincha.
