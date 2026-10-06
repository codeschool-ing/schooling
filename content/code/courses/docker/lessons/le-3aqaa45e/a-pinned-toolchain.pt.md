---
title: O mesmo Go em todo lugar
version: 1
---

**"Na minha máquina passa" é a versão em testes do problema da aula 1.** Os testes rodaram contra o
compilador, as bibliotecas e as ferramentas que aquela máquina tinha, e o pipeline tem outros. Rodar
os testes na mesma imagem em todo lugar acaba com a diferença, e a máquina da Ana, que não tem Go
nenhum, mostra isso sem ruído:

```
ana@vm:~/shelf$ docker run --rm -v "$PWD":/src -w /src golang:1.25 go version
go version go1.25.14 linux/amd64
ana@vm:~/shelf$ docker run --rm -v "$PWD":/src -w /src golang:1.25 go test ./...
ok  	example.com/shelf	0.005s
?   	example.com/shelf/probe	[no test files]
ana@vm:~/shelf$ docker run --rm -v "$PWD":/src -w /src golang:1.25 go test -race -count=1 ./...
ok  	example.com/shelf	1.019s
?   	example.com/shelf/probe	[no test files]
```

**A `golang:1.25` traz o Go 1.25.14, e esse é o Go que toda execução usa**, na máquina da Ana, na de um
colega e no pipeline, até alguém mudar a tag. O código é montado, como na aula 24, então nada é
construído numa imagem. O `-race` liga o detector de condições de corrida do Go, que precisa de um
toolchain de C que a imagem `golang` já tem; num notebook é mais uma coisa para instalar, e aqui não é.

O `-count=1` impede o Go de reaproveitar um resultado em cache, o que importa quando um teste conversa
com algo fora do programa, como o teste de integração mais adiante nesta aula.
