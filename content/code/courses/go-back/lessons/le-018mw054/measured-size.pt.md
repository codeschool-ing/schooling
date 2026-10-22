---
title: Os bytes, medidos
version: 1
---

"Protobuf é menor" se diz muito e se mede pouco, e a resposta honesta depende do que se compara com o quê.
Este programa monta a mesma lista de eventos duas vezes, como o JSON do boxoffice a mandaria e como uma
mensagem Protocol Buffers com um `Event` repetido, e informa os tamanhos crus e comprimidos com gzip, do
jeito que o HTTP comprime um corpo quando os dois lados concordam. Depois cronometra a codificação da lista
maior:

```go
// boxoffice/cmd/sizes/main.go
package main

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"example.com/boxoffice/internal/seatspb"
	"google.golang.org/protobuf/encoding/protowire"
	"google.golang.org/protobuf/proto"
)

type jsonEvent struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

// encode writes the events as a message with one field, repeated Event events = 1.
func encode(events []*seatspb.Event) []byte {
	var b []byte
	for _, e := range events {
		msg, _ := proto.Marshal(e)
		b = protowire.AppendTag(b, 1, protowire.BytesType)
		b = protowire.AppendBytes(b, msg)
	}
	return b
}

func gzipped(b []byte) int {
	var buf bytes.Buffer
	w := gzip.NewWriter(&buf)
	w.Write(b)
	w.Close()
	return buf.Len()
}

func main() {
	for _, n := range []int{2, 200} {
		var pbs []*seatspb.Event
		var js []jsonEvent
		for i := 1; i <= n; i++ {
			name := fmt.Sprintf("Recital number %03d", i)
			pbs = append(pbs, &seatspb.Event{Id: int32(i), Name: name, Seats: 120, Sold: int32(i % 120)})
			js = append(js, jsonEvent{ID: i, Name: name, Seats: 120, Sold: i % 120})
		}
		j, _ := json.Marshal(js)
		p := encode(pbs)
		fmt.Printf("%3d events: JSON %6d bytes, %5d gzipped; protobuf %6d bytes, %5d gzipped\n",
			n, len(j), gzipped(j), len(p), gzipped(p))
		if n == 200 {
			jt := testing.Benchmark(func(b *testing.B) {
				for b.Loop() {
					json.Marshal(js)
				}
			})
			pt := testing.Benchmark(func(b *testing.B) {
				for b.Loop() {
					encode(pbs)
				}
			})
			fmt.Printf("encoding 200 events: JSON %v per list, protobuf %v per list\n",
				time.Duration(jt.NsPerOp()), time.Duration(pt.NsPerOp()))
		}
	}
}
```

O `encode` escreve a lista exatamente como seria escrita uma mensagem que declara
`repeated Event events = 1`, uma tag e um tamanho por evento, com o `protowire`, o pacote que conhece o
formato de fio byte a byte. As duas codificações levam os mesmos quatro campos. Ele rodou duas vezes:

```
ana@vm:~/boxoffice$ go run ./cmd/sizes
  2 events: JSON    117 bytes,   142 gzipped; protobuf     56 bytes,    81 gzipped
200 events: JSON  12094 bytes,  1430 gzipped; protobuf   5671 bytes,  1350 gzipped
encoding 200 events: JSON 35.146µs per list, protobuf 27.145µs per list
ana@vm:~/boxoffice$ go run ./cmd/sizes
  2 events: JSON    117 bytes,   142 gzipped; protobuf     56 bytes,    81 gzipped
200 events: JSON  12094 bytes,  1430 gzipped; protobuf   5671 bytes,  1350 gzipped
encoding 200 events: JSON 33.271µs per list, protobuf 27.296µs per list
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Barras para duzentos eventos. Sem compressão: JSON 12.094 bytes, protobuf 5.671. Com gzip: JSON 1.430, protobuf 1.350. As barras sem compressão diferem em mais da metade; as com gzip têm quase o mesmo tamanho.\"><defs><marker id=\"gb-l11-bytes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"165\" y=\"31\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JSON, sem compressão</text><rect x=\"175\" y=\"18\" width=\"420.0\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"603.0\" y=\"31\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12.094 B</text><text x=\"165\" y=\"75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">protobuf, sem compressão</text><rect x=\"175\" y=\"62\" width=\"196.9\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"379.9\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">5.671 B</text><text x=\"165\" y=\"119\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JSON, com gzip</text><rect x=\"175\" y=\"106\" width=\"49.7\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"232.7\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.430 B</text><text x=\"165\" y=\"163\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">protobuf, com gzip</text><rect x=\"175\" y=\"150\" width=\"46.9\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"229.9\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1.350 B</text></svg>", "caption": "Duzentos eventos, medidos pelo cmd/sizes. A compressão tira quase tudo o que deixava o JSON maior."}
```

**Sem compressão, o protobuf tem menos da metade do tamanho**: 5.671 bytes contra 12.094 para duzentos
eventos. Os nomes `"id"`, `"name"`, `"seats"` e `"sold"` se repetem em todo objeto JSON e não existem no
protobuf, e números ocupam um ou dois bytes em vez dos seus dígitos.

**Com compressão, a diferença quase some**: 1.350 contra 1.430 bytes, uns seis por cento. O gzip é muito bom
em tirar exatamente a repetição que deixava o JSON grande. Como APIs HTTP comprimem as respostas como
prática comum, **para listas grandes o argumento de banda a favor do gRPC é pequeno**. Para mensagens
minúsculas é o contrário: dois eventos ficam com mais bytes depois de comprimidos, nos dois formatos, porque
o cabeçalho do gzip custa mais do que economiza, e ali os 56 bytes do protobuf contra 117 são a diferença
inteira.

**A codificação é mais rápida, e não por muito**: uns 27 µs contra 33 a 35 µs por lista de duzentos, nesta
máquina. Perto dos milissegundos que uma consulta ao banco custa, desde a aula 6, nenhum dos dois números
importa para um serviço como o boxoffice. Importa para um serviço que não faz nada além de mover mensagens,
a centenas de milhares por segundo.

**A medição não diz que o gRPC é inútil.** Ela diz que tamanho e velocidade raramente são o motivo para
escolhê-lo. Os motivos que se sustentam estão no contrato, nos streams, nos prazos e nos clientes gerados, e
são o assunto do resto desta aula.
