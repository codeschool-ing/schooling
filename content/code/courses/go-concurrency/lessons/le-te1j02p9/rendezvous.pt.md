---
title: O canal sem buffer é um encontro
version: 1
---

Todos os canais da lição 3, menos um, foram criados com `make(chan T)` e mais nada. Isso cria um
canal **sem buffer**: ele não tem espaço para guardar um valor, nem um só. O primeiro palpite comum
é que um envio deixa o valor e segue em frente, como pôr uma carta no correio. **Num canal sem
buffer um envio só termina quando alguém recebe o valor, e um recebimento só termina quando alguém
oferece um.** As duas goroutines se encontram, o valor atravessa, e as duas seguem. Esse encontro se
chama rendezvous.

Para ver um, o programa tem de imprimir o tempo de cada passo. Este faz quem recebe chegar 300
milissegundos atrasado, salvo como `meet.go`:

```schooling-example
{"language": "go", "file": "meet.go", "parts": [{"code": "// Command meet shows a send on an unbuffered channel waiting for its receiver.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"time\"\n)\n\nvar start = time.Now()\n\nfunc stamp(what string) {\n\tfmt.Printf(\"%4dms  %s\\n\", time.Since(start).Round(10*time.Millisecond).Milliseconds(), what)\n}\n\n", "note": "`stamp` imprime quanto tempo depois do início cada passo aconteceu, arredondado para dez milissegundos para o ruído de uma máquina ocupada não esconder o formato."}, {"code": "func main() {\n\tch := make(chan string)\n\tdone := make(chan struct{})\n\n", "note": "**Nenhum tamanho depois do tipo, então nenhum buffer.** `done` é um segundo canal usado só para esperar quem envia terminar; nada é enviado nele, ele é fechado."}, {"code": "\tgo func() {\n\t\tstamp(\"sender: about to send\")\n\t\tch <- \"ping\"\n\t\tstamp(\"sender: the send returned\")\n\t\tclose(done)\n\t}()\n\n", "note": "Quem envia vai direto para o envio. **A linha depois do envio só é impressa quando o valor foi pego**, então o horário dela diz quando foi."}, {"code": "\ttime.Sleep(300 * time.Millisecond)\n\tstamp(\"receiver: about to receive\")\n\tv := <-ch\n\tstamp(\"receiver: got \" + v)\n\t<-done\n}\n", "note": "`main` é quem recebe, e enrola 300 milissegundos antes. O `<-done` final espera até quem envia imprimir a última linha, pelo motivo que a lição 2 deu: `main` retornar encerra tudo."}]}
```

```
ana@vm:~/buffers$ go run meet.go
   0ms  sender: about to send
 300ms  receiver: about to receive
 300ms  receiver: got ping
 300ms  sender: the send returned
```

Quem envia chegou ao envio em 0 milissegundo e **o envio só retornou em 300**, no momento em que
quem recebe chegou. Durante esses 300 milissegundos a goroutine que envia não fez nada; ficou
estacionada pelo escalonador, sem usar processador, exatamente como uma goroutine em `time.Sleep`.
Aí o valor atravessou e as duas seguiram.

Olhe as duas últimas linhas. Quem recebe imprimiu `got ping` antes de quem envia imprimir que o
envio tinha retornado, e as duas dizem 300ms. **Depois de um rendezvous as duas goroutines voltam a
ser independentes**, e qual chega primeiro ao próximo `Println` é decisão do escalonador; em outra
execução as duas linhas podem trocar de lugar. O que é prometido é mais estreito e mais útil: nada
depois do envio, em quem envia, e nada depois do recebimento, em quem recebe, acontece antes de o
valor atravessar.

É por isso que um canal sem buffer sincroniza, além de levar. **Quando um envio nele retorna, quem
enviou sabe que quem recebe está com o valor**, e não só que ele foi postado em algum lugar.
Programas usam esse saber de propósito: uma goroutine que envia "terminei" num canal sem buffer sabe,
quando o envio retorna, que alguém ouviu.
