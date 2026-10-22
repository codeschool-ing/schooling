---
title: Menos alocações: pré-alocar, reaproveitar, pool
version: 1
---

Três técnicas eliminam a maior parte das alocações que vale eliminar, e vale aprendê-las nesta ordem,
porque cada uma é mais arriscada que a anterior. **Pré-alocar muda uma linha. Reaproveitar um buffer
muda quem é dono da memória. Um `sync.Pool` passa memória de uma goroutine para outra, e pode deixar
um programa mais lento ou errado se for usado onde não cabe.** As três são medidas aqui, antes e
depois, e nenhuma vale a pena antes que uma medição como a da seção 05 tenha dito que é na alocação
que o tempo vai.

## Pré-alocar quando o tamanho é conhecido

A seção 05 mediu a primeira técnica num benchmark: uma dica com o número exato de linhas levou o
`Load` de 53,8 MB e 53 ms por iteração para 20,5 MB e 24 ms. A mesma flag no programa inteiro, sobre
as dois milhões de linhas do `big.log`, a segunda execução recebendo a contagem de linhas do `wc -l`:

```
ana@vm:~/mem-hits$ ./slowest big.log && ./slowest -hint $(wc -l < big.log) big.log
2000000 requests, p99 396ms, slowest 400ms
1.74s, 21 collections, peak 501884 kB
2000000 requests, p99 396ms, slowest 400ms
898ms, 2 collections, peak 330968 kB
```

**Duas coletas em vez de vinte e uma, um pico de 330.968 kB em vez de 501.884, e metade do tempo.**
As coletas caíram por um motivo que a aritmética da seção 04 explica: a primeira coisa grande que o
programa alocou foi um array com espaço para todas as entradas, o heap ficou grande desde o início,
e a meta, o dobro do heap vivo, ficou grande junto. O pico caiu porque nenhum array precisou existir
ao lado de uma cópia maior de si mesmo.

O tamanho não precisa ser exato para ajudar. `make([]T, 0, n)` com um palpite pequeno demais ainda
poupa o crescimento inicial, e um grande demais desperdiça só a diferença. O tamanho de um arquivo
dividido por um comprimento típico de linha é um palpite razoável para um log; um tamanho conhecido
por um cabeçalho, ou pelo `len` da fatia de entrada, é melhor.

## Reaproveitar um buffer que é seu

A segunda técnica serve a um laço que monta algo temporário a cada volta. Escrever entradas de volta
no formato do log é um caso: um relatório das requisições mais lentas, digamos, impresso como linhas
de log. Um segundo arquivo no `keep` faz isso de três jeitos:

