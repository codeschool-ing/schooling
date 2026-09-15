---
title: Vazão de disco, e por que 100% ocupado não é veredito
version: 1
---

Espaço é uma pergunta; se o disco dá conta é outra, e a ferramenta é o `iostat`.

Aqui está esta máquina escrevendo cerca de um gigabyte por segundo:

```
ana@vm:~$ iostat -xz 2 2 | tail -6
           1.25    0.00    6.99   21.35    0.25   70.16

Device            r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
vda              0.00      0.00     0.00   0.00    0.00     0.00 1482.50 1028608.00     0.00   0.00    0.97   693.83    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    1.43  93.20
```

| | |
|---|---|
| `-x` | as colunas estendidas. Sem ele você recebe quatro, e nenhuma é o `await` |
| `-z` | omite dispositivos sem atividade. Numa máquina com doze discos é a diferença entre legível e não |
| `2 2` | duas amostras, com dois segundos. **A primeira é desde o boot** |

Este último ponto de novo, porque é a mesma armadilha do `vmstat`: **o primeiro
bloco que o `iostat` imprime é uma média desde o boot da máquina.** O `tail -6`
acima o está jogando fora.

## As colunas que importam

De umas vinte colunas, cinco:

| | |
|---|---|
| `r/s` `w/s` | **IOPS** — operações por segundo, lidas e escritas |
| `rkB/s` `wkB/s` | **vazão** — kilobytes por segundo |
| `r_await` `w_await` | **milissegundos que uma requisição esperou**, fila mais serviço |
| `aqu-sz` | profundidade média da fila |
| `%util` | porcentagem do tempo em que o dispositivo teve ao menos uma requisição em voo |

Lendo a captura acima: 1482 escritas por segundo, um gigabyte por segundo de
dados, profundidade de fila 1,43, **0,97 milissegundo de espera de escrita**, e
93% de utilização.

**Aquilo é um disco saudável trabalhando duro.** Um milissegundo de espera num
dispositivo fazendo um gigabyte por segundo não é nada; a fila mal passa de um;
ninguém está sofrendo.

## O `%util` parou de significar saturação

O `%util` é a fração do tempo em que ao menos uma requisição estava pendente. Num
disco mecânico de uma cabeça, isso era saturação: ocupado queria dizer ocupado.

**Em qualquer coisa com fila — todo SSD, todo NVMe, toda controladora RAID, todo
volume de nuvem — não é.** Um dispositivo que atende trinta e duas requisições de
uma vez mostra `%util 100` atendendo uma por vez, e mostra `%util 100` atendendo
trinta e duas. O número é o mesmo e a máquina está em estados completamente
diferentes.

Então o `%util 93` acima é um fato e não um diagnóstico. **O diagnóstico está no
`await`**:

| | |
|---|---|
| `await` abaixo de um milissegundo | NVMe ou um cache, funcionando |
| alguns milissegundos | um SSD, ou um disco mecânico sem fila |
| dezenas de milissegundos | um disco mecânico com fila, ou um volume de nuvem no limite |
| centenas | algo está muito errado, e as aplicações estão notando |

E leia o `aqu-sz` ao lado. Await subindo com a fila parada em um quer dizer que
cada requisição ficou mais lenta; await subindo porque a fila está quarenta fundo
quer dizer que você está pedindo mais do que o dispositivo dá.

## As duas colunas do `vmstat`

Nem sempre você precisa do `iostat`:

```
ana@vm:~$ vmstat 1 3
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 0  1      0 14476076  56304 1542856    0    0    69  5180  452    1  3  0 96  0  0  0
 0  1      0 14477244  56304 1542856    0    0     0 883716 3874 4433  6  5 67 22  0  0
 0  1      0 14485424  56304 1542856    0    0     0 980992 3815 4290  2  4 72 22  0  0
```

**`b 1` e `wa 22` com `r 0` é o diagnóstico inteiro em seis caracteres.** Nada
quer processador, uma coisa está bloqueada, e um quinto do tempo de processador
da máquina foi ocioso-por-causa-de-disco. O `bo` são 900 mil blocos por segundo
saindo.

Essa combinação — `wa` alto, `b` alto, `r` baixo — é a cara de um problema de I/O
visto do `vmstat`, e é por que o `vmstat 1` é o primeiro comando e o `iostat` é o
segundo.

## Leituras, escritas e flushes são diferentes

O `iostat -x` os separa por um motivo:

**Leituras** normalmente são síncronas: algo está esperando a resposta agora,
então o `r_await` mapeia direto na requisição de alguém estar lenta.

**Escritas** normalmente não são: o kernel as recebe no cache de páginas e retorna
na hora, e as escreve depois. O `w_await` mede a descarga, que ninguém está
esperando — até o cache encher, e aí todo mundo está.

**O `f/s` e o `f_await` são flushes** — o `fsync()`, que é um programa insistindo
que os dados estão mesmo no meio físico. Bancos de dados fazem isso o tempo todo,
e um `f_await` alto num volume de banco é o sinal mais direto de "este disco é
lento demais para esta carga" que existe.

## O penhasco da escrita

Os dois estados a conhecer:

| | |
|---|---|
| `Dirty` no `/proc/meminfo` pequeno e estável | a descarga está dando conta |
| `Dirty` grande e crescendo, `wa` subindo | não está, e o penhasco vem vindo |

Quando as páginas sujas chegam ao `vm.dirty_ratio` — 20% da memória por padrão —
o kernel para de ser generoso e faz o *processo que escreve* fazer a descarga ele
mesmo. A vazão não degrada suavemente; ela cai num degrau, e uma aplicação que
estava bem um segundo atrás agora bloqueia em toda escrita.

Uma máquina que fica bem por cinquenta segundos e terrível por dez, repetidamente,
normalmente é isso.

## Em ordem

```sh
vmstat 1                 # is wa high and b non-zero
iostat -xz 2             # which device, and what is await
pidstat -d 1             # which process — the next section
```
