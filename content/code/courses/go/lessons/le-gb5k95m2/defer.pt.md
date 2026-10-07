---
title: "defer: as chamadas que rodam na saída"
version: 1
---

`defer` guarda uma chamada de função e a executa quando a função em volta retorna. A imagem que
muita gente traz é o `with` de Python ou o `using` de C#, em que a limpeza acontece no fim de um
bloco. **Uma chamada adiada roda quando a função retorna, não quando o bloco termina**, e a
diferença aparece no momento em que um `defer` fica dentro de um laço. `~/panic-defer` guarda cinco
chamadas e imprime no meio delas:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command defer shows when deferred calls run, and in what order.\npackage main\n\nimport \"fmt\"\n\nfunc main() {\n\tfor i := range 3 {\n\t\tdefer fmt.Println(\"deferred in the loop:\", i)\n\t}\n",
      "note": "**Três chamadas guardadas, uma por volta do laço.** Nenhuma delas roda aqui: cada `defer` registra a chamada com o argumento, `i`, do jeito que ele está naquele momento."
    },
    {
      "code": "\n\tx := 1\n\tdefer fmt.Println(\"x when deferred:\", x)\n",
      "note": "**Os argumentos são lidos agora.** `x` vale 1 nesta linha, então é 1 que esta chamada vai imprimir, aconteça o que acontecer com `x` depois."
    },
    {
      "code": "\tdefer func() {\n\t\tfmt.Println(\"x when run:\", x)\n\t}()\n\tx = 2\n",
      "note": "Uma função literal sem argumentos, adiada. Ela lê `x` quando roda, e não agora, porque uma closure guarda a própria variável (lição 21). Depois `x` passa a valer 2."
    },
    {
      "code": "\n\tfmt.Println(\"end of main\")\n}\n",
      "note": "A última linha de `main`. Quando `main` retorna, as cinco chamadas adiadas rodam, a mais recente primeiro."
    }
  ],
  "output": "end of main\nx when run: 2\nx when deferred: 1\ndeferred in the loop: 2\ndeferred in the loop: 1\ndeferred in the loop: 0\n"
}
```

São três regras, e a saída mostra cada uma.

**Chamadas adiadas rodam na ordem inversa: a última a entrar é a primeira a sair.** A closure foi
adiada por último e rodou primeiro; as três chamadas do laço foram adiadas primeiro e rodaram por
último, de 2 até 0. A limpeza costuma desfazer as coisas na ordem inversa em que foram montadas, e
essa ordem faz isso sem que ninguém precise arrumar.

**Elas esperam a função, não o bloco.** O laço terminou, `end of main` foi impresso, e só então as
três chamadas de dentro do laço rodaram. Um `defer` num laço que roda mil vezes segura mil chamadas
até a função retornar.

**Os argumentos são avaliados na linha do `defer`.** `fmt.Println("x when deferred:", x)` foi
guardada com `x` já lido como 1, e o `x = 2` de depois não a alcançou. A função literal não recebia
argumentos. Ela lê `x` quando roda, e a essa altura `x` valia 2: ela capturou a variável, como a
lição 21 mostrou que as closures fazem.

## `defer f.Close()`

O uso que você mais vai escrever é fechar algo em toda saída de uma função. `countLines`, em
`~/panic-close`, abre um arquivo, conta as linhas dele com um `bufio.Scanner` e retorna:

```go
func countLines(name string) (int, error) {
	f, err := os.Open(name)
	if err != nil {
		return 0, err
	}
	defer f.Close()

	n := 0
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		n++
	}
	return n, sc.Err()
}

func main() {
	for _, name := range os.Args[1:] {
		n, err := countLines(name)
		if err != nil {
			fmt.Println(err)
			continue
		}
		fmt.Println(name, n)
	}
}
```

```
ana@vm:~/panic-close$ go build && ./lines notes.txt missing.txt
notes.txt 3
open missing.txt: no such file or directory
```

**`defer f.Close()` vai na linha depois da verificação do erro**, assim a chamada que fecha o
arquivo fica ao lado da chamada que o abriu, e ninguém precisa lembrar dela em cada `return` abaixo.
Antes da verificação, `f` pode nem ser um arquivo; `missing.txt` voltou no primeiro `return`, sem
nada aberto e nada adiado.

O laço em `main` é o motivo de `countLines` ser uma função à parte. Escrito ali dentro, com
`defer f.Close()` dentro do `for`, todo arquivo ficaria aberto até `main` retornar: a segunda regra
acima.

Os resultados de uma chamada adiada não vão para lugar nenhum, então `defer f.Close()` descarta o
`error` que `Close` devolve. Para um arquivo que o programa só leu, nada se perde. Quando o programa
escreveu o arquivo, chame `Close` você mesmo no fim e confira o erro como qualquer outro.

## Quando um panic passa por ali

Chamadas adiadas rodam seja como for que a função termine, e um panic é um dos jeitos.
`~/panic-exit` adia uma linha e depois para de um de dois jeitos, uma escrita num map nil ou
`os.Exit`:

```go
func main() {
	defer fmt.Println("deferred: cleaning up")
	if len(os.Args) > 1 {
		os.Exit(3)
	}
	var prices map[string]int
	prices["pear"] = 3
}
```

```
ana@vm:~/panic-exit$ go build && ./exit; echo $?
deferred: cleaning up
panic: assignment to entry in nil map

goroutine 1 [running]:
main.main()
	/home/ana/panic-exit/main.go:15 +0x7f
2
ana@vm:~/panic-exit$ ./exit now; echo $?
3
```

A linha adiada saiu **antes** da mensagem do panic. **Um panic executa as chamadas adiadas de cada
função de que sai, e só então para o programa.** Essa é a brecha que a seção 04 usa: uma função
adiada é o único lugar em que ainda roda código enquanto um panic está de saída.

O `os.Exit` é diferente. Com um argumento, o programa saiu com 3 e não imprimiu nada, e a
documentação dele diz por quê numa frase:

```
ana@vm:~/panic-exit$ go doc os.Exit
package os // import "os"

func Exit(code int)
    Exit causes the current program to exit with the given status code.
    Conventionally, code zero indicates success, non-zero an error. The program
    terminates immediately; deferred functions are not run.

    For portability, the status code should be in the range [0, 125].

```

O `log.Fatal` termina do mesmo jeito, o que é fácil de não perceber, porque o nome dele fala de log:

```
ana@vm:~/panic-exit$ go doc log.Fatal
package log // import "log"

func Fatal(v ...any)
    Fatal is equivalent to Print followed by a call to os.Exit(1).

```

**`os.Exit` e `log.Fatal` pulam todas as chamadas adiadas do programa.** Chame-os de `main`, depois
que o trabalho que precisava de limpeza terminou, e nunca do fundo de uma função que adiou alguma
coisa. A lição 20 mostrou uma função adiada mudando um resultado nomeado na saída; a seção 04 junta
isso com esta seção para transformar um panic num `error`.
