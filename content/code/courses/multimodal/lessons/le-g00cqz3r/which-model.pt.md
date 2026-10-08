---
title: O DALL-E, e os nomes que o substituíram
version: 2
---

O título desta aula cita o **DALL-E**, e o curso foi desenhado quando esse era o nome do modelo de imagem da OpenAI. Já não é o nome a escrever no código. A tabela do LiteLLM, lida com o `prices.py` da aula 3, lista os modelos de imagem que ela arquiva sob a OpenAI assim:

```
ana@lab:~/mm$ python prices.py find "" image_generation | grep " openai " | grep -vE "^(low|medium|high|standard|hd|[0-9])"
chatgpt-image-latest                         openai                     2026-12-01
gpt-image-1                                  openai                     2026-10-23
gpt-image-1-mini                             openai                     2026-12-01
gpt-image-1.5                                openai                     2026-12-01
gpt-image-1.5-2025-12-16                     openai                     2026-12-01
gpt-image-2                                  openai                     
gpt-image-2-2026-04-21                       openai                     
gpt-image-2.5-flare                          openai                     
gpt-image-2.5-flare-2026-09-08               openai                     
gpt-image-2.5-sunburst                       openai                     
gpt-image-2.5-sunburst-2026-09-08            openai                     
ana@lab:~/mm$ python prices.py show gpt-image-1 | grep -E "deprecation|supported_endpoints"
deprecation_date                           2026-10-23
supported_endpoints                        ['/v1/images/generations', '/v1/images/edits']
ana@lab:~/mm$ for q in low medium high; do printf "%-7s" $q; python prices.py show $q/1024-x-1024/gpt-image-1 | grep input_cost_per_image; done
low    input_cost_per_image                       0.011
medium input_cost_per_image                       0.042
high   input_cost_per_image                       0.167
```

**Não há mais `dall-e-3` entre as entradas da própria OpenAI**; o nome sobrevive na tabela só em outros provedores que o revendem. O que a OpenAI lista é a família de imagem GPT, do `gpt-image-1` ao `gpt-image-2.5`, com versões datadas como `gpt-image-2-2026-04-21`. E a última coluna é a que importa: o próprio `gpt-image-1` traz uma **data de descontinuação em 23 de outubro de 2026**, dezesseis dias depois de esta aula ser gravada, e quase toda a família abaixo do `gpt-image-2` acaba em 1º de dezembro.

Três hábitos decorrem disso, e importam mais em geração de imagens do que em qualquer outro lugar deste curso, porque modelos de imagem são substituídos mais rápido que os de texto:

1. **Cite uma versão datada** (`gpt-image-1.5-2025-12-16`) em produção, para o modelo não mudar debaixo de você, e um apelido (`gpt-image-1.5`) só onde você quer o mais novo.
2. **Guarde o nome do modelo num só lugar**, lido da configuração, para que sair de um modelo descontinuado seja uma mudança de uma linha e uma rodada de testes, não uma busca pelo código.
3. **Rode de novo a grade da aula 3 no modelo novo antes de trocar.** O mesmo prompt num modelo novo é outro experimento; um estilo de banner que levou duas rodadas para assentar pode se mover.

O `prices.py find` imprime a data de descontinuação de cada entrada na última coluna, e vale rodá-lo todo trimestre contra os nomes que o seu código usa.
