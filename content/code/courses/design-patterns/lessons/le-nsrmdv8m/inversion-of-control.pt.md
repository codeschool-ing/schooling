---
title: "Inversão de controle: quem chama quem"
version: 1
---

**Inversão de controle quer dizer que o seu código deixa de decidir quando roda: outra coisa segura
o laço e chama você.** A expressão costuma ser usada como sinônimo de injeção de dependência, e isso
mistura duas ideias que esta lição mantém separadas. Inversão de controle é a forma geral. Injeção
de dependência é uma coisa específica que se inverte: quem constrói os objetos de que uma classe
precisa.

O jeito mais limpo de ver a forma é a diferença entre uma biblioteca e um framework. Você chama uma
biblioteca: `textwrap.shorten`, `json.dumps` e `sqlite3.connect` fazem o trabalho quando o seu
código pede e depois devolvem o controle. Um framework chama você. Você escreve uma função, diz ao
framework quando ela se aplica, e o framework decide quando, e se, vai rodá-la. O Django chama a sua
view quando chega uma requisição, o `unittest` chama os seus métodos de teste, um botão de uma
biblioteca de interface gráfica chama o seu tratador quando alguém clica nele.

Crie `~/patterns/injection` e trabalhe nele durante a lição inteira:

```sh
mkdir -p ~/patterns/injection
cd ~/patterns/injection
```

Aqui está um framework pequeno o bastante para ler de uma vez: um balcão de empréstimos que é dono
da fila de pedidos e chama o tratador registrado para cada um.

```schooling-example
{"language": "python", "file": "desk.py", "parts": [
 {"code": "# desk.py\nfrom textwrap import shorten", "note": "A única chamada de biblioteca do arquivo. O seu código chama `shorten` e recebe uma resposta; nada em `shorten` sabe que o seu programa existe."},
 {"code": "\n\nclass Desk:\n    def __init__(self):\n        self._handlers = {}\n\n    def on(self, action):\n        def register(handler):\n            self._handlers[action] = handler\n            return handler\n        return register", "note": "O framework. Ele guarda uma tabela de tratadores e não faz ideia do que nenhum deles faz."},
 {"code": "\n    def run(self, queue):\n        for action, title in queue:\n            handler = self._handlers.get(action)\n            if handler is None:\n                print(f\"desk: no handler for {action!r}, skipped\")\n                continue\n            print(f\"desk: {action} -> {handler(title)}\")", "note": "O laço pertence ao framework. Ele decide a ordem, decide o que acontece quando ninguém trata um pedido e decide o que fazer com a resposta."},
 {"code": "\n\ndesk = Desk()\n\n\n@desk.on(\"lend\")\ndef lend(title):\n    return f\"lent {shorten(title, width=24, placeholder='...')} for 14 days\"\n\n\n@desk.on(\"return\")\ndef give_back(title):\n    return f\"{title} is back on the shelf\"", "note": "O seu código são duas funções que nunca chamam uma à outra e nunca chamam `run`. O decorador só avisa o framework de que elas existem."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk.run([(\"lend\", \"Memórias Póstumas de Brás Cubas\"),\n              (\"return\", \"Dom Casmurro\"),\n              (\"renew\", \"Vidas Secas\")])", "note": "Uma linha entrega o controle. Depois dela, quem manda é o framework, até a fila esvaziar."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 desk.py
desk: lend -> lent Memórias Póstumas de... for 14 days
desk: return -> Dom Casmurro is back on the shelf
desk: no handler for 'renew', skipped
```

Nada em `lend` ou em `give_back` diz quando a função roda. O terceiro pedido não encontrou
tratador, e foi o framework, não o seu código, que decidiu pulá-lo e avisar.

## O princípio de Hollywood

O nome antigo disso é **princípio de Hollywood: não nos ligue, nós ligamos para você.** Um ator deixa
o telefone com o estúdio e espera; o estúdio decide quando há um papel. O seu tratador deixa uma
função com o framework do mesmo jeito.

O que você ganha é tudo o que o framework faz em volta da sua função sem você escrever: o laço, o
roteamento, o tratamento de erros, a ordem. O que você perde é a visão de conjunto. Lendo `desk.py`
de cima a baixo, não dá para saber só por `lend` quando ela vai ser chamada, nem se vai ser chamada.
**Controle invertido é mais fácil de estender e mais difícil de acompanhar**, e todo framework que
você já usou pede exatamente essa troca.

| | uma biblioteca | um framework |
|---|---|---|
| quem segura o laço | o seu código | o framework |
| como o seu código é alcançado | não é: ele é que alcança | ele se registra e é chamado de volta |
| exemplo em Python | `json`, `textwrap`, `sqlite3` | `unittest`, Django, `tkinter` |
| exemplo em outras linguagens | `lodash`, `java.time` do Java, `strings` do Go | Express, Spring, JUnit, os handlers de `net/http` do Go |

O `net/http` do Go fica na coluna dos frameworks, embora quem programa em Go raramente o chame assim:
`http.HandleFunc("/loans", handler)` registra uma função, e o servidor a chama a cada requisição.

## O que se inverte nesta lição

O fluxo de controle é uma das coisas que um framework tira das suas mãos. **A construção é outra.**
Uma classe que precisa de um notificador pode construir um sozinha, ou pode recebê-lo de quem
constrói a classe. A segunda opção é inversão de controle aplicada às dependências, e tem nome
próprio: injeção de dependência. A lição 4 fez os avisos de multa dependerem de uma porta `Notifier`
em vez de uma classe concreta; esta lição trata da pergunta que isso deixa em aberto: se a classe
não constrói o seu notificador, quem constrói, e onde?
