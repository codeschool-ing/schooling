---
title: Fazendo algo exatamente uma vez
version: 1
---

Certos trabalhos devem acontecer uma vez na vida de um programa, e não antes de serem necessários:
ler um arquivo de configuração, abrir um pool de conexões, compilar uma expressão regular grande. Com
goroutines a versão óbvia, *se ainda não carregou, carregue*, é uma corrida, porque duas goroutines
podem ver "ainda não carregou" ao mesmo tempo. **O `sync.Once` roda uma função na primeira vez que o
`Do` é chamado e nunca mais, e todo outro chamador espera até essa primeira execução terminar.**

## `sync.Once`

Oito goroutines pedem uma configuração no mesmo momento, e um contador registra quantas vezes ela
foi carregada. Salvo como `once.go`:

```go
// Command once loads a configuration lazily, from eight goroutines, exactly once.
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

var loads atomic.Int64

type Config struct{ Workers int }

func load() Config {
	loads.Add(1)
	time.Sleep(10 * time.Millisecond) // reading a file, say
	return Config{Workers: 4}
}

var (
	once   sync.Once
	config Config
)

// Get returns the configuration, loading it on the first call.
func Get() Config {
	once.Do(func() { config = load() })
	return config
}

func main() {
	var wg sync.WaitGroup
	for range 8 {
		wg.Go(func() { _ = Get().Workers })
	}
	wg.Wait()
	fmt.Println("callers: 8  loads:", loads.Load(), " workers:", Get().Workers)
}
```

```
ana@vm:~/waitonce$ go run once.go
callers: 8  loads: 1  workers: 4
```

Oito chamadores, uma carga. As sete goroutines que chegaram enquanto a primeira ainda estava dentro
de `load` esperaram por ela, então nenhuma viu um `Config` vazio. Essa espera é a parte que uma flag
escrita à mão erra: um booleano ligado no começo do trabalho diz às outras *alguém está carregando*,
e não *está pronto*.

## `OnceValue` e `OnceValues`

O Go 1.21 acrescentou três funções que embrulham o padrão sem as duas variáveis do pacote.
`sync.OnceFunc(f)` devolve uma função que chama `f` uma vez; `sync.OnceValue(f)` faz o mesmo e
devolve o resultado de `f` a todo chamador; `sync.OnceValues(f)` devolve um resultado e um erro. A que
merece uma demonstração é a última, por causa do que ela faz com o erro. Ela roda num diretório sem
`token.txt`, salva como `oncevalues.go`:

```go
// Command oncevalues caches a result and an error with sync.OnceValues.
package main

import (
	"fmt"
	"os"
	"sync"
)

var attempts int

// token reads the file at most once, however many times it is called.
var token = sync.OnceValues(func() (string, error) {
	attempts++
	b, err := os.ReadFile("token.txt")
	return string(b), err
})

func main() {
	for range 3 {
		t, err := token()
		fmt.Printf("token %q, err %v\n", t, err)
	}
	os.WriteFile("token.txt", []byte("s3cr3t"), 0o600)
	t, err := token()
	fmt.Printf("after writing the file: token %q, err %v\n", t, err)
	fmt.Println("attempts:", attempts)
}
```

```
ana@vm:~/waitonce$ go run oncevalues.go
token "", err open token.txt: no such file or directory
token "", err open token.txt: no such file or directory
token "", err open token.txt: no such file or directory
after writing the file: token "", err open token.txt: no such file or directory
attempts: 1
```

**O erro foi guardado tão fielmente quanto um resultado seria.** O arquivo não existia na primeira
chamada, então toda chamada seguinte recebeu o mesmo erro, inclusive a que veio depois de o arquivo
ser escrito. `attempts: 1` diz que o arquivo foi lido uma vez. Esse é o comportamento certo para
"faça isto uma vez", e errado para "faça isto até funcionar". Se uma primeira tentativa que falhou
deve ser repetida, o `Once` é a ferramenta errada, e um mutex em volta de uma flag de "carregado"
ligada só no sucesso é a certa.

Mais uma regra da documentação de `sync.Once`: se a função passada ao `Do` entra em pânico, o `Do`
a considera feita, e as chamadas seguintes não a rodam de novo.
