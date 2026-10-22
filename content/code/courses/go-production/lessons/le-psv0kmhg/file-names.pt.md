---
title: Restrições escritas no nome do arquivo
version: 1
---

O `progress_darwin.go` da seção 02 não tem linha `//go:build`, e é compilado para macOS e para nada
mais. **Um arquivo cujo nome termina num sistema operacional ou num processador carrega uma
restrição no nome**, como se a linha estivesse lá. A regra é mecânica, e conhecê-la com exatidão
importa, porque um nome que quase a segue é um arquivo comum que todo build compila.

## Os três padrões

Pegue o nome, tire o `.go` e tire um `_test` no fim, se houver. Se o que sobra termina num destes,
o arquivo tem uma restrição implícita:

| o nome termina em | exemplo | compilado quando |
|---|---|---|
| `_GOOS` | `progress_darwin.go` | o sistema de destino é `darwin` |
| `_GOARCH` | `crc32_arm64.go` | o processador de destino é `arm64` |
| `_GOOS_GOARCH` | `zerrors_linux_amd64.go` | as duas coisas valem |

**`GOOS` e `GOARCH` representam qualquer valor que o toolchain conhece**: os 47 pares que
`go tool dist list` imprime, e a aula 16 lista os dos três sistemas mais comuns. Um sufixo `_test`
sai primeiro, então `progress_darwin_test.go` guarda testes que só rodam no macOS. **Um nome e uma
linha `//go:build` se combinam com "e"**: um arquivo chamado `progress_darwin.go` que também diga
`//go:build !darwin` não é compilado por build nenhum.

O `go list` mostra quais arquivos um pacote compila para um alvo. `{{.GoFiles}}` é a lista que ele
compila e `{{.IgnoredGoFiles}}` a lista que ele deixa de fora por causa de uma restrição:

```
ana@vm:~/tags$ go list -f '{{.GoFiles}}' .
[main.go progress.go progress_unix.go]
ana@vm:~/tags$ GOOS=darwin go list -f '{{.GoFiles}}' .
[main.go progress.go progress_darwin.go]
ana@vm:~/tags$ GOOS=windows go list -f '{{.GoFiles}} {{.IgnoredGoFiles}}' .
[main.go progress.go progress_other.go] [progress_darwin.go progress_unix.go]
```

Cada alvo compilou `main.go`, `progress.go` e exatamente um dos três arquivos por sistema. Para
macOS é o `progress_darwin.go`, escolhido só pelo nome. Para Windows os dois deixados de fora
aparecem na segunda lista, um pelo nome e outro pela linha `//go:build unix && !darwin`. O `go list`
informa os dois do mesmo jeito, porque para o comando go eles são o mesmo tipo de regra.

## Um nome que quase segue a regra

O sufixo precisa ser um valor que o toolchain conhece. **`mac` não é um deles**, nem `osx` nem
`win`, então um arquivo chamado `progress_mac.go` não carrega restrição nenhuma e é compilado para
todo alvo, inclusive o Linux:

```
ana@vm:~/tags$ cp progress_darwin.go progress_mac.go; go vet .; rm progress_mac.go
# example.com/hits
# [example.com/hits]
vet: ./progress_unix.go:11:5: progressSignals redeclared in this block
```

A cópia definiu `progressSignals` uma segunda vez no build para Linux, e o vet parou ali. Ele ia
reclamar em seguida que `syscall.SIGINFO` não existe no Linux, que é o problema de verdade. **Um
sufixo que o comando go não reconhece não é regra nenhuma**, e o erro que aparece é sobre aquilo com
que o arquivo calhou de colidir.

Vale reconhecer mais dois quase acertos. **O sufixo precisa vir depois de um sublinhado e no fim
do nome.** Um arquivo chamado só `linux.go` não é restrito, e `linux_progress.go` também não. Um arquivo cujo nome começa com `_` ou `.` é outro caso: o comando go o ignora por completo,
em todo build, e ele não aparece em nenhuma das duas listas.

## A biblioteca padrão é escrita assim

Nomes são o jeito como a biblioteca padrão carrega código para 47 alvos. No `syscall`, as constantes
e os números das chamadas de sistema são gerados por sistema e por processador, um arquivo cada:

```
ana@vm:~/tags$ go list -f '{{join .GoFiles "\n"}}' syscall | grep _linux_
syscall_linux_amd64.go
zerrors_linux_amd64.go
zsyscall_linux_amd64.go
zsysnum_linux_amd64.go
ztypes_linux_amd64.go
ana@vm:~/tags$ GOARCH=arm64 go list -f '{{join .GoFiles "\n"}}' syscall | grep _linux_
syscall_linux_arm64.go
zerrors_linux_arm64.go
zsyscall_linux_arm64.go
zsysnum_linux_arm64.go
ztypes_linux_arm64.go
```

**Trocar o `GOARCH` trocou cinco arquivos por outros cinco**, cada um com o mesmo nome e `arm64` no
lugar de `amd64`. `{{join .GoFiles "\n"}}` imprime a lista com um nome por linha, para o `grep`
poder separar os de Linux. Uma contagem mostra quanto de um pacote portável é por sistema:

```
ana@vm:~/tags$ for os in linux darwin windows; do echo "$os: $(GOOS=$os go list -f '{{len .GoFiles}} files, {{len .IgnoredGoFiles}} left out' os)"; done
linux: 45 files, 87 left out
darwin: 44 files, 92 left out
windows: 34 files, 105 left out
```

O `os` tem 119 arquivos que não são de teste, e **um build compila cerca de um terço
deles**: 45 para Linux, 44 para macOS, 34 para Windows. O resto são as versões de outros sistemas
das mesmas funções. O número de "left out" é maior que 119 menos o primeiro porque conta também
arquivos de teste escritos para um sistema só, que o `go list` informa na mesma lista.

## Um nome, uma linha ou um `switch`

Três ferramentas, cada uma com seu lugar:

- **Um nome**, quando o arquivo é de exatamente um sistema, um processador ou um par. Ele aparece no
  `ls`, que é onde as pessoas olham primeiro.
- **Uma linha `//go:build`**, para tudo o que um nome não consegue dizer: `unix && !darwin`,
  `!unix`, `cgo`, uma tag de versão ou uma tag sua.
- **Um `if` ou um `switch` em `runtime.GOOS`**, quando todo ramo compila em todo lugar e só o
  comportamento muda. O `os.UserConfigDir` da biblioteca padrão é um `switch runtime.GOOS` que
  escolhe `%AppData%` no Windows e `~/Library/Application Support` no macOS: strings simples, que
  compilam em qualquer sistema.

O `progressSignals` precisou de arquivos, porque `syscall.SIGINFO` e `syscall.SIGUSR1` não existem
em todo sistema. Uma mensagem como "press Ctrl-T" poderia ter sido um `switch`, já que uma string
compila em qualquer lugar.
