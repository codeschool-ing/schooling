---
title: Um primeiro olhar, e as duas metades de um programa
version: 1
---

**Um programa pequeno mostra a divisão que esta aula vem descrevendo melhor do que qualquer tabela.**
Aqui está o tipo de pergunta de Marta no seu menor tamanho: quantas viagens saíram de cada estação numa
manhã de domingo. O dado são seis viagens, coladas dentro do programa como o aplicativo poderia
exportá-las, então não há nada para baixar. Salve em `~/roda` como `first.py`.

```schooling-example
{"language": "python", "file": "first.py", "parts": [
{"code": "# first.py\nimport csv\nimport io\n\nEXPORT = \"\"\"ride_id,bike_id,start_station,started_at,minutes\nR000001,B017,ST02,2025-09-14 07:52,12\nR000002,B044,ST05,2025-09-14 08:03,25\nR000003,B017,ST06,2025-09-14 08:31,9\nR000004,B081,ST02,2025-09-14 09:10,31\nR000005,B032,ST02,2025-09-14 10:47,7\nR000006,B044,ST08,2025-09-14 11:20,44\n\"\"\"\n", "note": "A exportação, como texto. Uma de verdade chega como arquivo toda manhã; aqui são seis linhas dentro do programa, para o programa ser o laboratório inteiro. A primeira linha dá nome às colunas."},
{"code": "\nrides = list(csv.DictReader(io.StringIO(EXPORT)))\n", "note": "`csv.DictReader` transforma cada linha num dicionário cujas chaves são os nomes das colunas. `io.StringIO` deixa que ele leia um texto como se fosse um arquivo."},
{"code": "per_station = {}\nfor ride in rides:\n    station = ride[\"start_station\"]\n    per_station[station] = per_station.get(station, 0) + 1\n", "note": "A pergunta em si: um contador por estação. É nesta linha que o programa depende de a exportação chamar a coluna de `start_station`."},
{"code": "\nprint(len(rides), \"rides on 14 September\")\nfor station, n in sorted(per_station.items()):\n    print(station, n)\n", "note": "A resposta, uma estação por linha, em ordem."}
]}
```

Rode:

```
ana@lab:~/roda$ python first.py
6 rides on 14 September
ST02 3
ST05 1
ST06 1
ST08 1
```

Três das seis viagens saíram da Rua XV. Essa é a metade do analista no programa: uma definição (uma
viagem conta na estação de onde saiu) e uma contagem.

## A metade do engenheiro é tudo o que vem antes de `rides =`

O programa confia em quatro coisas que nunca confere: que a exportação existe, que as colunas se chamam
como se chamavam ontem, que cada viagem está nela uma vez, e que ela é a exportação do dia certo. Cada uma
dessas é trabalho de alguém, e na Roda Livre é de Davi.

Quebre a segunda. O time do aplicativo renomeia uma coluna, e a exportação da manhã seguinte diz `start`
onde dizia `start_station`. O comando abaixo faz essa versão do arquivo e a roda:

```
ana@lab:~/roda$ sed "s/,start_station,started_at/,start,started_at/" first.py > renamed.py
ana@lab:~/roda$ python renamed.py
Traceback (most recent call last):
  File "/home/ana/roda/renamed.py", line 17, in <module>
    station = ride["start_station"]
              ~~~~^^^^^^^^^^^^^^^^^
KeyError: 'start_station'
```

Essa falha é barulhenta, e **barulhenta é o tipo bom**. O programa para, diz o nome da coluna que
procurou, e ninguém recebe um número errado.

Agora quebre a terceira. Uma exportação repetida escreve a viagem `R000002` duas vezes:

```
ana@lab:~/roda$ sed "/^R000002/p" first.py > twice.py
ana@lab:~/roda$ python twice.py
7 rides on 14 September
ST02 3
ST05 2
ST06 1
ST08 1
```

Sete viagens numa manhã que teve seis, e a Rodoferroviária contada duas vezes. Nada parou, nada
reclamou, e a saída parece tão confiável quanto a primeira. **Essa é a falha que um engenheiro de dados
é pago para impedir**, porque ninguém mais adiante consegue vê-la. A aula 3 constrói um pipeline que pode
rodar duas vezes sem contar duas vezes; a aula 7 confere uma entrega antes de confiar nela.

Guarde o `first.py`: ele é a menor versão de todo pipeline do curso, uma entrada, uma definição e uma
saída, e é útil ter um programa que você entende por completo ao lado dos que são maiores.
