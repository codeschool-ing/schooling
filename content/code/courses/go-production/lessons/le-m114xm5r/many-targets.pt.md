---
title: Todos os alvos num comando só
version: 1
---

Quatro builds digitados à mão bastaram para ver como funciona a compilação cruzada. **Uma versão é
sempre os mesmos builds, com os mesmos nomes**, e isso é trabalho para um script. Quem digita seis
comandos um dia digita cinco, ou chama um binário de `hits-mac` e o seguinte de `hits-darwin`. Quem
baixa de uma página de versões lê o nome para escolher o arquivo, então o nome precisa dizer o
sistema e o processador nas palavras que o Go usa: `hits-<os>-<arch>`, com `.exe` no Windows.

## O script

`release.sh`, na raiz de `~/cross`, ao lado do `go.mod`:

```schooling-example
{
  "language": "sh",
  "file": "release.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# release.sh builds hits for each target below, into release/.\nset -eu\n",
      "note": "Um script de shell POSIX simples, então roda com `sh` no Linux e no macOS. **O `set -eu` o para no primeiro comando que falha** e na primeira variável usada sem valor, então um build que quebra para um alvo interrompe a versão em vez de deixar um diretório com um buraco."
    },
    {
      "code": "targets=\"linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64 windows/arm64\"\n",
      "note": "Os pares a compilar, escritos como o `go tool dist list` os imprime. **Acrescentar um alvo é acrescentar uma palavra.**"
    },
    {
      "code": "rm -rf release\nmkdir release",
      "note": "Cada execução parte de um diretório vazio, para que um alvo tirado da lista não deixe para trás o binário do mês passado, pronto para ser distribuído por engano."
    },
    {
      "code": "for t in $targets; do\n\tos=${t%/*}\n\tarch=${t#*/}\n\text=\n\tif [ \"$os\" = windows ]; then\n\t\text=.exe\n\tfi",
      "note": "`${t%/*}` é a palavra sem tudo o que vem da barra em diante, `linux`; `${t#*/}` é a palavra sem tudo o que vem até a barra, `amd64`. O Windows ganha `.exe`, que o `go build -o` não acrescenta sozinho."
    },
    {
      "code": "\tout=release/hits-$os-$arch$ext\n\tCGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -o \"$out\" .\n\techo \"$out\"\ndone",
      "note": "**`CGO_ENABLED=0` deixa o build nativo igual aos outros cinco.** Sem ele, o binário `linux/amd64` sairia com cgo ligado, porque esta é a máquina dele, e os outros cinco com cgo desligado. O script imprime cada nome à medida que avança, que é o progresso que quem está olhando quer ver."
    }
  ]
}
```

Nada nele é específico de Go além da linha do `go build`, e essa linha é o comando da seção 02 com
as variáveis preenchidas a partir de uma lista. Um `Makefile` com uma regra por alvo é a outra forma
comum e faz o mesmo trabalho; o laço é mais curto, e há um shell em toda máquina que tem Go.

## Um diretório de versão

Executado, e perguntado sobre o que fez:

```
ana@vm:~/cross$ sh release.sh
release/hits-linux-amd64
release/hits-linux-arm64
release/hits-darwin-amd64
release/hits-darwin-arm64
release/hits-windows-amd64.exe
release/hits-windows-arm64.exe
ana@vm:~/cross$ stat -c "%s bytes  %n" release/*
4120704 bytes  release/hits-darwin-amd64
3909762 bytes  release/hits-darwin-arm64
4031863 bytes  release/hits-linux-amd64
3831466 bytes  release/hits-linux-arm64
4217344 bytes  release/hits-windows-amd64.exe
3902464 bytes  release/hits-windows-arm64.exe
ana@vm:~/cross$ file release/* | cut -d, -f1,2
release/hits-darwin-amd64:      Mach-O 64-bit x86_64 executable, flags:<|DYLDLINK|PIE>
release/hits-darwin-arm64:      Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
release/hits-linux-amd64:       ELF 64-bit LSB executable, x86-64
release/hits-linux-arm64:       ELF 64-bit LSB executable, ARM aarch64
release/hits-windows-amd64.exe: PE32+ executable (console) x86-64, for MS Windows
release/hits-windows-arm64.exe: PE32+ executable (console) Aarch64, for MS Windows
```

**Seis binários para três sistemas e dois processadores**, cada um com o nome do lugar onde roda, e
o `file` concorda com todos os nomes. Os tamanhos vão de **3.831.466 bytes** no `linux/arm64` a
**4.217.344** no `windows/amd64`. Os arquivos `linux/arm64` e `darwin/arm64` têm exatamente os
tamanhos que a seção 02 imprimiu, porque são os mesmos builds. A primeira execução do script numa
máquina compila a biblioteca padrão uma vez para cada alvo novo, o que leva visivelmente mais tempo
que as execuções seguintes. O cache de build guarda todos eles, então uma segunda versão é quase só
ligação.

Mais duas conferências, sobre o que o script prometeu:

```
ana@vm:~/cross$ go version -m hits | grep CGO_ENABLED; go version -m release/hits-linux-amd64 | grep CGO_ENABLED
	build	CGO_ENABLED=1
	build	CGO_ENABLED=0
ana@vm:~/cross$ du -sb release
24013603	release
ana@vm:~/cross$ qemu-aarch64-static release/hits-linux-arm64 top -n 1 access.log
path    requests
/login  2576
```

**O binário de um `go build` comum registra `CGO_ENABLED=1`, e o `linux/amd64` da versão registra
`0`.** Para o `hits` a diferença fica só nesse registro, porque nada nele usa cgo e os dois saem
ligados estaticamente. Para um programa como o `who` da seção 04, é a diferença entre um binário
nativo ligado dinamicamente e cinco estáticos. Uma versão em que um arquivo se comporta diferente
dos outros é o tipo de coisa que ninguém percebe até um usuário daquele sistema reclamar. O binário
ARM do diretório de versão continua respondendo como todos os outros builds desta lição.

## Quanto custa o diretório

O `du -sb` põe o diretório em **24.013.603 bytes**, uns 24 MB para uma ferramenta que conta linhas.
Cada binário carrega o runtime do Go, as partes da biblioteca padrão que usa, a tabela de símbolos e
a informação de depuração que o `file` mostra como `with debug_info, not stripped` quando a saída
não é cortada. A lição 17 desmonta isso com as flags de compilador e de linker que removem o que uma
versão não precisa, e a lição 18 põe um binário numa imagem de contêiner mínima e o assina. Este
diretório, feito por um script a partir de uma árvore de código, é o ponto de partida das duas.
