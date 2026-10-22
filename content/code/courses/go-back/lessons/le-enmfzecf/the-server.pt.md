---
title: O valor servidor, e os timeouts que ele não traz
version: 1
---

`http.ListenAndServe(addr, handler)` é uma conveniência. Ele monta um `http.Server` com o endereço e
o handler que você deu e todos os outros campos no valor zero, e **para os timeouts o valor zero
quer dizer nenhum**. Uma conexão pode levar o tempo que quiser para mandar os cabeçalhos, para
mandar o corpo e para ficar ociosa entre requisições, e o servidor mantém uma goroutine e um
descritor de arquivo para ela o tempo todo.

Esse é um ataque real e antigo. Um cliente abre uma conexão, manda metade de uma requisição e
depois não manda mais nada; abra alguns milhares dessas e um servidor sem timeouts fica sem
conexões sem fazer trabalho nenhum. Ele ganhou o nome de *Slowloris* quando foi publicado, em 2009,
e **a defesa é um prazo para ler a requisição**, que o valor zero não define.

## Segurando uma conexão aberta

Rode de novo o `hello` da seção 03, que usou `ListenAndServe` e portanto não tem prazos. O bash
sabe abrir uma conexão TCP sozinho com o nome de arquivo `/dev/tcp/HOST/PORT`; isto manda uma linha
de requisição e um cabeçalho, e nunca manda a linha em branco que encerra os cabeçalhos:

```
ana@vm:~/hello$ exec 3<>/dev/tcp/localhost/8080; printf "GET / HTTP/1.1\r\nHost: localhost\r\n" >&3; timeout 5 cat <&3; echo "exit $?"
exit 124
```

O `cat` esperou uma resposta, e o `timeout` o matou depois de cinco segundos; **124 é o status de
saída do `timeout` para "tive de pará-lo"**. O servidor não tinha mandado nada nem fechado nada, e
continuaria esperando depois de cinco minutos com a mesma paciência de cinco segundos.

## A mesma requisição contra um servidor com prazos

Monte o servidor você mesmo, e defina os campos:

```go
// patient/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
	"time"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "hello")
	})
	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           mux,
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}
```

```
ana@vm:~/patient$ start=$SECONDS; exec 3<>/dev/tcp/localhost/8080; printf "GET / HTTP/1.1\r\nHost: localhost\r\n" >&3; timeout 5 cat <&3; echo "exit $? after $((SECONDS-start)) s"
exit 0 after 2 s
```

Desta vez o `cat` terminou sozinho: **o servidor fechou a conexão depois de dois segundos**, sem
dizer nada, e o `cat` viu o fim do fluxo e saiu com 0. Um cliente que manda os cabeçalhos a tempo
nem percebe que o prazo existe.

## O que cada campo limita

| campo | o relógio começa | e para |
|---|---|---|
| `ReadHeaderTimeout` | quando a conexão é aceita, ou uma conexão mantida viva começa uma requisição nova | quando os cabeçalhos foram lidos |
| `ReadTimeout` | no mesmo momento | quando o corpo também foi lido |
| `WriteTimeout` | quando os cabeçalhos foram lidos | quando a resposta foi escrita |
| `IdleTimeout` | depois de uma resposta, numa conexão mantida viva | quando a próxima requisição começa |

**O `ReadHeaderTimeout` é o que detém o Slowloris**, e não custa nada: um cliente de verdade manda
os cabeçalhos em milissegundos. Os outros são julgamentos sobre os seus próprios handlers. Um
`WriteTimeout` de dez segundos quer dizer que um handler que leva onze tem a conexão cortada debaixo
dele, então ele vai acima da resposta mais lenta que o serviço deve dar; a aula 13 encontra uma
resposta feita para durar minutos, e o suspende para aquela rota. Se o `IdleTimeout` ficar em zero,
o servidor usa o `ReadTimeout` no lugar dele.

Os números daqui são um ponto de partida e não uma lei: dois, dez, dez e sessenta segundos protegem
uma API pequena do ataque acima e dão espaço aos handlers. **O que não se defende é o valor zero**,
e todo servidor daqui em diante é um `http.Server` com os quatro definidos.

## A requisição traz o próprio prazo

Mais uma coisa vem com toda requisição e não precisa de campo: `r.Context()`. É um
`context.Context` que **o servidor cancela quando o cliente vai embora** ou a conexão fecha, o
primeiro caso de uso que a aula 12 do `go-concurrency` citou. Um handler que o repassa a uma
consulta ao banco interrompe essa consulta quando não sobra ninguém para ler a resposta. A aula 6 o
repassa.
