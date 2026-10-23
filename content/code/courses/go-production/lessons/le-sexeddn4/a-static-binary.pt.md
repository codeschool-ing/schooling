---
title: Um binário que não precisa de nada
version: 1
---

"Binário Go é sempre estático" é meia verdade, e a metade falsa é justamente a que quebra uma
imagem. **Um binário é estático quando nada nele pede a biblioteca C**, e se algo pede ou não
depende dos pacotes que ele importa e de o cgo estar ligado. O `hits` por acaso não precisa de
nada. Um programa que consulta quem o está rodando pode precisar de bastante coisa, sem uma linha
de C dentro.

Esta lição trabalha em `~/ship`, com os quatro arquivos do `hits` colocados ali a partir da lição
1, `go mod init example.com/hits` e o mesmo `access.log` de 20.000 linhas do `genlog -n 20000`.

## O hits não precisa de nada

Compilado do jeito simples, com o cgo ligado porque esta máquina tem `gcc`:

```
ana@vm:~/ship$ go build -o hits . && file hits | cut -d, -f1,4
hits: ELF 64-bit LSB executable, statically linked
ana@vm:~/ship$ ldd hits
	not a dynamic executable
ana@vm:~/ship$ go list -deps . | grep -x runtime/cgo; echo $?
1
```

**`statically linked` quer dizer que o arquivo contém cada instrução que vai executar**, e o `ldd`,
que lista as bibliotecas compartilhadas que um programa vai carregar, não acha nada para listar. O
`go list -deps` mostra cada pacote que o build compila, e o `runtime/cgo`, o pacote de que um
binário precisa para chamar C, não está entre eles: o `grep` não achou nada e avisou com 1. Nada do
que o `tally` e o `main.go` importam tem implementação em C, então o `CGO_ENABLED=1` não tinha o
que ligar.

## Um programa que precisa de algo

O `probe` é um segundo programa pequeno, sem ligação com o `hits`, que faz três perguntas cujas
respostas moram em arquivos fora do programa. É um módulo próprio em `~/ship/probe`, criado com
`go mod init example.com/probe`. Salve como `probe/main.go`:

```schooling-example
{
  "language": "go",
  "file": "probe/main.go",
  "parts": [
    {
      "code": "// Command probe asks three questions that a Go program answers from files\n// the system provides: who is running it, what time it is in Sao Paulo,\n// and which certificate authorities it trusts.\npackage main\n\nimport (\n\t\"crypto/x509\"\n\t\"fmt\"\n\t\"os/user\"\n\t\"time\"\n)\n",
      "note": "Só a biblioteca padrão. **Cada pergunta é respondida lendo um arquivo que o programa não leva consigo**, o que faz do programa um teste de qualquer sistema em que ele caia."
    },
    {
      "code": "func main() {\n\tif u, err := user.Current(); err != nil {\n\t\tfmt.Println(\"user: \", err)\n\t} else {\n\t\tfmt.Println(\"user: \", u.Username, u.Uid, u.HomeDir)\n\t}\n",
      "note": "O `user.Current` tem as duas implementações que a lição 16 mostrou para o `os/user`. Com cgo, ele pergunta à biblioteca C; sem cgo, lê o `/etc/passwd` sozinho."
    },
    {
      "code": "\tif loc, err := time.LoadLocation(\"America/Sao_Paulo\"); err != nil {\n\t\tfmt.Println(\"zone: \", err)\n\t} else {\n\t\tnoon := time.Date(2026, 10, 1, 12, 0, 0, 0, time.UTC)\n\t\tfmt.Println(\"zone: \", noon.In(loc).Format(\"15:04 MST\"))\n\t}\n",
      "note": "O `time.LoadLocation` lê as regras do fuso em `/usr/share/zoneinfo`. Um instante fixo, meio-dia UTC de 1º de outubro de 2026, deixa a resposta igual em toda execução."
    },
    {
      "code": "\t// On Linux the pool holds the system's roots, so Subjects counts them.\n\t// It is deprecated because that is not true on every system.\n\tif pool, err := x509.SystemCertPool(); err != nil {\n\t\tfmt.Println(\"certs:\", err)\n\t} else {\n\t\tfmt.Println(\"certs:\", len(pool.Subjects()), \"authorities\")\n\t}\n}",
      "note": "O `x509.SystemCertPool` carrega as autoridades em que um cliente TLS confia, de `/etc/ssl/certs/ca-certificates.crt` no Ubuntu. Sem elas, um cliente não tem contra o que conferir o certificado de um servidor."
    }
  ]
}
```

