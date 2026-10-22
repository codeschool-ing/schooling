---
title: A forma de um pool de workers
version: 1
---

Goroutines são baratas, a lição 2 mediu o quanto, e isso tenta todo mundo a usar uma goroutine por
tarefa. **As goroutines são baratas; o que as tarefas tocam não é.** Cada uma pode segurar um
arquivo, uma conexão com um banco de dados, uma vaga no limite de requisições de outra pessoa ou um
pedaço da memória. Mil tarefas de uma vez significam mil dessas coisas de uma vez, e a máquina ou o
servidor do outro lado tem um limite do qual a contagem de goroutines não sabe nada.

## Mil tarefas, mil arquivos

O primeiro programa inicia uma goroutine por tarefa, e cada tarefa abre um arquivo, trabalha por 50
milissegundos e o fecha. Um mutex, o assunto da lição 8, protege as duas variáveis que as goroutines
compartilham. Ele é compilado com `go build -o unbounded unbounded.go`, como todo programa desta
lição, e salvo como `unbounded.go`:

```go
// Command unbounded starts one goroutine per job, and every job holds a file open.
package main

import (
	"fmt"
	"os"
	"sync"
	"time"
)

// job opens a file, works on it for a moment, and closes it.
func job() error {
	f, err := os.Open("/etc/hostname")
	if err != nil {
		return err
	}
	defer f.Close()
	time.Sleep(50 * time.Millisecond)
	return nil
}

func main() {
	var mu sync.Mutex
	failed := 0
	var lastErr error
	var wg sync.WaitGroup
	for range 1000 {
		wg.Go(func() {
			if err := job(); err != nil {
				mu.Lock()
				failed++
				lastErr = err
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println("jobs: 1000  failed:", failed)
	if lastErr != nil {
		fmt.Println("last error:", lastErr)
	}
}
```

Um processo só pode ter um certo número de arquivos abertos ao mesmo tempo, e `ulimit -n` imprime
esse limite para o shell e tudo o que ele inicia. Rodado sob o limite da máquina, e depois sob um
mais baixo num subshell, que é para isso que servem os parênteses, para que o limite menor acabe
junto com eles:

```
ana@vm:~/pool$ ulimit -n
1024
ana@vm:~/pool$ ./unbounded
jobs: 1000  failed: 0
ana@vm:~/pool$ (ulimit -n 256; ./unbounded)
jobs: 1000  failed: 752
last error: open /etc/hostname: too many open files
```

**Sob 1.024 funcionou, e sob 256 três tarefas em quatro falharam**: 752 delas. Nada no programa
mudou. No pico ele teve quase mil arquivos abertos ao mesmo tempo, porque mil goroutines chegaram ao
`os.Open` nos mesmos poucos milissegundos. Sob o limite mais alto ele escapou; o mais baixo é a cara
de uma máquina mais ocupada, de um contêiner ou do limite de conexões de um banco de dados. Um
programa que só funciona enquanto o recurso é farto tem o seu limite definido por acaso.

## Um número fixo de workers

