---
title: DeepSeek
version: 1
---

A DeepSeek é uma empresa chinesa que publica pesos abertos e também vende uma API própria. A aula 2
leu as licenças dela: o código é MIT, os pesos do V3 estão sob uma licença de modelo com restrições de
uso, e o R1 é MIT para código e pesos. Os modelos da API dela, como a tabela os registra:

```
ana@desk:~/desk$ python sheet.py compare deepseek/deepseek-v3.2 deepseek/deepseek-v4-flash deepseek/deepseek-v4-pro deepseek/deepseek-r1
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
deepseek/deepseek-v3.2                          163,840   163840     0.28      0.4  .F.CR.
deepseek/deepseek-v4-flash                    1,000,000   393216      0.3      1.2  VFSCR.
deepseek/deepseek-v4-pro                      1,000,000   393216     1.32     3.96  .FSCR.
deepseek/deepseek-r1                             65,536     8192     0.55     2.19  .F.CR.
```

**V4 Flash e V4 Pro** são a geração atual, os dois com janela de um milhão de tokens; V3.2 e R1 são mais
antigos e ainda têm preço. Os nomes a que a API respondia sumiram:

```
ana@desk:~/desk$ python sheet.py retiring --provider deepseek
# LiteLLM model sheet at 21881c57, 4472 entries
4 entries carry a deprecation date
2026-07-24  deepseek-chat                                      deepseek
2026-07-24  deepseek-reasoner                                  deepseek
2026-07-24  deepseek/deepseek-chat                             deepseek
2026-07-24  deepseek/deepseek-reasoner                         deepseek
```

`deepseek-chat` e `deepseek-reasoner` eram os dois apelidos da API, e foram aposentados em 24 de julho de
2026. Um programa escrito contra eles em 2025 parou de responder naquele dia, que é a aula 2 seção 06
acontecendo com uma família de pesos abertos: **os pesos são abertos, a API do autor continua sendo um
serviço com datas**.

## O autor não é o host mais barato

A aula 2 viu que ninguém consegue cobrar menos que o autor de um modelo fechado. Num modelo aberto
acontece o contrário. O V4 Flash é oferecido por muitos hosts:

```
ana@desk:~/desk$ python sheet.py where deepseek-v4-flash | tail -n +3 | wc -l
33
```

```
ana@desk:~/desk$ python sheet.py where deepseek-v4-flash | grep -E "^(deepseek/|azure|tencent|scaleway|novita/deepseek/deepseek-v4-flash )"
azure_ai/deepseek-v4-flash                           azure_ai                       0.19     0.51
deepseek/deepseek-v4-flash                           deepseek                        0.3      1.2
deepseek/deepseek-v4-flash-vision-exp                deepseek                        0.3      1.2
novita/deepseek/deepseek-v4-flash                    novita                         0.14     0.28
scaleway/deepseek-v4-flash-0731                      scaleway                        0.4      0.8
tencent/deepseek-v4-flash                            tencent                        0.14     0.28
```

Trinta e três entradas. **A API da própria DeepSeek, a US$ 0,30 e US$ 1,20, não é a mais barata**: dois dos
hosts acima oferecem o mesmo modelo a US$ 0,14 e US$ 0,28, menos da metade do preço de entrada e menos de um
quarto do de saída. O autor concorre com todo mundo que baixou os pesos dele.

Para a ana isso transforma uma pergunta em duas. Se o DeepSeek V4 Flash é bom o bastante é a pergunta
da aula 5, respondida uma vez. Onde rodá-lo é a pergunta da aula 10 seção 05, respondida host a host por
preço, latência, precisão e, para uma loja brasileira, **onde o host processa os dados**. Na API do
próprio autor isso quer dizer uma empresa sediada na China; nos outros, onde cada um disser.
