---
title: O que é este curso, e como ele mostra o trabalho
version: 1
---

**Esta é a pilha científica por cima do Python, e não o Python de novo.** O curso `python` ensinou
a linguagem: tipos, funções, módulos e arquivos. Este supõe tudo isso e acrescenta as quatro
ferramentas que transformam a linguagem em algo com que se analisa dados — um notebook para
trabalhar, o **NumPy** para arrays, o **pandas** para tabelas e o **matplotlib** com o **seaborn**
para gráficos — e os hábitos que fazem o trabalho sobreviver a ser entregue para outra pessoa.

A ordem é esta:

| aulas | o quê |
|---|---|
| 1 a 3 | o notebook e o ambiente: onde o código roda, e por que um notebook mente quando é executado fora de ordem |
| 4 a 8 | NumPy: arrays, os laços que você deixa de escrever, broadcasting, máscaras e números aleatórios que se repetem |
| 9 a 12 | pandas: o DataFrame, a leitura de todo formato comum, a seleção, e tipos, datas e valores faltantes |
| 13 a 17 | remodelagem: agrupar, juntar, pivotar, janelas no tempo, e por que `apply` é o caminho lento |
| 18 e 19 | gráficos, das peças do matplotlib às linhas únicas do seaborn |
| 20 e 21 | memória e velocidade, e transformar um notebook num script que roda em outro computador |

O curso seguinte é `machine-learning`, e ele supõe tudo o que está aqui sem explicar de novo.
Estatística ajuda e não é exigida: os gráficos daqui são desenhados antes de serem interpretados.

## Como as saídas aparecem

Toda célula deste curso foi executada, e o que ela imprimiu está colado embaixo dela. O código é
um bloco colorido; o que ele imprimiu é o bloco simples logo depois:

```python
2 ** 10
```
```
1024
```

Quando a última linha de uma célula é uma tabela, o JupyterLab a desenha com bordas e sombreado. O
curso mostra a versão em texto simples da mesma tabela, que é o que o notebook guarda ao lado do
desenho e o que `print` mostraria; os números são os mesmos, e a seção sobre o arquivo do
notebook, mais adiante nesta aula, diz onde cada versão fica. As sessões de terminal começam com um
prompt, `(.venv) ana@lab:~/pydata$`, em que `ana` é a analista e `lab` a máquina em que foram
gravadas.

## As versões são fixadas, e isso importa mais do que de costume

O pandas e o NumPy mudaram coisas debaixo dos pés de quem os usa nos últimos anos. O NumPy 2 mudou
como os números são impressos e como dois tipos se combinam; o pandas 3 mudou o que acontece
quando você altera uma seleção, e fez do texto um tipo próprio. Código escrito para o comportamento
antigo continua rodando, muitas vezes com outra resposta. **A seção do laboratório fixa cada
biblioteca na versão de onde vieram estas saídas**, para que uma diferença entre a sua tela e esta
página queira dizer alguma coisa. Onde uma versão antiga se comportava de outro jeito, de um modo
que você vai encontrar no código dos outros, a aula diz: a aula 4 para o NumPy, as aulas 11 e 12
para o pandas.

## Os dados são as bicicletas de uma cidade

Toda aula a partir da 9 trabalha sobre os mesmos três arquivos: as estações, as viagens e o tempo
de um sistema de bicicletas compartilhadas no Recife. As aulas de NumPy também os usam, lidos como
arrays simples. Duas seções adiante você mesmo os cria, com um programa mostrado por inteiro.
