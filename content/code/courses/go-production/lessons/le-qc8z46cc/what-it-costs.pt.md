---
title: O que o unsafe custa, e uma regra para usá-lo
version: 1
---

As seções 03 e 04 esbarraram várias vezes em programas que funcionaram quando não deviam. Um
ponteiro guardado como inteiro ainda leu 404, um cast devolveu um número para bytes que não
existiam, e um mapa contou todas as requisições sob as chaves erradas. **O preço do `unsafe` não é
velocidade nem tamanho; é que o compilador, o sistema de tipos e a maioria das ferramentas deixam de
conseguir avisar que você está errado.** Ele vem em quatro partes.

## Fora da promessa de compatibilidade

A segunda frase do `go doc unsafe` é o primeiro custo: "Packages that import unsafe may be
non-portable and are not protected by the Go 1 compatibility guidelines", pacotes que importam
unsafe podem não ser portáveis e não são protegidos pelas diretrizes de compatibilidade do Go 1. A
promessa do Go é que um programa que compila com uma versão do Go 1 continua compilando, e se
comportando do mesmo jeito, com a seguinte. **Código que depende de como o runtime organiza a
memória saiu dessa promessa**, e o runtime é livre para mudar essa organização em qualquer versão.

A própria biblioteca padrão guarda a evidência. Alcançar uma função não exportada do runtime exige
uma diretiva `//go:linkname`, que o compilador recusa num arquivo que não importa `unsafe`. Quando um
pacote muito usado faz isso, a equipe do Go não consegue mais mudar aquela função sem quebrar o
pacote, então a função ganha um comentário dizendo quem depende dela:

```
ana@vm:~/unsafe$ grep -r "hall of shame" "$(go env GOROOT)/src" --include=*.go | wc -l
182
ana@vm:~/unsafe$ grep -B7 "^func checkptrBase" "$(go env GOROOT)/src/runtime/checkptr.go"
// Notable members of the hall of shame include:
//   - github.com/bytedance/sonic
//
// Do not remove or change the type signature.
// See go.dev/issue/67401.
//
//go:linkname checkptrBase
func checkptrBase(p unsafe.Pointer) uintptr {
```

**182 comentários assim na árvore de código do Go, cada um uma função que não pode mais mudar**,
porque um pacote de fora da biblioteca padrão se ligou a algo que nunca foi oferecido. Um deles é a
função que o próprio checkptr usa para achar onde uma alocação começa, da seção 03.

## Portabilidade: os números pertencem a uma máquina

Os deslocamentos da seção 02 foram medidos em `linux/amd64`. O compilador gera código para outras
arquiteturas, e a lição 16 mostrou como; `GOARCH=386` gera um programa de 32 bits que esta máquina
roda diretamente:

```
ana@vm:~/unsafe$ GOARCH=386 go run ./layout
tally.Entry  size 48  align 4
  Time      offset  0  size 20
  Method    offset 20  size  8
  Path      offset 28  size  8
  Status    offset 36  size  4
  Duration  offset 40  size  8
Loose        size 24  align 4
  Cached    offset  0  size  1
  Bytes     offset  4  size  8
  TLS       offset 12  size  1
  Status    offset 16  size  4
  Retry     offset 20  size  1
Tight        size 16  align 4
  Bytes     offset  0  size  8
  Status    offset  8  size  4
  Cached    offset 12  size  1
  TLS       offset 13  size  1
  Retry     offset 14  size  1
1000000 Loose  24006048 bytes
1000000 Tight  16007168 bytes
```

**Todos os números mudaram, menos o tamanho e os deslocamentos de `Tight`**, que se mantêm porque os
campos dela já estavam em ordem de tamanho. No 386 um ponteiro tem quatro bytes, então uma string
tem 8 e `tally.Entry` tem 48; um `int64` se alinha em 4, então `Loose` desperdiça menos e fica com
24. O `Status` de `tally.Entry` fica no deslocamento 36 aqui e no 56 no amd64. **Um código que
escreveu 56 num cálculo de ponteiro lê os bytes errados no 386**, e compila sem uma palavra nos
dois. Um código que escreveu `unsafe.Offsetof(e.Status)` acerta nos dois, porque o compilador
responde por plataforma: a regra dentro da regra é que um deslocamento ou um tamanho sempre se
pergunta, nunca se digita.

