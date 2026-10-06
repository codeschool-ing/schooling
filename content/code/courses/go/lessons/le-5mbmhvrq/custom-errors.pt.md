---
title: Um tipo de erro seu, e o nil que não é nil
version: 1
---

Uma mensagem é escrita para uma pessoa. Um programa que chamou você às vezes precisa de mais do que
uma frase que ele teria de desmontar: qual linha do arquivo estava errada, qual caminho não abriu,
qual entrada não converteu. **Quando quem chama precisa de dados, o erro é um tipo seu, com esses
dados em campos**, e a mensagem é montada a partir deles. Foi o que a biblioteca padrão fez na
seção 02: `*fs.PathError` tem a operação e o caminho em campos, e `*strconv.NumError` tem a função
e a entrada.

Um verificador de configuração em `~/errors-custom` aponta a primeira linha que não tem `=`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command config checks the lines of a small configuration text.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n)\n\n// A LineError says which line of the input was wrong, and why.\ntype LineError struct {\n\tLine int\n\tMsg  string\n}\n",
      "note": "**Um tipo de erro é uma struct comum com o que quem chama pode querer saber.** Aqui, o número da linha e o que havia de errado nela. O nome termina em `Error`, como `PathError` e `NumError` na seção 02."
    },
    {
      "code": "\nfunc (e *LineError) Error() string {\n\treturn fmt.Sprintf(\"line %d: %s\", e.Line, e.Msg)\n}\n",
      "note": "**O único método que faz dela um `error`.** Nada declara que `LineError` implementa coisa alguma; ter `Error() string` basta. O receptor é um ponteiro, `*LineError`, então é o ponteiro que satisfaz `error`. Métodos são a lição 25, e essa escolha é a lição 26."
    },
    {
      "code": "\nfunc check(text string) error {\n\tfor i, line := range strings.Split(text, \"\\n\") {\n\t\tif line != \"\" && !strings.Contains(line, \"=\") {\n\t\t\treturn &LineError{Line: i + 1, Msg: \"no = in \" + line}\n\t\t}\n\t}\n\treturn nil\n}\n",
      "note": "**O tipo do resultado é `error`, não `*LineError`.** Uma falha devolve um ponteiro para um `LineError` novo; o sucesso devolve o literal `nil`. As linhas são contadas a partir de 1 porque uma pessoa vai lê-las, e o `range` conta a partir de 0."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(check(\"port=8080\\nhost=localhost\"))\n\terr := check(\"port=8080\\nhost localhost\")\n\tfmt.Println(err)\n\tfmt.Printf(\"%T\\n\", err)\n}\n",
      "note": "Dois textos, um correto e outro com um espaço onde deveria estar o `=`. Quem chama vê um `error` e o imprime, e o `fmt` chama o método `Error` que o tipo escreveu."
    }
  ],
  "output": "<nil>\nline 2: no = in host localhost\n*main.LineError\n"
}
```

`check` faz o que a seção 03 pediu de uma função: devolve `nil` quando nada falhou e um `error`
quando algo falhou, e quem chama só precisa de `if err != nil` para distinguir os dois. O campo
`Line` está ali para quem chama e quiser usá-lo. Chegar a um campo através de uma variável do tipo
`error` exige um passo que esta lição não mostra, o `errors.As`, e a lição 34 trata dele.

## O nil que não é nil

Agora uma mudança pequena, do tipo que alguém faz para ser preciso. `check` só falha com um
`LineError`, então por que não dizer isso na assinatura? Em `~/errors-nil` ela devolve
`*LineError`, e uma segunda função, `load`, repassa o resultado como `error`:

```go
func check(text string) *LineError {
	for i, line := range strings.Split(text, "\n") {
		if line != "" && !strings.Contains(line, "=") {
			return &LineError{Line: i + 1, Msg: "no = in " + line}
		}
	}
	return nil
}

func load(text string) error {
	return check(text)
}

func main() {
	err := load("port=8080\nhost=localhost")
	fmt.Printf("%T %v\n", err, err == nil)
	if err != nil {
		fmt.Println("load failed:", err)
		fmt.Println(err.Error())
	}
}
```

O texto está correto, então `check` devolve `nil`. Eis o que o `main` viu:

```
ana@vm:~/errors-nil$ go vet && go run .
*main.LineError false
load failed: <nil>
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x49caf0]

goroutine 1 [running]:
main.(*LineError).Error(...)
	/home/ana/errors-nil/main.go:16
main.main()
	/home/ana/errors-nil/main.go:37 +0xf0
exit status 2
```

O `go vet` não encontrou nada, e o programa compilou. Depois `err == nil` deu `false` para uma
carga que deu certo, o programa anunciou uma falha e deu `<nil>` como motivo, e a chamada direta a
`Error` o derrubou com status de saída 2. A queda é um `panic`, assunto da lição 36, e a lição 37 lê
esse rastro linha a linha; por ora, os quadros dele dizem que a queda aconteceu dentro de
`(*LineError).Error`, chamado a partir de `main`.

É a interface com um ponteiro nil da lição 28, encontrada onde ela custa mais caro. O `return nil`
em `check` produziu um ponteiro nil do tipo `*LineError`. Quando `load` o devolveu como `error`, Go
o guardou numa interface, com tipo e tudo, então a palavra do tipo dizia `*main.LineError` e só o
ponteiro era nil. **Um valor de interface só é `nil` quando as duas palavras dele estão vazias**, o
tipo e o ponteiro da lição 22, e com `error` isso pesa mais do que em qualquer lugar: todo
`if err != nil` do programa lê esse valor como falha.

O `<nil>` da segunda linha é o `fmt` encobrindo o problema: imprimir chamou `Error`
num ponteiro nil, `Error` leu `e.Line` por esse ponteiro e entrou em pânico, e o `fmt` capturou o
pânico e imprimiu `<nil>` no lugar. A linha seguinte chamou `Error` sem o `fmt` no meio, e nada
capturou.

O conserto é a assinatura que alguém mudou. Em `~/errors-nilfix` a única diferença é que `check`
volta a devolver `error`:

```
ana@vm:~/errors-nilfix$ go vet && go run .
<nil> true
```

Com `error` como tipo do resultado, o `return nil` de `check` é uma interface nil desde o começo, e
`load` repassa exatamente isso. **Uma função que pode falhar declara o resultado como `error`,
nunca como o seu próprio tipo de erro, e devolve um `nil` literal quando dá certo.** O tipo
concreto continua lá quando algo falha: o `%T` imprimiu `*main.LineError` em `~/errors-custom`
para uma função cuja assinatura dizia `error`.