```schooling-example
{
  "language": "go",
  "file": "internal/keep/write.go",
  "parts": [
    {
      "code": "package keep\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"strconv\"\n\t\"sync\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "Um segundo arquivo no `keep`. Ele escreve as entradas de volta no formato do próprio log, de três jeitos."
    },
    {
      "code": "// WriteFmt writes entries in the log's own format, one Fprintf a line.\nfunc WriteFmt(w io.Writer, entries []tally.Entry) error {\n\tfor _, e := range entries {\n\t\t_, err := fmt.Fprintf(w, \"%s %s %s %d %dms\\n\", e.Time.Format(time.RFC3339),\n\t\t\te.Method, e.Path, e.Status, e.Duration.Milliseconds())\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t}\n\treturn nil\n}\n",
      "note": "**A versão óbvia.** `Format` devolve uma string nova para o horário, e cada argumento entregue ao `Fprintf` é convertido num valor de interface na entrada, o que também pode alocar."
    },
    {
      "code": "// AppendLine appends e to dst in the log's format and returns the extended\n// slice, the way strconv.AppendInt does.\nfunc AppendLine(dst []byte, e tally.Entry) []byte {\n\tdst = e.Time.AppendFormat(dst, time.RFC3339)\n\tdst = append(dst, ' ')\n\tdst = append(dst, e.Method...)\n\tdst = append(dst, ' ')\n\tdst = append(dst, e.Path...)\n\tdst = append(dst, ' ')\n\tdst = strconv.AppendInt(dst, int64(e.Status), 10)\n\tdst = append(dst, ' ')\n\tdst = strconv.AppendInt(dst, e.Duration.Milliseconds(), 10)\n\treturn append(dst, \"ms\\n\"...)\n}\n",
      "note": "**O estilo append da biblioteca padrão**: `time.Time.AppendFormat` e `strconv.AppendInt` escrevem na fatia que recebem e a devolvem, fazendo-a crescer só se for pequena demais. Nada aqui aloca quando `dst` tem espaço."
    },
    {
      "code": "// Write writes the same lines as WriteFmt through one buffer that every\n// line reuses.\nfunc Write(w io.Writer, entries []tally.Entry) error {\n\tbuf := make([]byte, 0, 64)\n\tfor _, e := range entries {\n\t\tbuf = AppendLine(buf[:0], e)\n\t\tif _, err := w.Write(buf); err != nil {\n\t\t\treturn err\n\t\t}\n\t}\n\treturn nil\n}\n",
      "note": "Um buffer para a chamada inteira. `buf[:0]` o esvazia sem devolver o seu array, então cada linha depois da primeira é escrita numa memória que já está lá."
    },
    {
      "code": "// lines holds buffers for WriteEntry. It stores pointers, so that Put has\n// nothing to allocate.\nvar lines = sync.Pool{New: func() any { b := make([]byte, 0, 64); return &b }}\n",
      "note": "**Um `sync.Pool` de buffers.** `New` cria um quando o pool está vazio. O pool guarda `*[]byte`, e não `[]byte`, por um motivo que o fim desta seção mede."
    },
    {
      "code": "// WriteEntry writes one entry in a single Write, so lines stay whole when\n// several goroutines share w. It may be called from any goroutine.\nfunc WriteEntry(w io.Writer, e tally.Entry) error {\n\tbp := lines.Get().(*[]byte)\n\t*bp = AppendLine((*bp)[:0], e)\n\t_, err := w.Write(*bp)\n\tlines.Put(bp)\n\treturn err\n}",
      "note": "Uma função que qualquer um pode chamar de qualquer goroutine, então não há um dono único para guardar um buffer. Ela pega um emprestado do pool, escreve e o devolve."
    }
  ]
}
```

Uma versão mais rápida só vale a pena se escrever os mesmos bytes, então os testes vêm antes.
Salve-os como `internal/keep/write_test.go`:

```go
package keep_test

import (
	"bytes"
	"io"
	"os"
	"testing"

	"example.com/hits/internal/keep"
	"example.com/hits/internal/tally"
)

func entries(b *testing.B) []tally.Entry {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		b.Fatal(err)
	}
	e, err := keep.Load(bytes.NewReader(data), 0)
	if err != nil {
		b.Fatal(err)
	}
	return e
}

func BenchmarkWrite(b *testing.B) {
	all := entries(b)
	b.Run("fmt", func(b *testing.B) {
		for b.Loop() {
			keep.WriteFmt(io.Discard, all)
		}
	})
	b.Run("append", func(b *testing.B) {
		for b.Loop() {
			keep.Write(io.Discard, all)
		}
	})
}

func BenchmarkWriteEntry(b *testing.B) {
	e := entries(b)[0]
	b.Run("new-buffer", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				io.Discard.Write(keep.AppendLine(make([]byte, 0, 64), e))
			}
		})
	})
	b.Run("pool", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				keep.WriteEntry(io.Discard, e)
			}
		})
	})
}

func TestWriteMatchesWriteFmt(t *testing.T) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		t.Fatal(err)
	}
	all, err := keep.Load(bytes.NewReader(data), 0)
	if err != nil {
		t.Fatal(err)
	}
	var a, b bytes.Buffer
	keep.WriteFmt(&a, all)
	keep.Write(&b, all)
	if !bytes.Equal(a.Bytes(), data) || !bytes.Equal(b.Bytes(), data) {
		t.Error("the lines written differ from the lines read")
	}
}
```

