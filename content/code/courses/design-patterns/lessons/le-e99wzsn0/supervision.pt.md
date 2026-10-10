---
title: "Supervisão: deixe cair, e recomece do zero"
version: 1
---

**Num sistema de atores, um ator que encontra uma situação para a qual não foi escrito não tenta se
recuperar; ele falha, e outro ator, o supervisor dele, decide o que acontece em seguida.** A decisão de
costume é trocá-lo por uma instância nova, construída do zero, e deixá-la seguir com a próxima
mensagem. A comunidade do Erlang chama isso de *let it crash*, deixe cair, e soa imprudente até você
olhar para o que a alternativa costuma ser.

A alternativa é o código defensivo: um `try` em volta de toda operação, um valor reserva para tudo o
que pode faltar, uma flag para todo estado pela metade. Cada proteção é razoável sozinha. Juntas, elas
produzem um código que continua rodando em estados que ninguém projetou, em que a estante acredita ter
menos um exemplar e toda decisão seguinte se apoia nisso. Uma queda para no primeiro estado errado, e
uma instância nova começa de um estado conhecido e bom. **A recuperação sai do código que falhou e vai
para um código cuja única função é recuperar.**

Sem supervisor, o `actor.py` da seção 04 mostra o perigo do outro extremo. Se `receive` lança uma
exceção, ela encerra `_run`, a thread morre com um traceback, e toda mensagem depois dela fica na caixa
de correio para sempre. Os remetentes continuam chamando `tell`, que continua funcionando, porque um
`put` numa fila não quer saber se alguém vai lê-la. É uma falha silenciosa: a estante parece viva para
todo mundo que fala com ela.

Aqui está um supervisor. Para o programa ficar curto, ele divide uma thread com a estante que vigia e
chama o `receive` dela ele mesmo; no Erlang e no Akka os dois são atores separados e o supervisor fica
sabendo da queda por uma mensagem.

```schooling-example
{"language": "python", "file": "supervision.py", "parts": [
 {"code": "# supervision.py\nimport queue\nimport threading\nfrom dataclasses import dataclass\n\nCATALOGUE = {\"Iracema\": 2, \"Vidas Secas\": 1}\n_STOP = object()", "note": "O catálogo é de onde uma estante nova tira o estado. Reiniciar quer dizer começar daqui de novo."},
 {"code": "\n\n@dataclass(frozen=True)\nclass Lend:\n    title: str\n\n\n@dataclass(frozen=True)\nclass GiveBack:\n    title: str"},
 {"code": "\n\nclass Shelf:\n    def __init__(self):\n        self.copies = dict(CATALOGUE)\n\n    def receive(self, message) -> None:\n        match message:\n            case Lend(title=title):\n                self.copies[title] -= 1\n            case GiveBack(title=title):\n                self.copies[title] += 1\n        print(f\"  {message} -> {self.copies}\")", "note": "A estante não tem tratamento de erro nenhum. Devolver um título que a estante nunca teve lança `KeyError`, como um dicionário faz para uma chave ausente, e esse é o bug que este programa lhe dá."},
 {"code": "\n\nclass Supervisor:\n    def __init__(self, make_child, max_restarts: int):\n        self._make_child, self._max = make_child, max_restarts\n        self._mailbox: queue.Queue = queue.Queue()\n        self._thread = threading.Thread(target=self._run)\n        self._thread.start()\n\n    def tell(self, message) -> None:\n        self._mailbox.put(message)\n\n    def stop(self) -> None:\n        self._mailbox.put(_STOP)\n        self._thread.join()", "note": "O supervisor é dono da caixa de correio. Os remetentes falam com ele exatamente como falavam com o ator da seção 04: `tell` e `stop`."},
 {"code": "\n    def _run(self) -> None:\n        child, restarts = self._make_child(), 0\n        while (message := self._mailbox.get()) is not _STOP:\n            if child is None:\n                print(f\"  {message} not handled: the shelf is down\")\n                continue\n            try:\n                child.receive(message)\n            except Exception as err:\n                print(f\"  {message} crashed the shelf: {type(err).__name__} {err}\")\n                if restarts == self._max:\n                    print(f\"  {restarts} restarts already; giving up and escalating\")\n                    child = None\n                else:\n                    restarts += 1\n                    child = self._make_child()\n                    print(f\"  restarted with fresh state ({restarts} of {self._max})\")", "note": "Para cada mensagem, o supervisor a entrega ao filho atual. Quando o filho lança exceção, ele avisa, constrói um filho novo com `make_child` e passa à próxima mensagem. Depois de `max_restarts`, ele para de tentar e recusa tudo o que vem depois, avisando a cada mensagem."},
 {"code": "\n\nif __name__ == \"__main__\":\n    shelf = Supervisor(Shelf, max_restarts=2)\n    for message in [Lend(\"Iracema\"), GiveBack(\"Macunaíma\"), Lend(\"Iracema\"),\n                    GiveBack(\"O Cortiço\"), GiveBack(\"Macunaíma\"), Lend(\"Vidas Secas\")]:\n        shelf.tell(message)\n    shelf.stop()", "note": "Seis mensagens, três delas ruins."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 supervision.py
  Lend(title='Iracema') -> {'Iracema': 1, 'Vidas Secas': 1}
  GiveBack(title='Macunaíma') crashed the shelf: KeyError 'Macunaíma'
  restarted with fresh state (1 of 2)
  Lend(title='Iracema') -> {'Iracema': 1, 'Vidas Secas': 1}
  GiveBack(title='O Cortiço') crashed the shelf: KeyError 'O Cortiço'
  restarted with fresh state (2 of 2)
  GiveBack(title='Macunaíma') crashed the shelf: KeyError 'Macunaíma'
  2 restarts already; giving up and escalating
  Lend(title='Vidas Secas') not handled: the shelf is down
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-restarts\" aria-label=\"Uma linha do tempo de supervision.py. Seis mensagens chegam da esquerda para a direita: Lend Iracema, GiveBack Macunaíma, Lend Iracema, GiveBack O Cortiço, GiveBack Macunaíma, Lend Vidas Secas. Abaixo, a vida de cada instância da estante é uma barra. A estante 1 trata a primeira mensagem e cai na segunda; o reinício 1 cria a estante 2, que trata a terceira e cai na quarta; o reinício 2 cria a estante 3, que cai na quinta, e o supervisor desiste, então a sexta não é tratada. Embaixo, os exemplares de Iracema depois de cada empréstimo: 1 depois do primeiro, e 1 de novo depois do segundo, porque a estante nova esqueceu o primeiro empréstimo.\"><text x=\"10.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mensagem</text><text x=\"10.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">instância</text><text x=\"10.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Iracema</text><text x=\"190.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Lend</text><text x=\"190.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Iracema</text><path d=\"M190.0 56.0 L190.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"285.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GiveBack</text><text x=\"285.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Macunaíma</text><path d=\"M285.0 56.0 L285.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"380.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Lend</text><text x=\"380.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Iracema</text><path d=\"M380.0 56.0 L380.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"475.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GiveBack</text><text x=\"475.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">O Cortiço</text><path d=\"M475.0 56.0 L475.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"570.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GiveBack</text><text x=\"570.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Macunaíma</text><path d=\"M570.0 56.0 L570.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"665.0\" y=\"28.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Lend</text><text x=\"665.0\" y=\"39.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Vidas Secas</text><path d=\"M665.0 56.0 L665.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"140.0\" y=\"98.0\" width=\"145.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"212.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">estante 1</text><rect x=\"285.0\" y=\"98.0\" width=\"190.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">estante 2</text><rect x=\"475.0\" y=\"98.0\" width=\"95.0\" height=\"24.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"522.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">estante 3</text><rect x=\"570.0\" y=\"98.0\" width=\"140.0\" height=\"24.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fora do ar</text><text x=\"285.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">queda</text><text x=\"475.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">queda</text><text x=\"570.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">queda</text><text x=\"285.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reinício 1</text><text x=\"475.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reinício 2</text><text x=\"570.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">desiste</text><text x=\"665.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">recusada</text><text x=\"190.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"380.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"380.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">não 0: o primeiro empréstimo foi esquecido</text></svg>", "caption": "Cada reinício parte do catálogo. O supervisor reinicia a estante duas vezes e desiste na terceira queda, e o segundo empréstimo mostra o preço: a estante nova não sabe nada do primeiro.", "same": ["Iracema"]}
```

