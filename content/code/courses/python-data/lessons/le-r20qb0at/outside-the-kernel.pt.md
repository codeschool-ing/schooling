---
title: Estado fora do kernel, em módulos e arquivos
version: 1
---

**Reiniciar o kernel limpa a memória dele e mais nada.** Dois tipos de estado vivem fora dele e
sobrevivem a um reinício, e os dois fazem um notebook responder diferente de um dia para o outro
sem nenhuma célula mudar.

## Um módulo que você edita

Cedo ou tarde uma função merece um arquivo só dela, para que dois notebooks a compartilhem. Uma
célula pode escrever esse arquivo: a mágica `%%writefile` grava o resto da célula com o nome dado,
em vez de rodá-lo.

```python
%%writefile bikes.py
def label(minutes):
    return "short" if minutes < 15 else "long"
```

```
Writing bikes.py
```

```python
import bikes
bikes.label(20)
```
```
'long'
```

Agora mude de ideia sobre o limite e grave o arquivo de novo, como você faria no editor do
JupyterLab:

```python
%%writefile bikes.py
def label(minutes):
    return "short" if minutes < 30 else "long"
```

```
Overwriting bikes.py
```

```python
import bikes
bikes.label(20)
```
```
'long'
```

**Continua `long`**, com o arquivo agora dizendo 30. O Python importa um módulo uma vez por
processo e o guarda; um segundo `import` o encontra já carregado e não faz nada. O kernel está
rodando a versão de `bikes.py` que leu da primeira vez, e a página não dá sinal disso. Peça uma
leitura nova:

```python
import importlib
importlib.reload(bikes)
bikes.label(20)
```

```
'long'
```

`importlib.reload` lê o arquivo de novo. Reiniciar o kernel faz o mesmo para todos os módulos de
uma vez. O IPython também tem uma extensão que recarrega módulos editados antes de cada célula,
ligada com duas linhas, `%load_ext autoreload` e `%autoreload 2`; ela é cômoda enquanto um módulo
muda a cada poucos minutos, e é também mais uma coisa que difere entre a sua sessão e a execução do
notebook por outra pessoa.

## Um arquivo que muda por baixo

O notebook lê `weather.csv` da pasta, e a pasta não faz parte do notebook. Se o arquivo muda, as
mesmas células dão respostas diferentes, e nada no `.ipynb` diz que arquivo ele leu. Dois hábitos
cobrem quase tudo:

- **Leia os dados nas primeiras células, com o caminho escrito ali**, para que aquilo de que o
  notebook depende esteja na primeira tela e em nenhum outro lugar.
- **Nunca sobrescreva a sua entrada.** Um arquivo limpo ganha um nome novo. Um notebook que lê
  `trips.csv` e escreve `trips.csv` dá outra resposta na segunda vez que roda, porque a segunda
  execução lê a saída da primeira.

A aula 3 acrescenta a terceira peça fora do kernel, as próprias bibliotecas, e como anotar as
versões delas ao lado do notebook.
