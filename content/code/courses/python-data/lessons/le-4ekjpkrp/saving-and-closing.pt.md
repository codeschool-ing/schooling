---
title: Salvar, e fechar o que você abriu
version: 1
---

**`fig.savefig(caminho)` grava a figura num arquivo, e a extensão do arquivo escolhe o formato.** Um
PNG é feito de pixels, na resolução que você pedir; um SVG ou um PDF é feito de formas, nítido em
qualquer tamanho. Qual mandar depende de para onde o gráfico vai.

A figura das horas da última seção, dos dois jeitos:

```python
fig.savefig("hours.png", dpi=200)
fig.savefig("hours.svg")
import os
os.path.getsize("hours.png"), os.path.getsize("hours.svg")
```

```
(50485, 41284)
```

`dpi=200` dobra a resolução padrão, então o PNG tem 1.800 por 700 pixels: nítido num slide ou numa
página impressa. O SVG não tem resolução nenhuma; guarda cada barra como um retângulo e cada rótulo
como formas, e combina com uma página web ou um documento que vai ser redimensionado. O PNG serve para
tudo o que não abre SVG, o que inclui a maioria dos programas de conversa e alguns programas de slides.

## Um gráfico por estação

Um relatório muitas vezes precisa do mesmo gráfico para cada grupo, salvo num arquivo cada. Vinte
estações, mais um gráfico de todas elas antes, numa célula:

```python
by_hour = trips.groupby(["start_station", "hour"]).size().unstack("hour", fill_value=0)
fig, ax = plt.subplots()
ax.bar(by_hour.columns, by_hour.sum())
for code, row in by_hour.iterrows():
    fig, ax = plt.subplots()
    ax.bar(by_hour.columns, row)
    ax.set_title(code)
    fig.savefig(f"hours-{code}.png")
```

```
/tmp/ipykernel_11198/1596725314.py:5: RuntimeWarning: More than 20 figures have been opened. Figures created through the pyplot interface (`matplotlib.pyplot.figure`) are retained until explicitly closed and may consume too much memory. (To control this warning, see the rcParam `figure.max_open_warning`). Consider using `matplotlib.pyplot.close()`.
  fig, ax = plt.subplots()
```

Vinte e uma figuras foram criadas, e o matplotlib avisa na vigésima primeira. **O pyplot guarda toda
figura que criou até ela ser fechada**, e cada uma segura os seus dados e o seu desenho na memória. No
notebook a célula ainda mostra as vinte e uma embaixo dela quando termina, que é o segundo sinal de
que algo está errado. Num script que percorre mil grupos não há célula que termine, e a memória cresce
até o programa ser morto.

`plt.close(fig)` depois de salvar libera cada uma:

```python
for code, row in by_hour.iterrows():
    fig, ax = plt.subplots()
    ax.bar(by_hour.columns, row)
    ax.set_title(code)
    fig.savefig(f"hours-{code}.png")
    plt.close(fig)
len(plt.get_fignums())
```

```
0
```

Nenhum aviso, nada mostrado embaixo da célula, e nenhuma figura aberta, que o `plt.get_fignums()`
lista. **Uma figura criada num laço é salva e fechada no mesmo laço.**

## Como os gráficos desta aula são desenhados

Os gráficos destas páginas não são capturas de tela do matplotlib. São desenhados pelo curso nas cores
desta página, para virarem com os temas claro e escuro dela, **a partir dos mesmos números que as suas
células calculam**. Onde um gráfico daqui e o que aparece embaixo da sua célula diferem, a diferença é
de estilo: a fonte, o azul, o espaçamento das marcas. As barras têm o mesmo comprimento e as linhas
passam pelos mesmos pontos.
