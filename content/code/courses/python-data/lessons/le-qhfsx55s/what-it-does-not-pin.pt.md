---
title: O que um arquivo fixado ainda deixa em aberto
version: 1
---

**Um arquivo de lock fixa as bibliotecas; não fixa tudo de que um resultado depende.** Saber o que
fica em aberto é o que deixa você dizer, com honestidade, até onde um notebook se reproduz no
computador de outra pessoa.

**O Python.** O `requirements.txt` não diz nada sobre qual interpretador o lê. O NumPy 2.5 recusa
qualquer coisa anterior ao 3.12, como a falha da aula 1 mostrou, então as versões deste projeto
calham de impor um piso; as de outro projeto podem não impor, e um Python mais novo também pode
mudar um resultado. Escreva a versão onde uma pessoa vai ler: uma linha no `README` do projeto, ou
`requires-python` num `pyproject.toml`, que a aula 19 do curso `python` define. O
`environment.yml` faz melhor, porque `python=3.12` é uma das linhas dele e o conda instala esse
Python.

**O sistema operacional e o processador.** O NumPy num notebook Intel e num Apple roda código
compilado diferente por baixo, feito com bibliotecas de matemática diferentes. Este curso foi
gravado numa máquina, e não foi rodado em outra. Onde um resultado é uma soma longa de números de
ponto flutuante, outra máquina pode imprimir um último dígito diferente, porque pode somá-los em
outra ordem; a aula 5 mostra por que a ordem das somas importa para um float.

**Os dados.** As versões fixadas não dizem nada sobre o `trips.csv`. A regra da aula 2, nunca
sobrescreva a sua entrada, e o programa da aula 1 que o regenera são o que cobre isso.

**A aleatoriedade.** Um embaralhamento, uma amostra ou uma divisão aleatória dá números novos a cada
execução se não tiver semente, quaisquer que sejam as versões. A aula 8 é sobre sementes.

**Os próprios pacotes, byte a byte.** `numpy==2.5.3` nomeia uma versão; não prova que o arquivo que
o pip baixa é o que você testou. `pip install --require-hashes`, com um hash ao lado de cada linha,
prova, e ferramentas como o `uv` escrevem esses hashes para você. Para uma análise no seu próprio
computador, é mais do que você precisa. Para um pipeline que roda sozinho num servidor, é a
diferença entre um número de versão e uma garantia.

| em aberto | o que fecha |
|---|---|
| o Python | uma versão escrita: `README`, `requires-python`, ou `python=` no `environment.yml` |
| o sistema operacional | nada no arquivo; uma máquina virtual ou um contêiner, quando importa |
| os dados | um programa que os cria, ou uma cópia que nunca é sobrescrita |
| a aleatoriedade | uma semente, aula 8 |
| os bytes dos pacotes | hashes no arquivo de lock |