`TestWriteMatchesWriteFmt` carrega o log de teste, escreve-o de volta dos dois jeitos e compara cada
resultado com o arquivo original, byte a byte. `BenchmarkWrite` mede os dois laços sobre as 100.000
entradas; `BenchmarkWriteEntry` chama `WriteEntry` de várias goroutines ao mesmo tempo com
`b.RunParallel`, contra uma linha de base que cria um buffer novo a cada vez.

```
ana@vm:~/mem-hits$ go test -count=1 ./internal/keep
ok  	example.com/hits/internal/keep	0.132s
ana@vm:~/mem-hits$ go test -run "^$" -bench Write -benchmem ./internal/keep
goos: linux
goarch: amd64
pkg: example.com/hits/internal/keep
cpu: Intel(R) Xeon(R) Processor
BenchmarkWrite/fmt-4    	      51	  23219544 ns/op	 7888408 B/op	  485979 allocs/op
BenchmarkWrite/append-4 	     231	   5193665 ns/op	      64 B/op	       1 allocs/op
BenchmarkWriteEntry/new-buffer-4         	13051022	        85.56 ns/op	      64 B/op	       1 allocs/op
BenchmarkWriteEntry/pool-4               	50229170	        27.15 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/hits/internal/keep	5.174s
```

Primeiro os dois laços de escrita:

| | `fmt` | `append` |
|---|---|---|
| ns/op | 23.219.544 | 5.193.665 |
| B/op | 7.888.408 | 64 |
| allocs/op | 485.979 | 1 |

**485.979 alocações para 100.000 linhas, quase cinco por linha, contra uma para o arquivo inteiro.**
Essa uma é o buffer de 64 bytes, que escapa porque é passado ao `w.Write`, um método de interface que
o compilador não consegue enxergar por dentro. Tudo depois da primeira linha é escrito numa memória
que já está lá. O laço também fica mais de quatro vezes mais rápido, e a maior parte disso são as
alocações que sumiram: nenhuma string nova para cada horário, nenhum valor de interface para cada
argumento, e menos coisa para o coletor achar depois.

**O custo é a posse.** `buf` pertence ao `Write` durante uma chamada, e cada linha sobrescreve a
anterior. Isso só é seguro porque o `w.Write` não pode guardar a fatia que recebeu, e a documentação
de `io.Writer` diz isso com todas as letras: "Implementations must not retain p", as implementações
não devem reter p. Um código que entrega um buffer reaproveitado a qualquer coisa que possa
guardá-lo tem um defeito que nenhum teste de uma linha só vai achar.

## Um pool, quando não há dono

O `Write` podia guardar um buffer porque uma chamada faz toda a escrita. O `WriteEntry` é chamado uma
vez por linha, de qualquer goroutine, então não há uma chamada para ser dona de um buffer nem lugar
para guardá-lo. É para esse caso que existe o `sync.Pool`. O exemplo da própria documentação dele é
o pacote `fmt`, que guarda seus impressores num pool pelo mesmo motivo.

Do benchmark: **27,15 ns e nenhuma alocação com o pool, contra 85,56 ns e uma alocação de 64 bytes
com um buffer novo a cada vez.** Quatro goroutines tiraram e devolveram buffers 50.229.170 vezes
entre elas na última rodada, sem alocar nada por operação.

O que um pool guarda, e por quanto tempo, é a parte que as pessoas erram. Um programa em
`~/mem-pool`, com `main.go`:

