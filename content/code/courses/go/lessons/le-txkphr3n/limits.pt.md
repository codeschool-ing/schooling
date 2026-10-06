---
title: Um limite de memória, e memória que você não pretendia guardar
version: 1
---

Uma linguagem com coleta de lixo costuma ser vendida como uma que não vaza memória. **Ela não perde
memória, o que é outra coisa: o coletor libera o que nada alcança, e guarda tudo o que alguma coisa
alcança.** Um programa que ainda aponta para bytes que nunca mais vai ler fica com eles enquanto o
ponteiro viver. Esta seção trata dos dois jeitos de a memória de um programa surpreender quem o
opera: um heap que cresce até onde o `GOGC` deixa, tenha a máquina o que tiver, e uns poucos bytes
que mantêm muitos outros vivos.

## GOMEMLIMIT: um teto abaixo do qual o runtime mira

O `GOGC` marca a próxima coleta por uma proporção, e uma proporção não sabe nada da máquina. Com
2 GB vivos, `GOGC=100` deixa o heap chegar a 4 GB antes de coletar, tenha ou não o contêiner em que
ele roda 4 GB para dar. A segunda configuração responde a isso:

```
ana@vm:~/memory-gc$ go doc runtime | grep -A 11 "The GOMEMLIMIT variable"
The GOMEMLIMIT variable sets a soft memory limit for the runtime. This memory
limit includes the Go heap and all other memory managed by the runtime, and
excludes external memory sources such as mappings of the binary itself, memory
managed in other languages, and memory held by the operating system on behalf
of the Go program. GOMEMLIMIT is a numeric value in bytes with an optional unit
suffix. The supported suffixes include B, KiB, MiB, GiB, and TiB. These suffixes
represent quantities of bytes as defined by the IEC 80000-13 standard. That is,
they are based on powers of two: KiB means 2^10 bytes, MiB means 2^20 bytes,
and so on. The default setting is math.MaxInt64, which effectively disables the
memory limit. runtime/debug.SetMemoryLimit allows changing this limit at run
time.
```

**O limite conta toda a memória que o runtime administra, não só o heap, e ele é flexível.** À
medida que o total se aproxima dele, o runtime coleta com mais frequência, diga o `GOGC` o que
disser. As duas configurações trabalham juntas: `GOGC=off` com um limite quer dizer "não colete
nada até a memória chegar perto disto", o que serve a um programa sozinho num contêiner de tamanho
conhecido. O programa `~/memory-gc` da seção 03, com 64 MiB para usar:

```
ana@vm:~/memory-gc$ GOGC=off GOMEMLIMIT=64MiB ./gc
10 collections, 496 MB allocated, heap at most 63 MB
```

Dez coletas em vez de 61, e um heap que cresceu até encostar no limite e parou ali. Ele usou a
memória que estava disponível para poupar o tempo de 51 coletas.

A outra direção é a que você precisa entender antes de usar isso. O programa mantém 8 MB vivos, e
nenhuma configuração faz o coletor liberar um byte alcançável. Aqui está o mesmo binário com um
limite de 4 MiB, abaixo do que ele precisa, ao lado de uma execução sem limite nenhum:

```
ana@vm:~/memory-gc$ time ./gc
61 collections, 496 MB allocated, heap at most 19 MB

real	0m0.420s
user	0m0.421s
sys	0m0.033s
ana@vm:~/memory-gc$ time GOMEMLIMIT=4MiB ./gc
2927 collections, 496 MB allocated, heap at most 19 MB

real	0m1.739s
user	0m1.612s
sys	0m1.439s
```

O programa terminou, e é isso que flexível quer dizer: não há erro nem queda no limite. Ele rodou
2.927 coletas para ficar o mais perto que conseguia, e levou quatro vezes mais tempo. O
código-fonte do runtime, `mgclimit.go`, limita o coletor a mais ou menos metade do tempo de
processador nessa situação, então o programa se arrasta em vez de parar. **Um limite abaixo do que
o programa de fato mantém vivo custa tempo e não economiza nada.** O lugar dele é uma margem acima
do heap vivo, e o heap vivo é o último dos três números do `#->#->#` numa linha do `gctrace`.

O `runtime/debug` tem uma função para cada configuração, `SetGCPercent` e `SetMemoryLimit`, para o
programa que as decide sozinho; as variáveis de ambiente são o jeito de quem opera decidir de fora.

## Dezesseis bytes segurando sessenta e quatro megabytes