Compilado do mesmo jeito que o `hits`:

```
ana@vm:~/ship/probe$ go build -o probe . && file probe | cut -d, -f1,4
probe: ELF 64-bit LSB executable, dynamically linked
ana@vm:~/ship/probe$ ldd probe | cut -d" " -f1
	linux-vdso.so.1
	libc.so.6
	/lib64/ld-linux-x86-64.so.2
ana@vm:~/ship/probe$ go list -deps . | grep -x runtime/cgo
runtime/cgo
ana@vm:~/ship/probe$ ./probe
user:  ana 30033 /home/ana
zone:  09:00 -03
certs: 127 authorities
```

**O `os/user` trouxe o cgo, e o cgo fez o binário depender de dois arquivos desta máquina.** A
`libc.so.6` é a biblioteca C, e o `/lib64/ld-linux-x86-64.so.2` é o carregador dinâmico, o
programa que o kernel inicia primeiro para que ele encontre a `libc.so.6` e a junte ao `probe`
antes de `main` rodar. A `linux-vdso.so.1` é fornecida pelo próprio kernel e não é arquivo em
lugar nenhum. As três respostas estão certas: a conta da Ana, São Paulo três horas atrás do UTC e
127 autoridades no pacote do Ubuntu.

O mesmo código com o cgo desligado:

```
ana@vm:~/ship/probe$ CGO_ENABLED=0 go build -o probe . && file probe | cut -d, -f1,4
probe: ELF 64-bit LSB executable, statically linked
ana@vm:~/ship/probe$ ldd probe; ./probe
	not a dynamic executable
user:  ana 30033 /home/ana
zone:  09:00 -03
certs: 127 authorities
```

Estático de novo, e as mesmas três respostas, porque o `os/user` passou a ler o `/etc/passwd`
sozinho. **O `CGO_ENABLED=0` tirou a dependência da biblioteca C e do carregador; não tirou a
dependência do `/etc/passwd`, do `/usr/share/zoneinfo` nem do pacote de certificados.** Isso são
dados, e um binário estático lê dados da máquina como qualquer outro programa. A seção 04 põe o
`probe` em duas imagens e observa quais desses arquivos estão lá.

## Por que um contêiner quer o estático

Uma imagem de contêiner leva os próprios arquivos e nada da máquina em que roda. A imagem que a
seção 03 constrói não tem biblioteca C nem carregador, então um binário ligado dinamicamente lá
dentro pede ao kernel o `/lib64/ld-linux-x86-64.so.2`, e o kernel não acha esse arquivo. A seção 04
mostra a mensagem, e ela aponta o arquivo errado. **Um binário estático não tem essa pergunta a
fazer**, e por isso todo build de release desta lição começa com `CGO_ENABLED=0`, como o
`release.sh` da lição 16 já fazia para todos os alvos.

O build de release do `hits` acrescenta as duas flags que a lição 17 destrinchou:

```
ana@vm:~/ship$ CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o hits . && stat -c "%s bytes  %n" hits
2650272 bytes  hits
ana@vm:~/ship$ file hits | cut -d, -f1,4; ./hits top -n 1 access.log
hits: ELF 64-bit LSB executable, statically linked
path    requests
/login  2576
```

**2.650.272 bytes, contra os 4.031.903 do build simples da lição 1**, e a mesma resposta para a
mesma pergunta. O `-s -w` deixa de fora a tabela de símbolos e a informação de depuração. O
`-trimpath` troca os diretórios desta máquina, `/home/ana/ship` entre eles, por caminhos de módulo
dentro do binário, e é isso que torna possível a comparação de dois builds da seção 05. Este é o
arquivo que a imagem entrega.
