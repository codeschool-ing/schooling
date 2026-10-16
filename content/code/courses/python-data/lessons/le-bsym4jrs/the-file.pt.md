---
title: O que um notebook é em disco
version: 1
---

**Um arquivo `.ipynb` é JSON: uma lista de células, cada uma com o seu código e as saídas que
produziu da última vez que rodou.** Não é um script, nem uma foto da página. Saber o que tem dentro
explica três coisas que, sem isso, parecem manias: por que dá para mandar um notebook a alguém que
nunca o roda, por que ele é incômodo no controle de versão, e por que ele pode carregar dados que
você não queria compartilhar.

Aqui está o notebook da seção anterior, com as cinco células rodadas uma vez cada, de cima para
baixo:

```
(.venv) ana@lab:~/pydata$ ls -l first.ipynb
-rw-r--r-- 1 ana ana 2503 Oct 10 04:05 first.ipynb
(.venv) ana@lab:~/pydata$ head -n 24 first.ipynb
{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "ed1348ee",
   "metadata": {},
   "outputs": [
    {
     "data": {
      "text/plain": [
       "2"
      ]
     },
     "execution_count": 1,
     "metadata": {},
     "output_type": "execute_result"
    }
   ],
   "source": [
    "1 + 1"
   ]
  },
  {
```

Cada célula é um objeto com as mesmas chaves, em ordem alfabética:

| chave | guarda |
|---|---|
| `cell_type` | `code` ou `markdown` |
| `execution_count` | o número entre colchetes na página, ou `null` se nunca rodou |
| `id` | um identificador aleatório que o JupyterLab dá a cada célula, então os seus são outros |
| `outputs` | o que a célula produziu, **gravado junto com o notebook** |
| `source` | o que você digitou, uma string por linha |

As saídas são a parte interessante. A quarta célula imprimiu uma linha e depois mostrou um valor, e
o arquivo guarda os dois, como duas saídas de dois tipos diferentes:

```
(.venv) ana@lab:~/pydata$ sed -n 69,98p first.ipynb
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "e9bc48ca",
   "metadata": {},
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "2025-01-01,0.0,29.9\n",
      "\n"
     ]
    },
    {
     "data": {
      "text/plain": [
       "'2025-01-01,0.0,29.9\\n'"
      ]
     },
     "execution_count": 4,
     "metadata": {},
     "output_type": "execute_result"
    }
   ],
   "source": [
    "print(lines[1])\n",
    "lines[1]"
   ]
  },
```

O `stream` é o que o `print` escreveu, com a quebra de linha. O `execute_result` é o valor da
última linha, guardado em `text/plain` como sua representação. Um DataFrame guarda uma segunda
versão de si em `text/html`, que é a tabela que o JupyterLab desenha, e um gráfico guarda a própria
imagem, como uma longa string de texto que se decodifica num PNG. **Este curso mostra a versão
`text/plain` de cada saída**, que é o mesmo texto que o `print` daria; na sua tela os números são
os mesmos e a tabela vem desenhada com linhas.

No fim do arquivo ficam os metadados do próprio notebook:

```
(.venv) ana@lab:~/pydata$ tail -n 22 first.ipynb
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
```

`kernelspec` diz qual kernel o notebook pede ao abrir, e `language_info` registra o Python que o
rodou por último, `3.12.3` aqui. Nada no arquivo registra **quais bibliotecas** estavam instaladas,
e é isso que a aula 3 acrescenta ao lado dele.

## O que decorre disso

**O arquivo pode ser lido sem ser executado.** Mande `first.ipynb` a alguém e essa pessoa vê os
seus resultados, inclusive qualquer número que os seus dados produziram, sem rodar uma linha. É a
grande força do notebook como documento, e também o seu risco: uma saída que imprimiu o e-mail de
um cliente, ou um token de acesso, fica gravada no arquivo e viaja com ele. **Limpe as saídas antes
de compartilhar um notebook que tocou em algo privado**: Edit, Clear Outputs of All Cells, e grave.

**O arquivo registra o que aconteceu, e não se aconteceria de novo.** Cada saída é do momento em
que sua célula rodou, e os contadores de execução dizem em que ordem foi. Um notebook gravado com
contadores `1, 2, 3, 4, 5` foi rodado de cima para baixo uma vez; um gravado com `7, 3, 12` não
foi, e a aula 2 é sobre o que isso pode esconder.

**O controle de versão enxerga JSON.** Rode uma célula de novo e o seu `execution_count` muda, e
talvez a saída também; um gráfico redesenhado é uma string nova de milhares de caracteres. Um diff
de dois notebooks é quase todo ruído em volta da única linha que mudou, e isso é parte do motivo de
a aula 21 levar o trabalho que precisa durar para um script.

**A memória do kernel não está no arquivo.** Variáveis, módulos importados e arquivos abertos
vivem no processo do kernel e somem quando ele para. Abra `first.ipynb` amanhã e as saídas estão
lá, mas `lines` não existe até a célula que a cria rodar de novo.
