---
title: Rodando o binário ARM numa máquina Intel
version: 1
---

Um binário feito para outro processador é um arquivo de instruções que este processador não tem.
**Compilá-lo prova só que ele compilou**; se ele conta o log direito é uma afirmação que alguém
precisa conferir, e o lugar óbvio para conferir é uma máquina daquele tipo. Quando não há nenhuma à
mão, um emulador faz o serviço: o modo de usuário do QEMU traduz as instruções ARM de um programa
para as da máquina enquanto ele roda e repassa as chamadas de sistema ao kernel Linux por baixo.

## O kernel recusa, o emulador roda

O Ubuntu empacota os emuladores como `qemu-user-static`, um programa por processador. A máquina do
laboratório já os tinha, então esta linha **não foi rodada aqui**:

```sh
sudo apt install qemu-user-static
```

Pedido para rodar o build `arm64` direto, o kernel olha o cabeçalho do arquivo, vê um processador
que ele não opera e recusa. Entregue ao `qemu-aarch64-static`, o mesmo arquivo roda:

```
ana@vm:~/cross$ ./hits-arm64 count access.log; echo $?
bash: line 1: ./hits-arm64: cannot execute binary file: Exec format error
126
ana@vm:~/cross$ qemu-aarch64-static ./hits-arm64 count access.log
status  requests
200     7554
201     1256
204     1248
301     1192
304     1229
400     1223
401     1226
404     2549
500     1269
503     1254
```

**O status 126 é o código do shell para "achei, mas não consigo executar"**, vizinho do 127 da lição
1, que quer dizer não encontrado. `Exec format error` é como o kernel chama um arquivo num formato
que ele não sabe carregar. Algumas máquinas têm o emulador registrado no kernel, por um mecanismo
chamado `binfmt_misc`, e ali a execução direta funciona porque o próprio kernel entrega o arquivo ao
QEMU. Esta não tem, então toda execução ARM desta lição cita o emulador pelo nome.

A tabela é a da lição 1, **7.554 requisições com status `200`** e o resto até o último dígito. Uma
tabela conferida a olho é uma comparação fraca, então aqui vai uma forte: `diff` entre o binário
nativo e o emulado, numa saída mais longa.

```
ana@vm:~/cross$ diff <(./hits top -n 8 access.log) <(qemu-aarch64-static ./hits-arm64 top -n 8 access.log) && echo identical
identical
```

`<(command)` é o shell rodando um comando e passando a saída ao `diff` como se fosse um arquivo. O
`diff` não imprimiu diferença e saiu com 0, então o `echo` rodou. Dois programas compilados para
dois processadores a partir de um código leram as mesmas 20.000 linhas e concordaram em todas as
linhas da saída.

## O binário diz para que foi feito

Um binário Go carrega um registro de como foi compilado. O `go version -m` o lê sem executar o
arquivo, o que importa para um binário que esta máquina não roda:

```
ana@vm:~/cross$ go version -m hits-arm64
hits-arm64: go1.27.1
	path	example.com/hits
	mod	example.com/hits	(devel)	
	build	-buildmode=exe
	build	-compiler=gc
	build	CGO_ENABLED=0
	build	GOARCH=arm64
	build	GOOS=linux
	build	GOARM64=v8.0
```

**`GOOS`, `GOARCH` e a versão do Go estão todos ali**, e também duas configurações que ninguém
digitou. `CGO_ENABLED=0` é escolha do próprio comando go num build cruzado, que a seção 04
destrincha. `GOARM64=v8.0` é o processador ARM de 64 bits mais antigo que o código pode supor, o
padrão; a seção 04 mostra o equivalente na Intel. Quando alguém lhe entrega um binário e pergunta
para qual máquina ele é, este é o comando que responde.

## Rodando os testes no outro processador

O `go test` compila um binário de teste e o executa, então com `GOARCH=arm64` ele compila um binário
de teste ARM e depois não consegue iniciá-lo, pelo motivo acima. A flag `-exec` indica um programa
pelo qual rodar o binário de teste, e o QEMU é um programa desses:

```
ana@vm:~/cross$ GOARCH=arm64 go test -count=1 .
fork/exec /tmp/go-build4148814532/b001/hits.test: exec format error
FAIL	example.com/hits	0.000s
FAIL
ana@vm:~/cross$ GOARCH=arm64 go test -count=1 -exec qemu-aarch64-static .
ok  	example.com/hits	0.167s
```

**O teste de tabela da lição 1 passou num processador ARM emulado**, linha por linha. O `-count=1`
impede o comando go de responder com um resultado do cache, então as duas linhas são execuções. Os
0,167 segundos contra os 0,003 da execução nativa da lição 1 são o preço de traduzir cada instrução.
Numa máquina ARM de verdade os testes rodam em velocidade normal, e um sistema de CI com um runner
ARM é onde um projeto que distribui binários ARM os executa.

## O que não deu para rodar aqui

Os builds de macOS e Windows da seção 02 foram **compilados e não executados**. O modo de usuário do
QEMU emula um processador para um programa Linux; ele não faz as vezes de macOS nem de Windows,
cujas chamadas de sistema são outras. `file` e `go version -m` são o que esta lição pode dizer sobre
eles: o formato certo, o processador certo, as configurações certas. Experimentá-los num Mac e numa
máquina Windows fica para quem tiver uma, e para o `hits`, que lê um arquivo e escreve texto, resta
pouca coisa específica de sistema para dar errado.
