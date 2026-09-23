---
title: A pasta com que todo mundo começa
version: 1
---

Todo mundo tem controle de versão antes de ouvir o nome. É uma pasta, e ela se parece com isto:

```
ana@vm:~/report$ ls -l
total 20
-rw-r--r-- 1 ana ana 109 Sep  9 08:47 report-FINAL.txt
-rw-r--r-- 1 ana ana 115 Sep  8 15:22 report-v2-final-bruno.txt
-rw-r--r-- 1 ana ana 109 Sep  8 11:05 report-v2-final.txt
-rw-r--r-- 1 ana ana  93 Sep  3 17:40 report-v2.txt
-rw-r--r-- 1 ana ana  93 Sep  1 09:12 report.txt
```

Cinco cópias de um relatório, escritas ao longo de nove dias por duas pessoas. Ninguém planejou
isso. A Ana guardou uma cópia antes de uma edição arriscada, depois outra antes de mandar para o
Bruno, depois o Bruno devolveu uma com o nome dele, e então alguém decidiu que aquela era a final.

**A imagem comum é que controle de versão é essa pasta, só que arrumada** — cópias com nomes
melhores, guardadas num lugar seguro. Não é, e a pasta é o melhor jeito de ver por quê. Cópias
guardam as versões antigas. O que elas perdem é tudo *sobre* as versões, e essa acaba sendo a parte
de que uma equipe precisa.

## O que a pasta não sabe dizer

Tente responder a cinco perguntas a partir dessa listagem.

**Qual é a atual?** `report-FINAL.txt` é a mais nova, então provavelmente essa. Mas a cópia do
Bruno é do dia anterior e tem mudanças próprias. A FINAL é a versão que inclui essas mudanças?

**O que mudou?** Dá para descobrir, se você tem as duas cópias e sabe quais duas comparar:

```
ana@vm:~/report$ diff report-v2-final.txt report-FINAL.txt
2c2
< Sales rose 6% against the last quarter.
---
> Sales rose 5% against the last quarter.
```

**Por que mudou?** Alguém transformou 6% em 5%. O 6% era um erro de digitação, ou o financeiro
mandou um número novo, ou a FINAL é a cópia errada? O arquivo não diz, e daqui a um mês ninguém vai
lembrar.

**Quem mudou?** A coluna de dono diz `ana` nas cinco, porque todas estão na máquina da Ana. O nome
do Bruno está em uma delas só porque ele o digitou no nome do arquivo.

**O que mudou junto?** Um relatório é um arquivo. Um site são quarenta, e uma mudança numa página
muitas vezes é também uma mudança na folha de estilo e no menu. Copiar um arquivo guarda um arquivo.
Não guarda **o estado do projeto inteiro num momento**, que é o que você precisa quando quer voltar
para "a versão que funcionava na terça".

## Duas pessoas pioram tudo

Compare a cópia do Bruno com a que ele usou de ponto de partida:

```
ana@vm:~/report$ diff report-v2-final.txt report-v2-final-bruno.txt
3c3
< The north region missed its target.
---
> The north region missed its target by 2%.
```

Agora olhe os dois diffs juntos. A FINAL mudou a linha 2 e o Bruno mudou a linha 3. **Nenhuma das
cópias tem as duas mudanças.** Quem mandar a FINAL para a diretoria vai mandá-la sem o número do
Bruno, e nada na pasta avisa. Cada nome naquela listagem foi escolhido por alguém que achava que
estava claro.

É para esse problema que o controle de versão existe. Um backup responde *"consigo pegar a antiga
de volta?"* Controle de versão responde às cinco perguntas acima, para todos os arquivos de uma vez,
e sabe perceber quando duas pessoas mudaram a mesma coisa ao mesmo tempo. A próxima seção é o que
ele guarda para conseguir isso.
