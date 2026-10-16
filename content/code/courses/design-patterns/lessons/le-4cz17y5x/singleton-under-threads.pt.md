---
title: "O singleton com threads: um vira quatro"
version: 1
---

**Um singleton criado sob demanda é uma corrida de verificar-depois-agir com nome de padrão de
projeto.** A lição 6 mostrou o singleton e deu motivos para desconfiar dele; aqui vai mais um, e é
o mais concreto. A versão comum em Python verifica se a instância existe e a cria se não existir.
Duas threads podem as duas descobrir que não existe.

O catálogo da biblioteca demora um pouco para carregar, 40.000 registros do disco, então o
programa o cria na primeira vez que alguém pede:

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [
 {"code": "# catalogue.py\nimport threading\nimport time\n\n\nclass Catalogue:\n    created = 0\n\n    def __init__(self):\n        Catalogue.created += 1\n        time.sleep(0.1)  # loading 40,000 records from disk\n        self.records = 40_000", "note": "`created` conta quantas vezes o construtor rodou. Um singleton promete que esse número nunca passa de um."},
 {"code": "\n_instance: Catalogue | None = None\n\n\ndef get_catalogue() -> Catalogue:\n    global _instance\n    if _instance is None:\n        _instance = Catalogue()\n    return _instance", "note": "O singleton preguiçoso dos livros: verificar, depois criar. Entre a verificação e a atribuição fica o construtor lento inteiro."},
 {"code": "\nif __name__ == \"__main__\":\n    got: list[Catalogue] = []\n    desks = [threading.Thread(target=lambda: got.append(get_catalogue())) for _ in range(4)]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"catalogues created:\", Catalogue.created)\n    print(\"distinct objects handed out:\", len({id(c) for c in got}))", "note": "Quatro balcões pedem o catálogo ao mesmo tempo, como quatro threads de requisição de um servidor web fariam no primeiro carregamento de página depois de um reinício."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 catalogue.py
catalogues created: 4
distinct objects handed out: 4
```

Os quatro balcões viram `_instance is None`, porque nenhum tinha terminado de montar o seu. Quatro
catálogos foram carregados, quatro objetos entregues, e a última atribuição venceu. Aqui isso custa
três cargas desperdiçadas. **Quando o singleton guarda um pool de conexões, um cache ou um
contador, as threads que ficaram com as cópias perdedoras continuam usando essas cópias**,
escrevendo em objetos que mais ninguém vai ler.

## Corrigido com uma trava, e verificado duas vezes

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [
 {"code": "# catalogue.py\nimport threading\nimport time\n\n\nclass Catalogue:\n    created = 0\n\n    def __init__(self):\n        Catalogue.created += 1\n        time.sleep(0.1)  # loading 40,000 records from disk\n        self.records = 40_000", "note": "Sem mudança: o construtor é tão lento quanto antes."},
 {"code": "\n_instance: Catalogue | None = None\n_lock = threading.Lock()\n\n\ndef get_catalogue() -> Catalogue:\n    global _instance\n    if _instance is None:\n        with _lock:\n            if _instance is None:\n                _instance = Catalogue()\n    return _instance", "note": "A primeira verificação fica fora da trava, então depois que o catálogo existe ninguém paga pela trava. A segunda fica dentro: uma thread que esperou na trava encontra a instância que um vencedor já criou."},
 {"code": "\nif __name__ == \"__main__\":\n    got: list[Catalogue] = []\n    desks = [threading.Thread(target=lambda: got.append(get_catalogue())) for _ in range(4)]\n    for d in desks:\n        d.start()\n    for d in desks:\n        d.join()\n    print(\"catalogues created:\", Catalogue.created)\n    print(\"distinct objects handed out:\", len({id(c) for c in got}))", "note": "Os mesmos quatro balcões."}
]}
```

```
ana@laptop:~/patterns/concurrency$ python3 catalogue.py
catalogues created: 1
distinct objects handed out: 1
```

Um catálogo. O padrão se chama **double-checked locking** (trava com verificação dupla), e tem uma
história que vale conhecer. Em Java antes da versão 5 ele era quebrado mesmo com a trava: outra
thread podia ver a referência para o objeto novo antes de as escritas do construtor nos campos
ficarem visíveis, e usar um catálogo montado pela metade. A correção lá é declarar o campo
`volatile`. A lição por baixo é que um padrão de trava esperto é uma afirmação sobre um modelo de
memória, e a maioria de quem escreve um nunca leu o seu.

## Ou não seja preguiçoso

A correção mais simples é criar o objeto antes de existir qualquer thread. Em Python um módulo é
executado uma vez, sob a trava do próprio sistema de importação, então isto é seguro não importa
quantas threads o importem:

```python
CATALOGUE = Catalogue()  # built when the module is first imported
```

Esse é o conselho da lição 6 sobre singletons em Python, e as threads dão a ele um segundo motivo. A
mesma ideia em outras linguagens: Go tem `sync.Once`, que roda uma função exatamente uma vez não
importa quantas goroutines a chamem; Java tem o idioma da classe portadora (*holder class*), em que
o carregamento de classes da JVM faz a trava. Módulos JavaScript são avaliados uma vez por realm,
então um objeto no nível do módulo é um por event loop, mas uma worker thread tem um realm próprio e
ganha a sua própria cópia.

Melhor ainda é o conselho que a lição 5 deu sobre injeção de dependência: construa o catálogo uma
vez em `main.py` e passe-o para quem precisar. Uma raiz de composição roda antes de as threads
começarem, então não há corrida para ganhar.
