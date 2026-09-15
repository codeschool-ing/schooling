---
title: Swap, que não é o problema e não é o conserto
version: 1
---

```
ana@vm:~$ swapon --show; echo "(nothing above means no swap)"
(nothing above means no swap)
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       657Mi        13Gi        11Mi       1.5Gi        15Gi
Swap:             0B          0B          0B
```

**Esta máquina não tem swap nenhum**, o que é comum em instâncias de nuvem e
quase universal em contêineres. Isso quer dizer que as capturas desta seção param
aqui: não há forma honesta de mostrar o `si`/`so` se mexendo numa máquina sem
para onde fazer swap, então o resto desta seção descreve em vez de demonstrar, e
diz isso.

## Para que serve o swap

O swap é disco usado como transbordo de memória. O kernel escreve nele páginas
que não são tocadas há muito tempo, liberando a página física para outra coisa.

**O propósito não é "mais memória".** Disco é milhares de vezes mais lento que
memória; uma máquina genuinamente sem memória e fazendo swap para compensar não
está lenta, está parada. O propósito é tirar páginas *frias* do caminho — o
código de inicialização de um daemon que rodou uma vez no boot, uma biblioteca
que ninguém chamou desde então — para que a memória física guarde o que está em
uso.

Que é por que uma máquina com swap em uso não está necessariamente em apuros:

| | |
|---|---|
| `Swap used: 400 MB`, `si`/`so` zerados | 400 MB de páginas frias estacionadas. **Saudável** |
| `Swap used: 400 MB`, `si`/`so` agitados | páginas entrando e saindo o tempo todo. **Thrashing** |

**O `swapon --show` te diz quanto está estacionado; o `si` e o `so` do `vmstat`
te dizem se algo está se movendo.** O segundo é a medição, e o primeiro é aquele
em que as pessoas dão alarme.

## As colunas

```
 r  b   swpd   free   buff  cache   si   so    bi    bo
```

| | |
|---|---|
| `swpd` | quanto está em swap agora — a figura estacionada |
| `si` | páginas trazidas de volta por segundo — um programa tocou algo estacionado |
| `so` | páginas mandadas para o swap por segundo — o kernel abrindo espaço |

`si` **e** `so` sustentados e diferentes de zero juntos é thrashing: a máquina
está gastando o tempo movendo páginas em vez de rodar código, e o sintoma é que
tudo está lento e nenhum processo isolado parece culpado.

Nesta máquina aquelas colunas são zero em toda captura desta aula, pelo motivo do
começo.

## O `swappiness`

```sh
cat /proc/sys/vm/swappiness         # 60 on most distributions
sysctl -w vm.swappiness=10          # until reboot
```

É um número de 0 a 100 que inclina o kernel entre recuperar cache de páginas e
mandar páginas anônimas para o swap. Mais alto faz swap mais prontamente.

**Não é uma porcentagem de memória e não é um limiar.** Definir 0 não desliga o
swap; faz o kernel evitá-lo até quase não ter opção, o que em alguns kernels quer
dizer que o matador de OOM chega mais cedo do que chegaria.

O padrão de 60 serve para quase tudo. Fabricantes de banco de dados recomendam 1
ou 10 porque um buffer pool em swap é um desastre; isso é uma recomendação
específica para uma carga específica, não conselho geral.

## Sem swap nenhum

Contêineres, a maioria dos nós Kubernetes, e muitas instâncias de nuvem rodam sem
nada, que é o que esta máquina faz. A troca é explícita:

**Com swap**, uma máquina sob pressão de memória fica lenta, e continua viva o
bastante para você notar e agir.

**Sem swap**, uma máquina sob pressão de memória é morta — o matador de OOM
escolhe um processo e o encerra, imediatamente, que é a próxima seção. Não há
degradação gradual nem aviso.

Nenhum dos dois é errado. **O errado é não saber qual você tem**, e o
`swapon --show` responde isso num comando.

## O que de fato fazer sobre swap

| | |
|---|---|
| swap em uso, `si`/`so` quietos | nada. É o recurso funcionando |
| `si`/`so` sustentados | ache o processo usando a memória. É problema de memória, não de swap |
| sem swap, e processos morrendo | a próxima seção |

**Acrescentar swap não conserta falta de memória**, converte-a de queda em
lentidão. Às vezes é exatamente a troca que você quer; continua sendo uma troca.
