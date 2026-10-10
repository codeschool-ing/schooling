---
title: Um notebook no controle de versão
version: 1
---

**Um notebook é uma boa coisa para guardar no git, desde que você saiba que o git vê o JSON e não a
página.** Ana põe o notebook corrigido no controle de versão, com o ambiente de fora:

```
(.venv) ana@lab:~/pydata$ git init -q
(.venv) ana@lab:~/pydata$ printf '.venv/\n' > .gitignore
(.venv) ana@lab:~/pydata$ git add .gitignore fixed.ipynb
(.venv) ana@lab:~/pydata$ git commit -qm "Wet days in 2025"
```

A linha do `.gitignore` importa: `.venv` são centenas de megabytes de bibliotecas instaladas que
os comandos da seção do laboratório reconstroem em minutos, e não tem lugar num histórico que
nunca esquece.

No dia seguinte ela abre o notebook, roda as três células, roda a última mais duas vezes para olhar
o número de novo, e grava. Não mudou código nenhum. Eis o que o git informa agora:

```
(.venv) ana@lab:~/pydata$ git diff --stat
 fixed.ipynb | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
(.venv) ana@lab:~/pydata$ git diff
diff --git a/fixed.ipynb b/fixed.ipynb
index 3c7af00..0b0d677 100644
--- a/fixed.ipynb
+++ b/fixed.ipynb
@@ -24,7 +24,7 @@
   },
   {
    "cell_type": "code",
-   "execution_count": 3,
+   "execution_count": 5,
    "id": "d83302b2",
    "metadata": {},
    "outputs": [
@@ -34,7 +34,7 @@
        "63"
       ]
      },
-     "execution_count": 3,
+     "execution_count": 5,
      "metadata": {},
      "output_type": "execute_result"
     }
```

Duas linhas mudaram e as duas são contadores de execução, `3` virando `5`. **Nada na análise
mudou, e o histórico tem uma mudança.** Multiplique isso por um notebook com vinte células, um ou
dois DataFrames e um gráfico, que é guardado como uma longa string de imagem codificada que muda a
cada execução, e o diff de um trabalho de verdade vira uma página de ruído com uma linha
significativa em algum lugar.

## Limpando as saídas antes de um commit

O remédio mais simples é fazer commit dos notebooks sem as saídas, para que o histórico guarde só o
que as pessoas escreveram:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --clear-output --inplace fixed.ipynb
[NbConvertApp] Converting notebook fixed.ipynb to notebook
[NbConvertApp] Writing 1077 bytes to fixed.ipynb
(.venv) ana@lab:~/pydata$ git diff --stat
 fixed.ipynb | 19 ++++---------------
 1 file changed, 4 insertions(+), 15 deletions(-)
```

`--clear-output` esvazia o `outputs` de cada célula e devolve o contador a `null`; o arquivo
encolhe, e o que sobra para comparar é o código. O custo é que quem abre o notebook a partir do
repositório vê código e nenhum resultado até rodá-lo, que é, depois desta aula, o que essa pessoa
deveria fazer de qualquer jeito. Um pacote à parte, `nbstripout`, faz o mesmo sozinho a cada
commit; ele não está instalado no laboratório deste curso, e o comando acima basta para ver o que
ele poupa.

Dois outros hábitos fazem os notebooks se comportarem num repositório:

- **Guarde o código que precisa durar em arquivos `.py`**, importados pelo notebook, como o
  `bikes.py` de duas seções atrás. Esses aparecem no diff como código, porque são código. A aula
  21 leva isso até o fim.
- **Reinicie e rode tudo antes de cada commit.** Um notebook no repositório é uma afirmação de que
  as saídas vieram do código dele, e os contadores de `1` a `n` são a prova.
