---
title: Mostrando uma resposta enquanto é escrita
version: 2
---

Modelos respondem em Markdown, e uma página o renderiza. **Uma resposta pela metade é Markdown pela
metade**, e os momentos intermediários são o que uma pessoa vê. O `partial.py` pede uma lista com
palavras em negrito e imprime o fim do texto que uma página teria cada vez que um negrito abre ou
fecha:

```python
"""What a page would have to render at each moment of a reply written in Markdown."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Why does a shop keep prices as whole cents? "
                                   "A short Markdown list, with the key word of each item in bold."}]
sofar = ""
was_open = False
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for n, text in enumerate(stream.text_stream, 1):
        sofar += text
        is_open = sofar.count("**") % 2 == 1
        if is_open != was_open:
            print(f"after {n:3} pieces, bold {'opened' if is_open else 'closed'}: {sofar[-36:]!r}")
            was_open = is_open
print(f"at the end, {n} pieces and {len(sofar)} characters")
```

```
ana@dev:~/shop$ python partial.py
after  16 pieces, bold opened: ' keep prices as whole cents:\n\n*   **'
after  19 pieces, bold closed: 's as whole cents:\n\n*   **Rounding**:'
after  37 pieces, bold opened: 'lculations and reduce errors.\n*   **'
after  40 pieces, bold closed: 'uce errors.\n*   **Price stability**:'
after  59 pieces, bold opened: ' of small price fluctuations.\n*   **'
after  62 pieces, bold closed: ' fluctuations.\n*   **Cost control**:'
after  89 pieces, bold opened: 'the accuracy of calculations.\n*   **'
after  92 pieces, bold closed: 'lations.\n*   **Marketing strategy**:'
after 116 pieces, bold opened: 'ore appealing or competitive.\n*   **'
after 120 pieces, bold closed: 'r competitive.\n*   **Practicality**:'
at the end, 172 pieces and 884 characters
```

**Cinco palavras em negrito, e cada uma fica aberta por três ou quatro pedaços**: depois de 16
pedaços o texto termina em `**`, um marcador de abertura sem fechamento, e `**Rounding**` só fica
completo no pedaço 19. Renderizado assim, a página mostra dois asteriscos; uma página que espera o
fechamento ainda não mostra nada; uma página que adivinha mostra um negrito que vira texto comum, ou o
contrário, conforme os pedaços chegam. Cinco vezes numa resposta curta, cada uma por uns três décimos
de segundo nesta velocidade, o que é tempo bastante para ser visto.

## Renderizar sem piscar

- **Renderize o texto até ali a cada pedaço**, com um renderizador de Markdown que tolere marcadores
  abertos. A maioria tolera: um `**` aberto sai como dois asteriscos literais por um instante e vira
  negrito quando o fechamento chega.
- **Ou renderize blocos completos e mostre o resto sem formatação.** Tudo até a última linha em
  branco é um parágrafo ou lista terminado; só a última parte ainda está mudando.
- **Não mexa no que o leitor está lendo.** Role para acompanhar o texto novo só enquanto o leitor
  está no fim. Quem subiu para reler uma frase não deve ser arrancado dela.

## O que o resto da página deve fazer

- **Mostrar que algo está acontecendo antes da primeira palavra.** O tempo até o primeiro token foi
  de três décimos de segundo na seção 01, e são vários segundos com um prompt longo ou um modelo
  ainda carregando. Um aviso de que a
  resposta está vindo é melhor que nada na tela.
- **Oferecer Parar durante o stream**, e cumprir, como a aula 9 seção 06 faz.
- **Anunciar a resposta uma vez, completa, a um leitor de tela.** Uma região viva atualizada a cada
  pedaço lê fragmentos, um atrás do outro. Atualizá-la com a resposta terminada, ou por frase, dá a
  quem ouve algo que consegue acompanhar.
