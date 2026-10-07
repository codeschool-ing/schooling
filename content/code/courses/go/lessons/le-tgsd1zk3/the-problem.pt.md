---
title: O problema para o qual Go foi feito
version: 1
---

"Go é rápido" é a primeira coisa que quase todo mundo ouve sobre a linguagem, e entende que os
programas em Go rodam rápido. Rodam, mas **a velocidade que os projetistas quiseram resolver
primeiro foi a do build.** Go começou no Google em 2007 como resposta a três problemas de escrever
software de servidor ali: builds que demoravam demais, dependências que ninguém conseguia
acompanhar e máquinas que tinham deixado para trás as linguagens que as programavam.

## Builds medidos em minutos

Rob Pike, um dos três projetistas, deu os números numa palestra na conferência SPLASH em 2012,
*Go at Google: Language Design in the Service of Software Engineering*. Em 2007 os engenheiros de
build do Google instrumentaram a compilação de um programa grande em C++. O código-fonte tinha cerca
de dois mil arquivos, 4,2 megabytes postos um atrás do outro. Depois de expandido cada `#include`,
o compilador lia mais de 8 gigabytes: **2.000 bytes de entrada para cada byte de código-fonte.**
Esse programa levava 45 minutos para compilar, num sistema de build que espalhava o trabalho por
muitas máquinas.

Esses números são da palestra, e nada neste laboratório compila o C++ do Google. O que o laboratório
consegue medir é o outro lado da comparação. O comando go é ele mesmo um programa Go, e o código dele
vem com toda instalação de Go, então dá para compilá-lo do zero:

```
ana@vm:~/why$ nproc
4
ana@vm:~/why$ go list -deps cmd/go | wc -l
334
ana@vm:~/why$ go clean -cache
ana@vm:~/why$ time go build -o /dev/null cmd/go

real	0m21.332s
user	0m57.345s
sys	0m11.351s
ana@vm:~/why$ time go build -o /dev/null cmd/go

real	0m0.837s
user	0m1.115s
sys	0m0.250s
```

O `go list -deps` lista cada pacote de que o comando go é feito, os da biblioteca padrão inclusive,
e são 334. O `go clean -cache` esvazia o cache de build da lição 4, então o primeiro build compila
todos eles, numa máquina virtual com quatro processadores, em 21,332 segundos. O `-o /dev/null`
joga o resultado fora, porque aqui só o tempo importa. O segundo build achou todos os pacotes já no
cache e levou 0,837 segundo.

**`user` é maior que `real` porque o comando go compila pacotes independentes ao mesmo tempo**, um
por processador. É o segundo problema aparecendo na resposta ao primeiro.

## Dependências que o compilador enxerga

Em C e C++ um arquivo diz do que precisa com `#include`, que cola dentro dele o texto de outro
arquivo. Um include de que ninguém precisa mais continua sendo colado e compilado, em todo build, e
nada avisa que ele poderia sair. Multiplique isso por dois mil arquivos e você chega aos 8 gigabytes.

Go fez da dependência uma parte da linguagem. Um `import` nomeia um pacote, e não um arquivo para
colar, e **um import que o arquivo não usa é erro de compilação**: a lição 4 mostra o compilador
recusando `"os" imported and not used`. Assim a lista do que um programa Go usa é exata por
construção. A palestra de 2012 acrescenta a outra metade. Quando o compilador encontra `import "B"`,
ele abre um arquivo, a forma compilada de `B`, que já traz tudo o que um usuário de `B` precisa
saber das dependências do próprio `B`. Nada é lido duas vezes.

## Muitos processadores, e a rede

O terceiro problema eram as máquinas. Um servidor do Google em 2007 tinha vários processadores e
passava o dia respondendo a outras máquinas, e a palestra diz isso com todas as letras: C, C++ e,
em certa medida, Java foram projetadas antes de máquinas multicore, redes e aplicações web serem o
normal.

Go pôs a concorrência na linguagem, e não numa biblioteca. **A palavra-chave `go` põe uma função
para rodar ao lado do resto do programa**, e `chan` declara um canal pelo qual duas delas conversam.
As duas estão entre as 25 palavras-chave que a seção 04 conta. Usá-las bem é o assunto do curso
`go-concurrency`; este curso ensina a linguagem sobre a qual elas são construídas.

## Quem, e quando

Segundo o FAQ do próprio projeto Go, Robert Griesemer, Rob Pike e Ken Thompson começaram a rascunhar
os objetivos de uma linguagem nova num quadro branco em 21 de setembro de 2007. No começo era um
projeto de meio período, em meados de 2008 já era de tempo integral, e **Go virou um projeto
público, de código aberto, em 10 de novembro de 2009.** A lição 2 continua a história dali até o
go1.27.1 que este laboratório roda.
