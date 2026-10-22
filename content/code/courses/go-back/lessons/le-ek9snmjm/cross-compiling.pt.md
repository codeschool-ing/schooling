---
title: Compilando para uma máquina em que você não está
version: 1
---

**O toolchain do Go gera um binário para qualquer sistema operacional e processador que ele suporta, a
partir de qualquer um deles**, sem nada instalado além do próprio Go. Duas variáveis de ambiente escolhem o
alvo: `GOOS`, o sistema operacional, e `GOARCH`, o processador. Sem elas, o `go build` gera para a máquina
em que roda:

```
ana@vm:~/boxoffice$ go env GOOS GOARCH; go tool dist list | wc -l
linux
amd64
47
```

Linux em `amd64`, os processadores Intel e AMD de 64 bits, e 47 pares para os quais o toolchain sabe
gerar. Quatro deles cobrem quase toda máquina que o boxoffice poderia encontrar: Linux em `amd64` e em
`arm64`, o processador da maioria dos servidores de nuvem vendidos como mais baratos, e do Raspberry Pi;
macOS em `arm64`, os chips da Apple; e Windows em `amd64`:

```
ana@vm:~/boxoffice$ for t in linux/amd64 linux/arm64 darwin/arm64 windows/amd64; do GOOS=${t%/*} GOARCH=${t#*/} go build -o dist/try-${t%/*}-${t#*/} . || exit; done; ls -l dist
total 100140
-rwxr-xr-x 1 ana ana 25418370 Oct 22 20:01 try-darwin-arm64
-rwxr-xr-x 1 ana ana 26168752 Oct 22 20:01 try-linux-amd64
-rwxr-xr-x 1 ana ana 24540414 Oct 22 20:01 try-linux-arm64
-rwxr-xr-x 1 ana ana 26407424 Oct 22 20:01 try-windows-amd64
ana@vm:~/boxoffice$ file dist/try-*
dist/try-darwin-arm64:  Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
dist/try-linux-amd64:   ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=dJxaNngpzGzpUm-DDWZl/Qb7CJdNknL3lITZ-g_dF/KGnFNDlvctMs6BtkzrAK/liQSlGq4CaBtIcr7_ECG, BuildID[sha1]=2bdb6128f70bc35840b48c0dba78fb803da39d1b, with debug_info, not stripped
dist/try-linux-arm64:   ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, Go BuildID=JALTTkBmDID4ij3wT60n/wXdH1Pis8-Zir6UrxfDC/G6u52ErfxVV0NTt9Rihn/PdGufm5b-B-pwUDpyLYe, BuildID[sha1]=1645a1a6d6de0958ddf8879f32130a8dc859aa05, with debug_info, not stripped
dist/try-windows-amd64: PE32+ executable (console) x86-64, for MS Windows, 16 sections
```

Quatro binários de uns 25 MB cada, a partir de uma máquina, num laço. O `file` lê o cabeçalho de cada um e
concorda com o nome: um executável ELF para cada Linux, um Mach-O para o macOS, um PE32+ para o Windows.
Nada aqui foi emulado nem instalado para os outros alvos; o compilador e a biblioteca padrão sabem produzir
cada formato.

**Olhe de novo as duas linhas do Linux.** O binário `arm64` é `statically linked`. O `amd64`, gerado para
esta mesma máquina, é `dynamically linked`, com um interpretador, `/lib64/ld-linux-x86-64.so.2`. O mesmo
código, gerado de dois jeitos, e a diferença decide se o binário vai rodar na imagem da seção 06. A
próxima seção explica por quê.
