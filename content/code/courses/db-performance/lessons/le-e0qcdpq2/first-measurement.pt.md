---
title: Uma medida em que dá para acreditar
version: 1
---

Todo conserto neste curso é julgado por um número, então o número tem de significar alguma coisa.
O `\timing` dá um por comando, e o erro que todo mundo comete com ele no começo é acreditar no
primeiro.

## O que o `\timing` mede

A linha `Time:` é medida pelo `psql`, do seu lado: do momento em que enviou o comando ao momento em
que a resposta inteira chegou. Então ela inclui o trabalho do servidor, a viagem pela conexão e o
tempo de receber as linhas. Na sua máquina virtual a viagem não é nada, porque o `psql` e o
servidor estão no mesmo computador. Entre uma aplicação num prédio e um banco em outro, a viagem é
uma parte grande de toda consulta curta — e é por isso que o número do próprio servidor para a
mesma consulta, que a aula 3 lê, é menor do que este.

## A mesma consulta, três vezes

Reinicie o servidor, peça ao sistema operacional que descarte o que guardou do disco, abra o
`psql` e rode uma consulta três vezes:

```
ana@vm:~$ sudo systemctl restart postgresql
ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
ana@vm:~$ psql market
market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
  count  
---------
 1666667
(1 row)

Time: 434.619 ms

market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
  count  
---------
 1666667
(1 row)

Time: 166.557 ms

market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
  count  
---------
 1666667
(1 row)

Time: 207.896 ms
```

**435, 167, 208 milissegundos.** Três execuções de uma consulta, e a mais lenta levou mais que o
dobro da mais rápida. Há duas coisas diferentes nesses números.

A primeira execução é lenta porque está **fria**. O reinício esvaziou a memória do próprio
PostgreSQL, e a linha do `drop_caches` esvaziou a do sistema operacional, então os 432 MB de
`order_lines` vieram do disco. Na segunda, os dois já tinham guardado uma cópia. Uma execução fria
é real — é o que recebe a primeira pessoa a perguntar depois de um reinício —, mas não é o que a
mesma consulta custa na milésima vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Quatro caixas da esquerda para a direita: o disco, com o banco inteiro de 1334 MB; o cache do sistema operacional, que usa a memória que estiver livre; os shared buffers do PostgreSQL, 128 MB; e a consulta. Uma página viaja da esquerda para a direita. A execução fria, de 435 milissegundos, leu do disco; as quentes, de 167 e 208, acharam as páginas na memória.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Três lugares onde uma página pode estar, o mais lento à esquerda</text><rect x=\"14\" y=\"44\" width=\"170\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"99.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">o disco</text><text x=\"99.0\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1334 MB</text><text x=\"99.0\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o banco inteiro</text><rect x=\"214\" y=\"44\" width=\"200\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"314.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">cache do sistema operacional</text><text x=\"314.0\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">14 GB disponíveis neste computador</text><rect x=\"444\" y=\"44\" width=\"150\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"519.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">shared buffers</text><text x=\"519.0\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">128 MB</text><text x=\"519.0\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">do próprio PostgreSQL</text><rect x=\"624\" y=\"44\" width=\"82\" height=\"104\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"665.0\" y=\"64\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">a consulta</text><path d=\"M184 96 L214 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M214.0 96.0 L208.0 100.0 L208.0 92.0 Z\" fill=\"var(--wire)\"></path><path d=\"M414 96 L444 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M444.0 96.0 L438.0 100.0 L438.0 92.0 Z\" fill=\"var(--wire)\"></path><path d=\"M594 96 L624 96\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M624.0 96.0 L618.0 100.0 L618.0 92.0 Z\" fill=\"var(--wire)\"></path><path d=\"M99 156 L99 176 L659 176 L659 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"110\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">execução fria: do disco, 435 ms</text><path d=\"M314 156 L314 166 L659 166\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"325\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">execuções quentes: já na memória, 167 e 208 ms</text></svg>", "caption": "De onde vem uma página de uma tabela. A execução fria foi até o disco; as quentes pararam na memória.", "same": ["shared buffers"]}
```

A segunda e a terceira diferem em 41 milissegundos, embora as duas estejam quentes. Isso é
**ruído**: outros processos, os caches do próprio processador, o tempo de alguns workers
paralelos. Ele nunca some, e é por isso que uma execução não prova nada sobre uma mudança. Uma
consulta que "foi de 208 para 167 milissegundos" depois de um conserto pode não ter mudado nada.

## A regra para o resto do curso

- **Diga se está medindo frio ou quente**, e compare igual com igual. Um "depois" quente contra
  um "antes" frio é um conserto que não fez nada e parece uma melhora de 60%.
- **Rode várias vezes e fique com a do meio**, a mediana, que uma execução lenta sozinha não
  consegue arrastar como arrasta uma média.
- **Uma diferença menor que o ruído não é diferença.** A aula 24 transforma essa frase em conta.

## A máquina em que você está medindo

Os números das transcrições são deste computador:

```
ana@vm:~$ nproc
4
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       824Mi        11Gi       154Mi       4.2Gi        14Gi
Swap:             0B          0B          0B
```

Quatro processadores e 15 GB de memória, contra os dois e quatro da máquina virtual recomendada.
Desses 15, o próprio PostgreSQL só usa uma fatia fixa para o seu cache de páginas de tabela:

```
market=# SHOW shared_buffers;
 shared_buffers 
----------------
 128MB
(1 row)

Time: 0.598 ms
```

**128 MB**, que é o padrão do Ubuntu e foi escolhido para funcionar em qualquer computador, não
para ser rápido no seu. A aula 6 do `db-administration` é a conta para dimensioná-lo. Este curso o
deixa quieto quase sempre, de propósito: o banco é dez vezes maior que esse cache, então a
diferença entre memória e disco continua visível, e um tempo na sua máquina e um numa transcrição
diferem por motivos que você sabe nomear.

Seus tempos não vão bater com estes. O que deve bater é o **formato** — qual consulta é mais
rápida, por mais ou menos quantas vezes, e qual execução foi fria. Quando o formato discorda,
procure o que você fez de diferente antes de culpar a máquina.
