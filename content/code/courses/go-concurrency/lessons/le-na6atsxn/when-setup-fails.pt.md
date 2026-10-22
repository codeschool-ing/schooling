---
title: Quando a instalação falha
version: 1
---

A lição 3 de `go` cobre as falhas do próprio Go: `go: command not found`, um `go.mod` pedindo uma
versão mais nova, um proxy de módulos inalcançável. Esta seção cobre as que este curso acrescenta,
e todas se resumem ao compilador de C. **Cada uma tem uma causa, e a mensagem diz qual é.** A máquina
do laboratório tem `gcc`, então, para mostrar o que diz uma máquina sem ele, os comandos abaixo dão
ao shell um `PATH` só com o diretório do próprio Go. O comando go procura o `gcc` ali, não acha
nada, e se comporta exatamente como numa máquina onde o `gcc` nunca foi instalado.

## `-race requires cgo`

```
ana@vm:~/promise$ PATH=/usr/local/go/bin go env CGO_ENABLED
0
ana@vm:~/promise$ PATH=/usr/local/go/bin go run -race count.go; echo $?
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
```

**A primeira linha é o diagnóstico e a segunda é o sintoma.** Sem compilador de C à vista, o
comando go desliga o cgo sozinho, `CGO_ENABLED` vale `0`, e o detector de corridas, que precisa do
cgo, se recusa antes de compilar qualquer coisa. Tudo o que não usa `-race` continua funcionando, e
é por isso que essa falha costuma aparecer no primeiro dia em que alguém pede o detector.

A mensagem sugere definir `CGO_ENABLED=1`. Numa máquina sem compilador isso só leva a falha um passo
adiante:

```
ana@vm:~/promise$ PATH=/usr/local/go/bin CGO_ENABLED=1 go run -race count.go; echo $?
# runtime/cgo
cgo: C compiler "gcc" not found: exec: "gcc": executable file not found in $PATH
1
```

Agora o comando go tentou compilar a metade em C do runtime e deu o nome do programa que não
encontrou. **O conserto das duas é o da seção 02, `sudo apt install gcc`**, e depois dele
`go env CGO_ENABLED` imprime `1` sem que ninguém o defina.

## A mesma mensagem numa máquina que tem `gcc`

A recusa também aparece onde há compilador instalado, porque `CGO_ENABLED` foi definido como `0` à
mão em algum lugar:

```
ana@vm:~/promise$ CGO_ENABLED=0 go run -race count.go; echo $?
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
```

É uma configuração comum, porque um programa compilado com o cgo desligado é totalmente estático e
pode ser copiado para qualquer máquina Linux, e muitos scripts de build e receitas de contêiner a
definem por esse motivo. Ela pode estar no ambiente do seu shell, no `~/.profile` ou no arquivo do
próprio comando go, escrito por `go env -w`. `go env -changed` lista toda configuração diferente do
padrão, venha de onde vier, como a lição 3 de `go` mostrou; `go env -u CGO_ENABLED` a tira do
arquivo do comando go, e `unset CGO_ENABLED` a tira do shell.

## Uma conferência curta, antes de pedir ajuda

Cinco comandos respondem à maioria das perguntas sobre o laboratório deste curso:

1. `go version`: `go1.27.1`, e nenhuma outra versão.
2. `command -v go gcc`: que arquivos são esses, e que os dois existem.
3. `go env CGO_ENABLED CC`: `1` e `gcc`.
4. `go env -changed`: qualquer coisa que alguém definiu, em qualquer dos três lugares.
5. `go run -race order.go`, com o programa da seção 02: três saudações, em qualquer ordem.