A seção 03 da lição 9 mostrou que uma substring compartilha os bytes da string de onde foi cortada,
e a lição 11, que uma slice é uma vista de um array. As duas coisas são o que torna cortar barato.
Elas também querem dizer que um pedaço pequeno mantém o todo vivo, porque o coletor vê um ponteiro
para dentro do array e guarda o array, inteiro. Nada no coletor olha quanto de um array uma slice
consegue ver.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"slices\"\n\t\"strings\"\n)\n"
    },
    {
      "code": "\n// heapMB collects, then reports what the heap still holds.\nfunc heapMB() uint64 {\n\truntime.GC()\n\tvar m runtime.MemStats\n\truntime.ReadMemStats(&m)\n\treturn m.HeapAlloc >> 20\n}\n",
      "note": "`runtime.GC` roda uma coleta inteira antes da medição, então `HeapAlloc`, os bytes ocupados por valores do heap, conta só o que ainda é alcançável."
    },
    {
      "code": "\n// load stands in for reading a 64 MB file into memory.\nfunc load() []byte {\n\treturn make([]byte, 64<<20)\n}\n\nvar header []byte\nvar name string\n",
      "note": "`64<<20` é 64 vezes 1.048.576. As duas variáveis de pacote são o que o programa guarda para depois: os primeiros bytes de um arquivo, e um nome lido dele."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Printf(\"at start              %2d MB\\n\", heapMB())\n",
      "note": "Quase nada no heap ainda."
    },
    {
      "code": "\n\theader = load()[:16]\n\tfmt.Printf(\"16 bytes kept         %2d MB\\n\", heapMB())\n",
      "note": "**A slice enxerga 16 bytes, e o array por trás dela tem 64 MB.** Nada mais aponta para o array, e o coletor o guarda mesmo assim, porque `header` aponta."
    },
    {
      "code": "\theader = slices.Clone(header)\n\tfmt.Printf(\"after slices.Clone    %2d MB\\n\", heapMB())\n",
      "note": "`slices.Clone` copia os 16 bytes para um array novo e pequeno. Quando `header` passa a apontar para lá, o array de 64 MB fica inalcançável e a coleta seguinte o libera."
    },
    {
      "code": "\n\tname = string(load())[:16]\n\tfmt.Printf(\"16-byte substring     %2d MB\\n\", heapMB())\n\tname = strings.Clone(name)\n\tfmt.Printf(\"after strings.Clone   %2d MB\\n\", heapMB())\n}\n",
      "note": "**Com uma string acontece a mesma coisa.** A substring de 16 bytes compartilha os bytes de uma string de 64 MB e os mantém vivos, até que `strings.Clone` lhe dê bytes próprios."
    }
  ],
  "output": "at start               0 MB\n16 bytes kept         64 MB\nafter slices.Clone     0 MB\n16-byte substring     64 MB\nafter strings.Clone    0 MB"
}
```

O programa está em `~/memory-keep`, e os números são os mesmos em toda execução, porque cada um é
medido logo depois de uma coleta completa. A biblioteca padrão documenta a correção onde você
procuraria:

```
ana@vm:~/memory-keep$ go doc strings.Clone
package strings // import "strings"

func Clone(s string) string
    Clone returns a fresh copy of s. It guarantees to make a copy of s into a
    new allocation, which can be important when retaining only a small substring
    of a much larger string. Using Clone can help such programs use less memory.
    Of course, since using Clone makes a copy, overuse of Clone can make
    programs use more memory. Clone should typically be used only rarely,
    and only when profiling indicates that it is needed. For strings of length
    zero the string "" will be returned and no allocation is made.

ana@vm:~/memory-keep$ go doc slices.Clone
package slices // import "slices"

func Clone[S ~[]E, E any](s S) S
    Clone returns a copy of the slice. The elements are copied using assignment,
    so this is a shallow clone. The result may have additional unused capacity.
    The result preserves the nilness of s.
```

O aviso da documentação é o certo. Clonar tudo dobra as cópias à toa; clonar um pedaço curto de um
valor grande **que você vai guardar** é o que economiza memória. Um handler de requisição que lê um
corpo, tira dele um cabeçalho e retorna não tem nada a corrigir, porque o corpo inteiro fica
inalcançável quando ele retorna. Um cache que guarda esse cabeçalho por um dia tem. `slices.Clone` é
uma função genérica, e é por isso que a assinatura dela tem colchetes; a lição 30 trata deles.