## O peso da revisão

Quem lê Go comum consegue conferir uma função lendo a função. Quem lê código `unsafe` precisa
conferi-lo contra uma lista de seis padrões e suas condições, contra os comentários de documentação
de toda memória que ele empresta, e contra cada chamador, porque a segurança do `zc.String` depende
do que o chamador faz com os bytes enquanto a string existir. **O bug do `paths` na seção 04 não tem
nenhuma linha errada**: o `zc.String` está certo, o `sc.Bytes()` está certo, e o defeito é um ter
sido entregue ao outro. Isso faz de cada chamada de uma função unsafe algo sobre o qual um revisor
precisa raciocinar, para sempre.

## Bugs que não aparecem

| bug desta lição | o que fez ao rodar | o que o encontrou |
|---|---|---|
| um `uintptr` guardado e depois convertido de volta em ponteiro | imprimiu a resposta certa | `go vet` |
| oito bytes lidos onde o registro tinha um | imprimiu um número errado, sem erro | checkptr, `-race` |
| uma string sem cópia usada como chave de mapa sobre um buffer reaproveitado | imprimiu totais plausíveis | nada |

**Nenhum deles quebrou num build comum.** Um programa com erro de tipo não compila; um programa com
erro de índice entra em pânico e cita o índice. Estes imprimem, e o primeiro sintoma é um relatório
errado de um jeito que ninguém consegue rastrear até a causa.

## Onde o unsafe é a ferramenta certa

Nada disso faz do pacote um erro. A biblioteca padrão o usa onde a alternativa é pior, atrás de uma
interface que é segura de chamar:

```
ana@vm:~/unsafe$ go doc -src strings.Builder.String
package strings // import "strings"

// String returns the accumulated string.
func (b *Builder) String() string {
	return unsafe.String(unsafe.SliceData(b.buf), len(b.buf))
}
ana@vm:~/unsafe$ go list -f '{{join .Imports " "}}' std | grep -cw unsafe; go list std | wc -l
101
383
```

**O `strings.Builder` é a conversão sem cópia da seção 04, tornada segura pelo próprio projeto.** O
builder é dono do buffer, nunca deixa ninguém mais escrever nele e só acrescenta, então os bytes que
uma string devolvida usa nunca mudam depois. A promessa que o `zc.String` pede a cada chamador aqui
é cumprida pelo próprio tipo. O mesmo vale para o runtime, que administra a memória e não pode ser
escrito sem ele, para o `reflect`, assunto da lição 21, e para o `sync/atomic` e o `syscall`, que
conversam com o hardware e com o kernel em endereços.

## Uma regra para o seu código

1. **Meça antes.** Um perfil da lição 12, ou um benchmark como o da seção 04, precisa mostrar a
   alocação ou a cópia custando algo que importe. Depois procure a versão segura, que muitas vezes
   já existe: `m[string(b)]` para consultar, `strings.Builder` para montar, `encoding/binary` para
   ler campos de tamanho fixo, e uma struct reordenada para o preenchimento.
2. **Isole o código num pacote pequeno**, como o `zc`, com a promessa escrita no comentário de
   documentação de cada função exportada. O resto do programa passa a importar um nome, e
   `grep -rl '"unsafe"'` acha cada lugar que precisa da revisão mais rigorosa.
3. **Teste com o checkptr ligado.** Rode `go test -race` no CI, que também liga o checkptr, e
   `go vet ./...` como passo próprio, já que o `go test` pula o `unsafeptr`. Nenhum dos dois prova
   que o código está certo, como o programa `paths` mostrou; juntos eles pegam os dois tipos de erro
   que as ferramentas conseguem ver.
4. **Fixe a versão do Go com que você compila, e rode tudo de novo a cada atualização**, porque a
   única garantia que cobre o resto do programa não cobre este pacote.
