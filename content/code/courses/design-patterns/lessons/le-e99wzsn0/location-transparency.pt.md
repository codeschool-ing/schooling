---
title: "Transparência de localização: por que mensagens e não chamadas"
version: 1
---

**Como quem envia só põe uma mensagem numa caixa de correio, ele não tem como saber se o ator atrás
da caixa está na mesma thread, em outro processo ou em outra máquina.** Isso é transparência de
localização, e é o motivo de o modelo de atores insistir em mensagens até dentro de um programa só. Um
projeto escrito como atores que dizem coisas uns aos outros pode ser espalhado por processos depois,
sem reescrever quem envia.

A crença que isso corrige é que mensagens são um tipo mais lento e desajeitado de chamada de método.
Dentro de um processo elas são, um pouco. Mas uma chamada de método supõe coisas que uma rede não
oferece: que quem é chamado divide a sua memória, que a chamada ou termina ou lança exceção, e que é
rápida. Uma mensagem não supõe nada disso. Código escrito contra a promessa mais fraca continua
funcionando quando a mais forte é tirada.

O programa abaixo leva a estante para um processo separado do sistema operacional. Os remetentes
seguram um `Ref`, um endereço com um método, `tell`; eles nunca veem a estante em si.

```schooling-example
{"language": "python", "file": "location.py", "parts": [
 {"code": "# location.py\nimport multiprocessing as mp\nimport os\nimport threading\nfrom dataclasses import dataclass", "note": "O `multiprocessing` inicia outros processos Python e os liga por pipes."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Lend:\n    title: str\n\n\n@dataclass(frozen=True)\nclass Available:\n    title: str", "note": "As mesmas classes de mensagem de antes. Para atravessar para outro processo, uma mensagem passa por pickle, vira bytes, e é reconstruída do outro lado."},
 {"code": "\n\ndef shelf(inbox, outbox) -> None:\n    copies = {\"Iracema\": 1}\n    while (message := inbox.recv()) is not None:\n        match message:\n            case Lend(title=title):\n                copies[title] -= 1\n            case Available(title=title):\n                outbox.send((title, copies[title], os.getpid()))", "note": "A estante é uma função rodando no próprio processo, com a própria memória. O `copies` dela só existe lá. Ela lê mensagens de um pipe e escreve respostas, com o id do processo, em outro."},
 {"code": "\n\nclass Ref:\n    def __init__(self, inbox):\n        self._inbox = inbox\n\n    def tell(self, message) -> None:\n        self._inbox.send(message)", "note": "Um `Ref` é o que os remetentes seguram: a ponta de envio do pipe da estante e nada mais. Não há atributo para alcançar, porque o estado da estante está em outro espaço de endereçamento."},
 {"code": "\n\nif __name__ == \"__main__\":\n    ctx = mp.get_context(\"spawn\")\n    shelf_inbox, to_shelf = ctx.Pipe(duplex=False)\n    from_shelf, shelf_outbox = ctx.Pipe(duplex=False)\n    process = ctx.Process(target=shelf, args=(shelf_inbox, shelf_outbox))\n    process.start()", "note": "O método `spawn` inicia um interpretador novo para a estante, o comportamento padrão do Windows e do macOS, então a execução é a mesma em todo sistema. `Pipe(duplex=False)` devolve uma ponta de recebimento e uma de envio."},
 {"code": "\n    ref = Ref(to_shelf)\n    ref.tell(Lend(\"Iracema\"))\n    ref.tell(Available(\"Iracema\"))\n    title, copies, pid = from_shelf.recv()\n    print(f\"{title}: {copies} left, answered by another process: {pid != os.getpid()}\")", "note": "Um tell, depois um ask montado à mão: mandar *Available*, depois esperar no pipe de resposta."},
 {"code": "\n    try:\n        ref.tell(threading.Lock())\n    except TypeError as err:\n        print(\"a lock cannot be a message:\", err)\n    ref.tell(None)\n    process.join()\n    print(\"shelf process exit code:\", process.exitcode)", "note": "Um lock é estado compartilhado por definição, e não pode virar bytes, então não pode ser uma mensagem. `None` diz à estante para parar."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 location.py
Iracema: 0 left, answered by another process: True
a lock cannot be a message: cannot pickle '_thread.lock' object
shelf process exit code: 0
```

A resposta veio de outro processo, com a própria memória, e o código que envia é o mesmo `tell` da
seção 04. O lock foi recusado no momento do envio, com a razão do próprio Python:
`cannot pickle '_thread.lock' object`. **A regra da seção 03, de que mensagens são valores, deixa de
ser conselho aqui e vira uma propriedade que o transporte impõe.** Algo que só faz sentido como
memória compartilhada não tem como viajar.

## O que a rede acrescenta

Levar um ator para outra máquina mantém a forma do código e muda o que pode dar errado. Uma mensagem a
um ator remoto pode se perder no caminho, ou a máquina pode reiniciar com a mensagem não lida. Uma
resposta pode se perder depois de o trabalho ter sido feito. Por isso os sistemas de atores remotos
dizem o que garantem, e por padrão é pouco: o Akka entrega uma mensagem *no máximo uma vez*, sem
confirmação a não ser que você construa uma, e o Erlang só promete que mensagens de um processo para
outro chegam na ordem em que foram enviadas, se chegarem.

É por isso que os padrões das seções anteriores pesam mais à distância:

| numa máquina | através de uma rede |
|---|---|
| um tell sempre chega à caixa de correio | um tell pode se perder; mensagens importantes precisam de confirmação e nova tentativa |
| um ask sem timeout só trava por bug | um ask sem timeout trava sempre que uma resposta se perde |
| uma queda é vista na hora pelo supervisor | uma máquina calada parece igual a uma lenta, então a falha é detectada por timeout |
| uma mensagem duplicada é bug | uma mensagem reenviada chega duas vezes, então os tratadores precisam ser idempotentes |

As lições 9 e 11 de `architecture` cobriram consistência eventual e novas tentativas entre serviços,
e o mesmo raciocínio vale para atores espalhados por uma rede. O que o modelo de atores contribui é que
o código já estava escrito para isso: nenhuma chamada supunha memória compartilhada, nenhum remetente
supunha uma resposta instantânea, e todo ator já tinha um supervisor para reiniciá-lo.

## Transparente, e ainda assim uma rede

A expressão às vezes é lida como "a rede não importa", e a tabela acima diz outra coisa. A leitura
honesta é mais estreita: **o código que envia não muda; o tratamento de falhas muda.** Um sistema
projetado como se todo ator fosse local, com asks sem timeout e mensagens que se supõe que chegam, vai
se mudar para muitas máquinas e falhar de todos os jeitos que a coluna da direita lista. Projetar para
a coluna da direita desde o começo custa pouco numa máquina só e é o que torna a mudança possível.

O Orleans, da Microsoft, leva a ideia mais longe. Os *atores virtuais* dele, chamados grains, são
endereçados por uma identidade, como um número de membro, e o runtime decide que servidor hospeda cada
um, iniciando-o no primeiro uso e mudando-o de lugar quando um servidor sai. Quem chama nunca fica
sabendo onde o grain mora, e não precisa saber.
