---
title: Quando a instalação falha
version: 1
---

Montar o ambiente é onde a maioria das pessoas desiste de um curso assim, e com Python e nenhuma biblioteca há só um punhado de jeitos de dar errado. Cada um tem uma mensagem que você reconhece. Os três primeiros abaixo foram provocados de propósito no computador em que estas aulas foram gravadas; os dois últimos não foram rodados aqui, porque precisam de um sistema que este não é, e estão descritos pelo que esses sistemas imprimem.

## "can't open file"

```
ana@laptop:~/delivery$ python3 biling.py
python3: can't open file '/home/ana/delivery/biling.py': [Errno 2] No such file or directory
```

**A mensagem diz o caminho em que o Python procurou**, e esse caminho é a pista: um erro de digitação no nome, como aqui, ou um terminal aberto em outra pasta. Um editor de texto no Windows também pode ter salvo o arquivo como `billing.py.txt` mostrando `billing.py`; ligar as extensões de arquivo no explorador mostra o nome real.

## "IndentationError"

```
ana@laptop:~/delivery$ python3 broken.py
  File "/home/ana/delivery/broken.py", line 61
    reviewed.append(name)
IndentationError: expected an indented block after 'if' statement on line 60
```

O Python usa os espaços no início de uma linha para saber que linhas andam juntas, então **uma colagem que os perde quebra o programa**. Esta cópia perdeu a indentação de uma linha, e o Python diz qual. Alguns editores e ferramentas de chat tiram ou convertem os espaços iniciais ao colar; copie com o botão do bloco, cole num editor de texto simples e, se o erro continuar, compare a linha que ele aponta com a da aula.

## Os arquivos foram para outro lugar

```
ana@laptop:~/delivery$ cd ..
ana@laptop:~$ python3 delivery/billing.py
123 items merged, 19 not yet, 47 deploys
ana@laptop:~$ ls -1 delivery
billing.py
ana@laptop:~$ ls -1 *.csv
deploys.csv
items.csv
```

O programa rodou e informou sucesso, e a pasta continua sem dados. **Um programa escreve os arquivos na pasta de onde você o roda**, não na pasta onde ele mora. Todo programa seguinte também lê o `items.csv` da pasta de onde é rodado, então a regra que faz tudo funcionar é a mais simples: abra o terminal em `delivery` e rode tudo de lá. Apague os dois arquivos perdidos e rode de novo no lugar certo.

## "python3: command not found", ou a Microsoft Store abre

Não rodado aqui. No Windows, digitar `python3` ou `python` num sistema novo pode abrir a Microsoft Store em vez de rodar qualquer coisa, porque o Windows vem com um atalho com esse nome que oferece instalar o Python. Se você instalou pelo `python.org`, digite `py`. No Linux e no macOS, `command not found` quer dizer que o Python 3 não está instalado, ou não está no caminho; a seção 04 desta aula diz como instalar.

## "SyntaxError: invalid syntax" numa linha com um f antes de uma string

Não rodado aqui. Linhas como `print(f"{len(days)} days")` precisam de Python 3.6 ou mais novo, e este curso pede 3.8. Um `SyntaxError` apontando para uma delas quer dizer que o comando rodou um Python velho, quase sempre o 2.7, guardado por alguns sistemas para as próprias ferramentas. O `python3 --version` diz qual você tem; use o que responder 3.8 ou mais.

## Quando não é nenhum destes

Leia a **última linha** do erro primeiro. O Python imprime a cadeia de chamadas que levou ao problema, e a linha que o nomeia está embaixo. Procure exatamente essa linha, e quase sempre você acha alguém que passou por isso antes. Se o seu programa roda mas imprime números diferentes dos da aula, a cópia difere da página em algum ponto: copie de novo, inteiro, em vez de caçar a diferença no olho.