```go
// Command pool shows what a sync.Pool keeps, and what it costs to use one
// wrongly.
package main

import (
	"fmt"
	"runtime"
	"sync"
	"testing"
)

func main() {
	made := 0
	p := sync.Pool{New: func() any { made++; return new([4096]byte) }}

	b := p.Get()
	p.Put(b)
	fmt.Printf("put back, got again:        same %t, made %d\n", p.Get() == b, made)

	p.Put(b)
	runtime.GC()
	fmt.Printf("after one collection:       same %t, made %d\n", p.Get() == b, made)

	p.Put(b)
	runtime.GC()
	runtime.GC()
	fmt.Printf("after two collections:      same %t, made %d\n", p.Get() == b, made)

	byValue := sync.Pool{New: func() any { return make([]byte, 0, 64) }}
	byPointer := sync.Pool{New: func() any { b := make([]byte, 0, 64); return &b }}
	fmt.Println("allocations per Get and Put of a []byte: ", testing.AllocsPerRun(1000, func() {
		b := byValue.Get().([]byte)
		byValue.Put(b[:0])
	}))
	fmt.Println("allocations per Get and Put of a *[]byte:", testing.AllocsPerRun(1000, func() {
		bp := byPointer.Get().(*[]byte)
		byPointer.Put(bp)
	}))
}
```

Rodado primeiro num processador, depois nos quatro do laboratório:

```
ana@vm:~/mem-pool$ GOMAXPROCS=1 go run .
put back, got again:        same true, made 1
after one collection:       same true, made 1
after two collections:      same false, made 2
allocations per Get and Put of a []byte:  1
allocations per Get and Put of a *[]byte: 0
ana@vm:~/mem-pool$ go run .
put back, got again:        same true, made 1
after one collection:       same false, made 2
after two collections:      same false, made 3
allocations per Get and Put of a []byte:  1
allocations per Get and Put of a *[]byte: 0
```

Num processador, o buffer sobreviveu a uma coleta e sumiu depois da segunda. **Um pool é esvaziado
pelo coletor**: a cada ciclo o que ele guarda passa para um segundo nível, e o que ainda está nesse
nível no ciclo seguinte é descartado. Em quatro processadores até uma coleta bastou para perdê-lo:
cada processador guarda os seus próprios itens, e depois do `runtime.GC` a goroutine pode voltar a
rodar num processador diferente daquele que guardou o buffer. Um pool é um cache que esquece no seu
próprio ritmo, nunca um lugar para guardar algo que precisa estar lá depois.

As duas últimas linhas são a ressalva que o comentário sobre `lines` menciona. `Put` recebe um
`any`, e um `[]byte` transformado em `any` precisa ter as suas três palavras copiadas para o heap,
**uma alocação por `Put`, exatamente o que o pool deveria eliminar**. Um ponteiro cabe num `any` como
está, então um pool de `*[]byte` não custa nada. A regra é guardar ponteiros no pool.

Mais uma ressalva está escrita no próprio `fmt`:

```
ana@vm:~/mem-pool$ sed -n 163,167p /usr/local/go/src/fmt/print.go
	if cap(p.buf) > 64*1024 {
		p.buf = nil
	} else {
		p.buf = p.buf[:0]
	}
```

**Um buffer acima de 64 KiB não volta para o pool.** Uma linha enorme deixaria um buffer enorme no
pool, entregue a cada chamador seguinte que queria uns poucos bytes, e um pool em uso constante
continuaria segurando a maior coisa que já viu. Um pool de buffers cujo tamanho depende da entrada
precisa da mesma verificação.

## Qual delas, e quando

| técnica | serve quando | o seu risco |
|---|---|---|
| pré-alocar | o tamanho é conhecido ou dá para estimar | quase nenhum: um palpite grande demais desperdiça a diferença |
| reaproveitar um buffer | uma função é dona do trabalho do começo ao fim | algo guarda o buffer depois que ele é reaproveitado |
| `sync.Pool` | muitas goroutines precisam de buffers de vida curta e nenhuma é dona deles | esquecer de zerar, guardar valores em vez de ponteiros, guardar buffers enormes |

As três são respostas a uma medição, e a medição vem primeiro. O `hits count` gasta cerca de 1% da
execução coletando, pelo trace da seção 03, então nenhuma delas o deixaria visivelmente mais rápido.
O `slowest` rodou na metade do tempo depois que um argumento a mais no `make` removeu as cópias da
fatia que ele fazia crescer.
