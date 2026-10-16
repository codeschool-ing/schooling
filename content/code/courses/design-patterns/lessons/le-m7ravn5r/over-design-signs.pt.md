---
title: Sinais de excesso de projeto, e os sinais contrários
version: 1
---

**Excesso de projeto é estrutura construída para uma mudança que ainda não chegou.** É fácil
confundi-lo com bom projeto, porque ele se parece com os exemplos: interfaces, factories, classes
pequenas com uma tarefa cada. O que o denuncia é que a flexibilidade nunca é usada. O nome que Kent
Beck deu ao hábito de não construí-la é *you aren't gonna need it* (você não vai precisar disso), e
o catálogo de smells de Martin Fowler chama o resultado de **generalidade especulativa**: ganchos,
parâmetros e classes abstratas que existem para um futuro que ninguém consegue apontar.

Os sinais são concretos o bastante para um programa procurar alguns deles.

## Quatro sinais que dá para ver no código

**Um protocolo ou interface com exatamente uma implementação, e nenhum dublê de teste também.** Uma
interface é a promessa de que várias coisas podem ocupar um lugar. Com uma coisa só ali, ela é um
segundo nome para uma classe. A exceção é uma porta para algo que você não controla, como um
gateway de pagamento, em que a segunda implementação é a falsa dos testes.

**Um parâmetro que ninguém lê.** `for_category(category)` em `layered.py` recebe uma categoria e
devolve a mesma política seja ela qual for. O parâmetro foi posto ali para o dia em que as
categorias forem diferentes, e até lá todo chamador precisa passar um valor que não muda nada.

**Um método que só repassa o trabalho.** `FineCalculator.compute` pergunta à factory e chama a
política; `NoticeService.notice` pergunta à calculadora e chama o formatador. Uma camada que não
acrescenta regra, verificação nem tradução é um salto sem nada no fim.

**Uma factory que só sabe fazer uma coisa**, ou um builder para um objeto de dois campos. Os
padrões de criação da lição 6 compensam quando a construção é complicada ou a classe é escolhida em
tempo de execução. Um construtor de dois argumentos não é nenhum dos dois.

Eis um programa curto que procura os três primeiros num arquivo Python. Ele lê o código-fonte com
o módulo `ast` da biblioteca padrão, que transforma código numa árvore de nós, e percorre a árvore:

```schooling-example
{"language": "python", "file": "smells.py", "parts": [
 {"code": "# smells.py\nimport ast\nimport sys\n\n\ndef protocols(tree: ast.Module) -> dict[str, set[str]]:\n    found = {}\n    for node in tree.body:\n        if isinstance(node, ast.ClassDef) and any(\n                isinstance(b, ast.Name) and b.id == \"Protocol\" for b in node.bases):\n            found[node.name] = {f.name for f in node.body if isinstance(f, ast.FunctionDef)}\n    return found\n\n\ndef methods(cls: ast.ClassDef) -> list[ast.FunctionDef]:\n    return [f for f in cls.body if isinstance(f, ast.FunctionDef)]", "note": "`protocols` acha as classes que herdam de `Protocol` e anota os métodos que cada uma pede."},
 {"code": "\ndef report(path: str) -> None:\n    tree = ast.parse(open(path).read())\n    classes = [n for n in tree.body if isinstance(n, ast.ClassDef)]\n    protos = protocols(tree)\n    print(path)\n    for name, needed in protos.items():\n        impls = [c.name for c in classes\n                 if c.name not in protos and needed <= {m.name for m in methods(c)}]\n        if len(impls) == 1:\n            print(f\"  {name}: a protocol with one implementation, {impls[0]}\")", "note": "Aqui, uma classe implementa um protocolo se tem todos os métodos que ele nomeia. Uma única classe assim é o primeiro sinal."},
 {"code": "\n    for cls in classes:\n        if cls.name in protos:\n            continue\n        for fn in methods(cls):\n            used = {n.id for n in ast.walk(fn) if isinstance(n, ast.Name)}\n            for arg in fn.args.args[1:]:\n                if arg.arg not in used:\n                    print(f\"  {cls.name}.{fn.name}: never reads its argument {arg.arg!r}\")\n            body = fn.body\n            if (len(body) == 1 and isinstance(body[0], ast.Return)\n                    and isinstance(body[0].value, ast.Call)\n                    and isinstance(body[0].value.func, ast.Attribute)):\n                print(f\"  {cls.name}.{fn.name}: one line that hands the work to another object\")", "note": "Para cada método: um argumento que nunca aparece como nome no corpo, e um corpo que é um único `return` de um método chamado em outro objeto."},
 {"code": "\nfor path in sys.argv[1:]:\n    report(path)", "note": "Cada arquivo passado na linha de comando ganha um relatório."}
]}
```

Rode-o nas duas versões do aviso da seção anterior:

```
ana@laptop:~/patterns/choosing$ python3 smells.py layered.py plain.py
layered.py
  FinePolicy: a protocol with one implementation, DailyFine
  PolicyFactory.for_category: never reads its argument 'category'
  FineCalculator.compute: one line that hands the work to another object
  NoticeService.notice: one line that hands the work to another object
plain.py
```

Quatro linhas para `layered.py` e nenhuma sob `plain.py`. **Leia cada linha como uma pergunta,
nunca como um veredito.** Um método que repassa é exatamente o certo numa facade ou num adapter, em
que repassar é o objetivo. Um protocolo com uma implementação é o certo quando a segunda é a falsa
num arquivo de teste que este programa nunca abriu. O que o relatório faz é pôr a pergunta na
frente de alguém, o que já é mais do que uma revisão de projeto costuma conseguir.

## Os sinais contrários

Falta de projeto também existe, e a mesma honestidade vale no outro sentido. Estes são sinais de
que uma força chegou e o código não a respondeu:

- o mesmo `if` sobre as mesmas categorias aparece em vários lugares, e acrescentar uma categoria
  obriga a achar todos;
- um tipo de mudança, como um canal novo, vive mexendo nos mesmos cinco arquivos;
- um teste precisa de um banco de verdade ou de um servidor de e-mail de verdade porque um detalhe
  é construído dentro do código que ele testa;
- duas partes do sistema vivem quebrando uma à outra por um objeto compartilhado que nenhuma das
  duas possui.

Cada um desses é uma força que dá para dizer numa frase, que é o teste que a seção 02 propôs. A
regra de três, normalmente creditada a Don Roberts, é um bom padrão entre os dois tipos de erro: na
primeira vez, escreva simples; na segunda, repare na cópia; na terceira, extraia a estrutura,
porque aí você já sabe qual parte varia.

## Por que o excesso acontece mesmo assim

Raramente é descuido. Um padrão parece competência numa revisão, e uma função simples parece algo em
que ninguém pensou. Entrevistas perguntam sobre padrões pelo nome, e ninguém é chamado a explicar o
padrão que removeu. E a estrutura especulativa parece barata no momento em que é escrita, porque
seu custo cai sobre os leitores depois, que é a conta da seção anterior. Saber que essas pressões
existem não as faz sumir. Mas facilita perguntar, numa revisão, a que força uma interface nova
responde.
