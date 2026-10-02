---
title: Mostrando uma resposta enquanto é escrita
version: 1
---

Modelos respondem em Markdown, e uma página o renderiza. **Uma resposta pela metade é Markdown pela
metade**, e os momentos intermediários são o que uma pessoa vê. O `partial.py` imprime o texto que
uma página teria em três momentos:

```python
"""What a page would have to render at each moment of a reply written in Markdown."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "The cents rule, as a short list."}]
sofar = ""
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for n, text in enumerate(stream.text_stream, 1):
        sofar += text
        if n in (2, 5, 12):
            print(f"after {n:2} pieces: {sofar!r}")
print(f"at the end:      {sofar!r}")
```

```
ana@dev:~/shop$ python partial.py
after  2 pieces: '**Store'
after  5 pieces: '**Store cents, never'
after 12 pieces: '**Store cents, never floats.** Then:\n\n- add'
at the end:      '**Store cents, never floats.** Then:\n\n- add integers\n- round once, at the end\n- format at the edge'
```

**Depois de dois pedaços o texto é `**Store`**, um marcador de abertura sem fechamento. Renderizado
assim, a página mostra dois asteriscos; uma página que espera o fechamento ainda não mostra nada; uma
página que adivinha mostra um negrito que vira texto comum, ou o contrário, conforme os pedaços
chegam. A lista depois de doze pedaços é um item com uma palavra só.

## Renderizar sem piscar

- **Renderize o texto até ali a cada pedaço**, com um renderizador de Markdown que tolere marcadores
  abertos. A maioria tolera: um `**` aberto sai como dois asteriscos literais por um instante e vira
  negrito quando o fechamento chega.
- **Ou renderize blocos completos e mostre o resto sem formatação.** Tudo até a última linha em
  branco é um parágrafo ou lista terminado; só a última parte ainda está mudando.
- **Não mexa no que o leitor está lendo.** Role para acompanhar o texto novo só enquanto o leitor
  está no fim. Quem subiu para reler uma frase não deve ser arrancado dela.

## O que o resto da página deve fazer

- **Mostrar que algo está acontecendo antes da primeira palavra.** O tempo até o primeiro token é um
  décimo de segundo no laboratório e pode ser vários segundos com um prompt longo. Um aviso de que a
  resposta está vindo é melhor que nada na tela.
- **Oferecer Parar durante o stream**, e cumprir, como a aula 9 seção 06 faz.
- **Anunciar a resposta uma vez, completa, a um leitor de tela.** Uma região viva atualizada a cada
  pedaço lê fragmentos, um atrás do outro. Atualizá-la com a resposta terminada, ou por frase, dá a
  quem ouve algo que consegue acompanhar.