Um pool de workers inverte o arranjo. **Um número fixo de goroutines, os workers, pega tarefas de um
canal uma de cada vez**, então nunca há mais tarefas em andamento do que isso, seja qual for o
tamanho da fila. Três papéis fazem isso funcionar: alguém alimenta as tarefas e fecha o canal, os
workers o esvaziam, e alguém fecha os resultados quando os workers terminam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um pool de workers. Uma goroutine produtora envia números de tarefa no canal jobs e o fecha quando terminou de enviar. Um número fixo de workers, aqui três de cinquenta, pega cada um a próxima tarefa de jobs e envia o resultado no canal results. Uma goroutine de fechamento espera todos os workers com wg.Wait e então fecha results. O main lê results até ele ser fechado.\"><defs><marker id=\"l07pool-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07pool-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l07pool-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">produtora</text><text x=\"95\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1000 tarefas, depois close(jobs)</text><rect x=\"195\" y=\"125\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">jobs</text><path d=\"M172 145 H193\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><text x=\"390\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">workers: um número fixo</text><rect x=\"330\" y=\"45\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">worker 1</text><path d=\"M267 145 L328 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><path d=\"M452 65 L493 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><rect x=\"330\" y=\"105\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">worker 2</text><path d=\"M267 145 L328 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><path d=\"M452 125 L493 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><rect x=\"330\" y=\"165\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">worker 3</text><path d=\"M267 145 L328 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-phosphor)\"></path><path d=\"M452 185 L493 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><text x=\"390\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… mais 47</text><rect x=\"495\" y=\"125\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">results</text><rect x=\"600\" y=\"115\" width=\"105\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main</text><text x=\"652\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">lê até results ser fechado</text><path d=\"M577 145 H598\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07pool-amber)\"></path><rect x=\"470\" y=\"250\" width=\"235\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"587\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">fechamento</text><text x=\"587\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">wg.Wait(); close(results)</text><path d=\"M535 248 V167\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07pool-wire)\"></path></svg>", "caption": "pool.go: a fila pode ter qualquer tamanho, e nunca há mais de cinquenta tarefas em andamento ao mesmo tempo."}
```

O programa, parte por parte, salvo como `pool.go`:

```schooling-example
{"language": "go", "file": "pool.go", "parts": [{"code": "// Command pool runs 1000 jobs on a fixed number of workers.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\t\"sync\"\n\t\"time\"\n)\n\n", "note": "A biblioteca padrão, e mais nada."}, {"code": "func job() error {\n\tf, err := os.Open(\"/etc/hostname\")\n\tif err != nil {\n\t\treturn err\n\t}\n\tdefer f.Close()\n\ttime.Sleep(50 * time.Millisecond)\n\treturn nil\n}\n\n", "note": "**A mesma tarefa do `unbounded.go`.** Ela segura um arquivo aberto por 50 milissegundos, que é o recurso que o pool existe para racionar."}, {"code": "func main() {\n\tconst workers = 50\n\tstart := time.Now()\n\n", "note": "**O tamanho do pool é um número só, escolhido aqui.** Cinquenta workers significam no máximo cinquenta arquivos abertos ao mesmo tempo, seja qual for o número de tarefas."}, {"code": "\tjobs := make(chan int)\n\tresults := make(chan error)\n\n", "note": "Dois canais sem buffer: `jobs` leva o trabalho aos workers, `results` traz as respostas de volta. Os valores em `jobs` são só números de tarefa, porque a tarefa em si não precisa de entrada."}, {"code": "\tvar wg sync.WaitGroup\n\tfor range workers {\n\t\twg.Go(func() {\n\t\t\tfor range jobs {\n\t\t\t\tresults <- job()\n\t\t\t}\n\t\t})\n\t}\n\n", "note": "**Os workers.** Cinquenta goroutines, cada uma rodando um `for range` sobre `jobs`, então cada uma pega a próxima tarefa assim que termina a anterior. O laço acaba quando `jobs` está fechado e vazio, e o worker retorna."}, {"code": "\tgo func() {\n\t\tfor i := range 1000 {\n\t\t\tjobs <- i\n\t\t}\n\t\tclose(jobs)\n\t}()\n\n", "note": "**A produtora**, numa goroutine própria, distribui mil tarefas e depois fecha `jobs`. Fechar é o que deixa o laço de cada worker acabar."}, {"code": "\tgo func() {\n\t\twg.Wait()\n\t\tclose(results)\n\t}()\n\n", "note": "**O fechamento.** Quando os cinquenta workers retornaram, ninguém mais vai enviar em `results`, então esta goroutine o fecha. Sem ela o laço abaixo esperaria para sempre, o vazamento de receptor da lição 6."}, {"code": "\tfailed := 0\n\tfor err := range results {\n\t\tif err != nil {\n\t\t\tfailed++\n\t\t}\n\t}\n\tfmt.Println(\"jobs: 1000  workers:\", workers, \" failed:\", failed, \" took:\", time.Since(start).Round(10*time.Millisecond))\n}\n", "note": "O `main` é o único leitor de `results`, então a contagem não precisa de trava. O laço acaba quando a goroutine de fechamento fecha o canal."}]}
```

```
ana@vm:~/pool$ (ulimit -n 256; ./pool)
jobs: 1000  workers: 50  failed: 0  took: 1.01s
```

**Sob o limite que quebrou o `unbounded.go`, nada falhou.** Cinquenta arquivos abertos de cada vez
ficam bem abaixo de 256. As mil tarefas levaram cerca de um segundo: vinte rodadas de cinquenta
tarefas, cada uma com 50 milissegundos. A seção 03 trata de como esse `50` deve ser escolhido.

As duas goroutines que fecham são a parte que as pessoas erram. A produtora precisa fechar `jobs`,
ou os workers esperam mais tarefas para sempre. Alguém precisa fechar `results` depois do último
worker, ou o `main` espera mais resultados para sempre. E quem fecha `results` não pode ser um
worker, porque um worker não sabe se os outros quarenta e nove terminaram, que é o que `wg.Wait`
sabe.
