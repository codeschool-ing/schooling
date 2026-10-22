---
title: Arquivos são Readers e Writers com nome
version: 1
---

A lição 17 disse que um arquivo é um Reader e um Writer. **Isso é tudo o que há de especial num
arquivo depois de aberto: o resto é abri-lo, fechá-lo e saber o que deu errado quando uma das duas
coisas falha.** O pacote é o `os`, o trabalho mora em `~/files`, criado com
`go mod init example.com/files`, e o primeiro programa faz as três coisas que quase todo programa
faz com um arquivo: escrever, acrescentar e ler de volta. Salvo como `notes.go`:

```go
// Command notes writes a file, adds to it, and reads it back.
package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
)

func main() {
	if err := os.WriteFile("notes.txt", []byte("first line\n"), 0o644); err != nil {
		fmt.Println("write:", err)
		return
	}

	f, err := os.OpenFile("notes.txt", os.O_APPEND|os.O_WRONLY, 0)
	if err != nil {
		fmt.Println("open:", err)
		return
	}
	fmt.Fprintln(f, "second line, appended")
	if err := f.Close(); err != nil {
		fmt.Println("close:", err)
		return
	}

	data, err := os.ReadFile("notes.txt")
	if err != nil {
		fmt.Println("read:", err)
		return
	}
	fmt.Printf("%d bytes:\n%s", len(data), data)

	_, err = os.ReadFile("missing.txt")
	fmt.Println("missing:", err)
	fmt.Println("does not exist:", errors.Is(err, fs.ErrNotExist))
}
```

```
ana@vm:~/files$ go run notes.go
33 bytes:
first line
second line, appended
missing: open missing.txt: no such file or directory
does not exist: true
ana@vm:~/files$ ls -l notes.txt
-rw-r--r-- 1 ana ana 33 Oct 16 19:44 notes.txt
ana@vm:~/files$ umask
0022
```

## Três portas de entrada

**`os.WriteFile` e `os.ReadFile` são os atalhos de arquivo inteiro**: uma chamada escreve um slice
num arquivo, criando-o ou esvaziando-o antes, e uma chamada lê um arquivo para um slice. Servem para
tudo o que cabe com folga na memória, o que, para um arquivo de configuração ou um relatório
pequeno, é tudo.

**`os.OpenFile` é a porta geral**, e as flags dizem de que tipo. `os.O_APPEND|os.O_WRONLY` abre para
escrever no fim, então a segunda linha foi depois da primeira em vez de por cima dela. `os.Open` é o
`OpenFile` só para leitura, e `os.Create` é o `OpenFile` para escrita que cria o arquivo ou esvazia
um existente. Seja quem for que abriu o arquivo, `fmt.Fprintln(f, …)` escreveu nele, porque `f` é um
`io.Writer`, e um `io.Copy` ou um `json.Encoder` teriam feito o mesmo.

**O `Close` depois da escrita tem o erro conferido, e isso é de propósito.** Alguns sistemas só
informam uma escrita que falhou quando o arquivo é fechado, então um programa que escreve e depois
ignora o erro do `Close` pode perder dados sem uma palavra. Para um arquivo só lido, um
`defer f.Close()` simples basta, já que nada espera para ser escrito.

## Permissões, e quem as apara

`0o644` pediu leitura e escrita para o dono e leitura para todos os outros, e o `ls -l` mostra
exatamente isso, `-rw-r--r--`. O número é um pedido, não uma ordem: a **umask** do processo, `0022`
aqui, tira bits de todo arquivo que ele cria. Um programa que pedisse `0o666` nesta máquina ainda
receberia `-rw-r--r--`. Peça o que você quer dizer, e não se surpreenda quando uma umask mais rígida
der menos.

## O erro diz o quê e onde

O arquivo que faltava produziu `open missing.txt: no such file or directory`: a operação, o
caminho e o motivo vindo do sistema operacional, que é o formato de todo erro do `os`. **Para
decidir o que fazer com um erro, teste-o com `errors.Is` contra um valor de `io/fs`**, e não lendo o
texto: `fs.ErrNotExist` aqui, `fs.ErrPermission` para um arquivo que você não pode abrir,
`fs.ErrExist` para um que você pediu para criar só se fosse novo. O texto é para pessoas; o
`errors.Is` é para programas, como a lição 34 de `go` mostrou para erros em geral.
