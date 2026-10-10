---
title: O que um ambiente guarda, num projeto de dados
version: 1
---

**A resposta de um notebook depende de quatro coisas, e só uma delas está no notebook.** O código
está no `.ipynb`. Os dados estão na pasta, e a aula 2 disse como mantê-los honestos. O Python é o
que o `language_info` registra. A quarta são as bibliotecas, e um notebook não registra nada sobre
elas: abra-o com o pandas 2 em vez do pandas 3 e ele roda, e algumas respostas mudam.

O curso `python` montou ambientes virtuais para projetos comuns, nas aulas 18 e 19: `venv`,
`pip`, `requirements.txt`, e depois `uv` e `pyproject.toml`. Isso é suposto aqui. Esta aula é
sobre o que muda quando o projeto é uma análise e não um programa:

- **As bibliotecas são grandes e compiladas.** NumPy e pandas são quase todo C, distribuídos como
  wheels feitas para um sistema operacional e um processador; `pydata/.venv` tem 635 MB depois de
  um `pip install`. Reconstruir um ambiente é barato em comandos e não é de graça em disco nem em
  tempo.
- **Elas mudam de comportamento entre versões, em silêncio.** Um framework web que muda a API faz o
  seu programa falhar. O pandas mudar um padrão faz o seu notebook imprimir outro número, o que é
  pior, e a aula 11 e a aula 12 têm um exemplo cada.
- **Quem roda depois muitas vezes é você, meses mais tarde**, em outro computador, querendo o
  mesmo gráfico para o trimestre seguinte. O ambiente precisa ser reconstruído a partir de algo
  escrito, porque o que você tem não vai durar intacto tanto tempo.
- **Algumas ferramentas fora do Python fazem parte da pilha.** Um driver de banco de dados, uma
  biblioteca geográfica, um kit de GPU: nenhum é uma wheel que o `pip` instala em qualquer lugar,
  e é essa lacuna que o conda preenche, quatro seções adiante.

Então um projeto de dados carrega, ao lado dos notebooks, **um arquivo que diz quais bibliotecas em
quais versões**, e a disciplina de reconstruir o ambiente a partir desse arquivo e não da memória.
O resto desta aula escreve esse arquivo, prova que ele reconstrói, roda dois ambientes lado a lado
num JupyterLab, e depois faz o mesmo com o conda.
