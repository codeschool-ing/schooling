---
title: Atores na sua linguagem
version: 1
---

**Só uma das quatro linguagens da trilha `backend` tem uma biblioteca de atores consagrada, e a
linguagem mais famosa por atores não está entre as quatro.** Vale saber isso antes de partir para um
framework: em JavaScript, Go e Python, o modelo de atores costuma ser um projeto que você aplica com as
ferramentas que a linguagem já tem, como a seção 04 fez com uma thread e uma fila.

| sua linguagem | atores | o mais próximo embutido |
|---|---|---|
| Java (e Scala, Kotlin) | Akka, e Apache Pekko, o fork de código aberto dele | threads e `BlockingQueue`, como na seção 04 |
| Go | nenhum na biblioteca padrão; existem Proto.Actor e Ergo | goroutines e canais |
| JavaScript / TypeScript | nenhum consagrado | Web Workers e os `worker_threads` do Node, que só conversam por `postMessage` |
| Python | Pykka e Thespian, fora da biblioteca padrão | `threading` com `queue.Queue`, `multiprocessing`, tasks do `asyncio` com filas |

## Java: Akka e Pekko

O Akka trouxe o modelo do Erlang para a JVM em 2009 e é o kit de atores mais completo fora do Erlang:
atores tipados, supervisão, cluster, persistência. A API tipada dele deixa a estante assim, sem os
tipos de resposta e o auxiliar `withOneLess`:

```java
sealed interface ShelfMessage {}
record Lend(String title, ActorRef<LendResult> replyTo) implements ShelfMessage {}

Behavior<ShelfMessage> shelf(Map<String, Integer> copies) {
    return Behaviors.receive(ShelfMessage.class)
        .onMessage(Lend.class, msg -> {
            int left = copies.getOrDefault(msg.title(), 0);
            if (left == 0) {
                msg.replyTo().tell(new Refused(msg.title()));
                return Behaviors.same();
            }
            msg.replyTo().tell(new Lent(msg.title()));
            return shelf(withOneLess(copies, msg.title()));
        })
        .build();
}
```

Duas coisas diferem do Python. A mensagem carrega o endereço de resposta como um `ActorRef`, o projeto
"me conte como foi" da seção 05. E o estado não é um campo: o comportamento devolve o comportamento
para a próxima mensagem, montado com os novos exemplares, que é a terceira regra de Hewitt escrita ao
pé da letra e a imutabilidade da lição 15 aplicada a um ator. Em 2022 a Lightbend passou o Akka para
uma licença de código disponível que cobra de empresas maiores, e a Apache Software Foundation fez um
fork da última versão aberta com o nome Pekko, com a mesma API sob `org.apache.pekko`.

## Go: goroutines, canais e o primo próximo

Uma goroutine que é dona de um estado e lê pedidos de um canal é um ator em tudo menos no nome, e é Go
idiomático. O provérbio do Go diz isso diretamente: *não comunique compartilhando memória; compartilhe
memória comunicando*.

```go
type lend struct {
	title string
	reply chan bool
}

func shelf(copies map[string]int, requests <-chan lend) {
	for req := range requests {
		ok := copies[req.title] > 0
		if ok {
			copies[req.title]--
		}
		req.reply <- ok
	}
}
```

O modelo por trás dos canais é o *communicating sequential processes* de Tony Hoare, de 1978, e ele
difere dos atores num ponto que vale conhecer. **Um ator tem caixa de correio e endereço; uma
goroutine é anônima e conversa por canais com nome.** Qualquer goroutine que tenha o canal pode ler
dele, um canal pode ser dividido entre muitos leitores, e um envio sem buffer espera até alguém
receber, enquanto o tell de um ator nunca espera. A supervisão também não vem embutida: um panic numa
goroutine que ninguém recupera encerra o programa inteiro.

## JavaScript e TypeScript: uma thread, e workers

Um processo Node.js ou uma aba de navegador roda o seu JavaScript numa thread só, então a corrida da
seção 02 não acontece entre duas linhas de JavaScript puro; ela reaparece em volta de um `await`, onde
outro handler pode rodar entre a verificação e a ação. Para paralelismo de verdade, Web Workers e os
`worker_threads` do Node rodam cada um um interpretador separado com a própria memória, e se comunicam
por `postMessage`, que copia a mensagem. É a disciplina da transparência de localização imposta pela
plataforma: um worker é um ator sem a supervisão.

## Erlang e Elixir: onde o modelo mora

Nenhuma das duas é linguagem da `backend` aqui, e as duas valem uma tarde. O Erlang foi construído na
Ericsson no fim dos anos 1980 para centrais telefônicas que precisavam rodar por anos, e os processos
dele são o modelo de atores com todas as regras impostas: memória separada, mensagens copiadas, links
que avisam outro processo de uma queda, e os supervisores do OTP, cujas estratégias a seção 06
nomeou. O Elixir roda na mesma máquina virtual com uma sintaxe mais amigável. Uma única máquina
aguenta milhões desses processos, porque um processo começa com uma heap de poucos kilobytes. Se a
seção de supervisão fez sentido, a tese de Joe Armstrong, *Making reliable distributed systems in the
presence of software errors*, de 2003, é o argumento original e se lê bem.

## O que se leva daqui

Seja qual for a linguagem, as decisões são as mesmas cinco. Quem é dono deste estado? Que mensagens o
mudam? O que quem envia faz enquanto espera, se é que espera? Quem reinicia o dono quando ele falha, e
de que estado o novo parte? E o que acontece com uma mensagem que não chega? A lição 18 faz as mesmas
perguntas sobre threads e locks, onde as respostas são mais difíceis porque o estado é compartilhado.
