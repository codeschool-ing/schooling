---
title: Um primeiro notebook, e os três programas por trás dele
version: 1
---

**Um notebook parece um programa e são três.** A página no seu navegador é um documento: uma lista
de células, umas de código e outras de texto. O código dela não roda no navegador. Ele roda num
**kernel**, um processo Python que o JupyterLab iniciou para este notebook e que fica esperando
código chegar. Entre os dois fica o **servidor Jupyter**, o programa que você iniciou no terminal,
que grava o documento em disco e leva o código ao kernel e os resultados de volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três programas. O navegador tem a página de células e manda código ao servidor Jupyter, que o repassa ao kernel, um processo Python que guarda o estado; os resultados voltam pelo mesmo caminho. O servidor também grava o notebook em disco como first.ipynb.\" data-fig=\"three\"><defs><marker id=\"three-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"170\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">seu navegador</text><text x=\"105.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a página: células, saídas</text><rect x=\"275\" y=\"50\" width=\"170\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">servidor Jupyter</text><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">iniciado no terminal</text><rect x=\"530\" y=\"50\" width=\"170\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">kernel</text><text x=\"615.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o Python e suas variáveis</text><rect x=\"275\" y=\"185\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">first.ipynb</text><text x=\"360.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">em disco</text><line x1=\"194\" y1=\"80\" x2=\"271\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><line x1=\"271\" y1=\"110\" x2=\"194\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><line x1=\"449\" y1=\"80\" x2=\"526\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><line x1=\"526\" y1=\"110\" x2=\"449\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><text x=\"232\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">código</text><text x=\"232\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">saídas</text><text x=\"487\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">código</text><text x=\"487\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">resultados</text><line x1=\"360\" y1=\"144\" x2=\"360\" y2=\"181\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#three-ah)\"></line><text x=\"388\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">grava</text></svg>", "caption": "A página mostra o que o kernel disse quando cada célula rodou. O kernel guarda o que vale agora.", "same": ["kernel"]}
```

Quase tudo o que confunde as pessoas em notebooks vem de esquecer o meio desse desenho. A página
mostra o que o kernel disse **no momento em que cada célula rodou**; o kernel guarda o que vale
**agora**. A aula 2 é sobre o dia em que os dois discordam.

## Criando um

No lançador do JupyterLab, em **Notebook**, escolha **Python 3 (ipykernel)**. Abre uma aba com uma
célula vazia e o nome `Untitled.ipynb`. Clique na aba com o botão direito, escolha **Rename
Notebook…** e chame-o de `first.ipynb`.

Digite na célula e aperte **Shift+Enter**:

```python
1 + 1
```
```
2
```

A resposta aparece embaixo da célula, e o cursor passa para uma nova. O número entre colchetes à
esquerda, `[1]`, é o **contador de execução**: a contagem do próprio kernel de quantas células ele
já rodou. É o único rastro, na página, da ordem em que as coisas aconteceram, e a aula 2 se apoia
nele.

A primeira coisa que vale perguntar a qualquer kernel é qual Python ele é:

```python
import sys
sys.executable
```
```
'/home/ana/pydata/.venv/bin/python'
```

O caminho termina em `pydata/.venv/bin/python`, então este notebook roda dentro do ambiente que
você montou, com as bibliotecas que fixou. Se aparecer qualquer outro, a seção sobre falhas no fim
desta aula é o lugar para ir.

## Um valor, e o que a página mostra dele

Os dados estão na mesma pasta, então o kernel consegue abri-los como qualquer arquivo:

```python
with open("weather.csv") as f:
    lines = f.readlines()
len(lines)
```
```
366
```

Um cabeçalho e uma linha por dia de 2025. Uma célula pode ter várias linhas, e **o valor da última
é o que aparece embaixo dela**, como aconteceu com `len(lines)`. Nada mais da célula aparece a não
ser que você imprima, e as duas coisas não são iguais:

```python
print(lines[1])
lines[1]
```
```
2025-01-01,0.0,29.9

'2025-01-01,0.0,29.9\n'
```

`print` escreve o texto, então a linha termina onde a quebra de linha manda, e a linha em branco
embaixo é essa quebra. O `lines[1]` sozinho na última linha aparece como sua **representação**, a
forma que o Python aceitaria de volta como código: aspas em volta, e a quebra escrita como `\n`.
Toda saída deste curso é uma ou outra, e vale reparar qual quando um número parecer estranho.

Python puro já responde perguntas sobre este arquivo:

```python
rain = [float(line.split(",")[1] or "nan") for line in lines[1:]]
wet_days = [r for r in rain if r > 0]
len(wet_days), max(rain)
```
```
(167, 45.9)
```

Isso diz que o Recife teve 167 dias com chuva em 2025, e 45,9 mm no mais chuvoso deles. E não diz
nada sobre os seis dias sem leitura nenhuma. Cada um virou `nan`, e `nan > 0` é falso, então eles
saíram da contagem sem uma palavra; `max` os pulou pelo mesmo motivo. Um programa que roda ainda
não é um programa que contou tudo, e as aulas 9 e 12 voltam aos dias faltantes com ferramentas
melhores do que uma list comprehension.

## Dois modos, e as teclas que vale aprender

Uma célula está em **modo de edição** quando o cursor está nela e as teclas digitam texto, e em
**modo de comando** quando está selecionada, com uma barra azul à esquerda, e as teclas agem sobre
as células. **Esc** sai do modo de edição e **Enter** volta.

| no modo de comando | faz |
|---|---|
| **A** / **B** | insere uma célula acima / abaixo |
| **D**, **D** | apaga a célula |
| **M** / **Y** | torna a célula Markdown / código |
| **Z** | desfaz a última operação de célula |
| **Shift+Enter** | roda a célula e passa para a próxima (em qualquer modo) |
| **Ctrl+S** | grava o notebook |

Uma **célula Markdown** é texto: títulos com `#`, `**negrito**`, listas e fórmulas entre cifrões.
Rode-a e ela é formatada. Um notebook só de células de código é um script com passos a mais; o
texto entre elas é o que deixa outra pessoa, ou você daqui a três meses, ler o raciocínio e não só
o resultado.

**Grave com Ctrl+S.** O JupyterLab também grava sozinho a cada dois minutos, mais ou menos, e a
próxima seção olha o que ele escreve.
