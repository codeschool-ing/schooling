---
title: Quando a instalação falha
version: 1
---

O começo é onde a maioria desiste de um curso como este, quase sempre por causa de uma linha de saída
que parecia um desastre e era uma coisa pequena. Estas são as falhas que aparecem seguindo as duas
últimas seções e os primeiros programas desta lição, cada uma com o que imprime e o que resolve. As
que têm transcrição foram produzidas de propósito, na máquina de onde vêm as transcrições.

## `python: command not found`

```
ana@laptop:~/patterns/oo$ python check.py
bash: line 1: python: command not found
```

O Ubuntu instala o Python como `python3` e não tem um `python` simples a menos que você acrescente um
pacote para isso. Um terminal interativo escreve a mensagem de outro jeito e pode sugerir um pacote
para instalar; a causa é a mesma. **Digite `python3`.** No Windows é o contrário: `py` ou `python`
funcionam e `python3` pode não funcionar. No Windows, um `python` que abre a Microsoft Store em vez
de rodar é um *alias de execução de aplicativo*, um atalho que o Windows traz antes de qualquer Python
estar instalado; instalar pelo python.org com *Add python.exe to PATH* marcado o substitui. Esse
caso não foi rodado para este curso.

## `can't open file`

```
ana@laptop:~$ python3 check.py
python3: can't open file '/home/ana/check.py': [Errno 2] No such file or directory
```

O caminho na mensagem entrega tudo: o Python procurou `check.py` no diretório pessoal, porque era lá
que o terminal estava. **Faça `cd ~/patterns/oo` antes**, ou passe o caminho,
`python3 ~/patterns/oo/check.py`. O comando `pwd` imprime em que diretório um terminal está.

## Um arquivo que perdeu a indentação

O Python lê a indentação como estrutura, então uma linha colada com o número errado de espaços para o
programa antes de ele rodar. Aqui uma linha do `loan.py`, da seção de encapsulamento, veio com dois
espaços onde deviam ser oito:

```
ana@laptop:~/patterns/oo$ python3 loan.py
due: 2026-03-16
fine on 20 March: 200
fine after return: 100
refused: 'Dom Casmurro' was already returned
```

**A última linha é a causa e a linha acima dela é o lugar**: linha 22. Abra o arquivo ali e faça a
indentação bater com a das linhas em volta. Se o editor misturou tabs e espaços, um editor que mostra
espaços em branco deixa isso visível; configure-o para inserir quatro espaços no lugar de um tab.

## `No module named`

O `member.py`, da seção de composição, importa o `notices.py`. Rode-o num diretório onde o
`notices.py` não está, e:

```
ana@laptop:~/patterns/oo$ python3 member.py
e-mail to bia@example.org, subject "Library": Bia, your reservation is ready
SMS to +55 11 5550-0142: Bia, your reservation is ready
```

O Python procura um módulo importado primeiro no diretório do programa que está rodando. **Salve o
arquivo importado ao lado do que o importa**; dentro de uma lição, todo programa vai no mesmo
diretório, e a lição diz quando um arquivo usa outro.

## Um Python velho demais

O `check.py` imprime *This course needs Python 3.12 or newer* e para. Isso não foi rodado, porque a
máquina de onde vêm as transcrições tem o 3.12. Instale um Python mais novo por um dos caminhos da
seção do laboratório; no Linux, `uv python install 3.12` põe um no seu diretório pessoal sem tocar
no do sistema, e `uv run --python 3.12 check.py` roda um programa com ele.

## Quando não é nenhuma dessas

Leia primeiro a última linha da saída: o Python põe ali o tipo de erro e a mensagem, e as linhas de
cima são o caminho que ele fez até chegar lá. Pesquise essa última linha, entre aspas, com a palavra
Python. Depois compare o seu arquivo com o da lição, caractere por caractere, a partir da linha que o
erro aponta; um dois-pontos ou um parêntese faltando é acusado mais vezes na linha *seguinte* do que
na própria.