## O que a execução mostra

O primeiro empréstimo leva *Iracema* de dois exemplares para um. Devolver *Macunaíma*, que a estante
nunca teve, a derruba, e o supervisor inicia uma estante nova. O empréstimo seguinte de *Iracema*
deixa **um exemplar, não zero**: a estante nova começou do catálogo e não sabe nada do primeiro
empréstimo. A segunda devolução ruim derruba a estante de novo e o supervisor a reinicia pela segunda
vez. A terceira queda encontra o limite atingido, então o supervisor desiste, e o empréstimo de
*Vidas Secas* é recusado em voz alta.

Duas lições moram nessas nove linhas. A primeira é que um reinício não é de graça: **estado novo quer
dizer estado esquecido**, e tudo o que precisa sobreviver a uma queda não pode morar só dentro do
ator. Os exemplares da estante pertencem a um banco de dados ou, como na lição 9, a um log de eventos
que a instância nova reexecuta quando começa. Quem programa em Erlang divide o estado do mesmo jeito: o
que pode ser reconstruído mora no processo, e o que não pode é escrito num lugar que um reinício não
alcança.

A segunda é que reiniciar tem de parar. Uma mensagem que derruba a estante vai derrubar toda estante
nova também, e um supervisor que reiniciasse para sempre ficaria girando em cima dela. Os supervisores
do Erlang contam os reinícios dentro de uma janela de tempo, por exemplo no máximo três em cinco
segundos, e passado esse limite o próprio supervisor falha, passando o problema para o supervisor
*dele*. Aqui, desistir só imprime uma linha. Num sistema de verdade isso subiria para o nível de
cima, que poderia reiniciar um grupo inteiro de atores, ou parar a aplicação e deixar o sistema
operacional ou a plataforma de contêineres iniciá-la de novo.

## Uma árvore de supervisores

Como supervisores são atores, eles podem ser supervisionados, e uma aplicação vira uma árvore: um
supervisor raiz sobre alguns subsistemas, o supervisor de cada subsistema sobre os seus
trabalhadores. Uma falha sobe pela árvore só até o primeiro supervisor que dá conta dela. O OTP do
Erlang dá nome às estratégias de costume: *one for one* reinicia só o filho que falhou, *one for all*
reinicia todos os filhos de um supervisor quando um falha, para filhos que não funcionam uns sem os
outros, e *rest for one* reinicia o filho que falhou e todos os iniciados depois dele.

## Quando não deixar cair

O lema é sobre falhas inesperadas, as que um programador não previu. Um membro digitando um título
desconhecido é esperado, e a estante deve responder *título inexistente* como uma mensagem comum. Uma
queda ali transformaria um erro de digitação em estado perdido e num reinício contado contra o
limite. Valide nas bordas, onde a entrada chega; deixe o interior cair diante do que deveria ser
impossível. Os erros como valores da lição 15 e as quedas desta seção dividem o trabalho exatamente
nessa linha.
