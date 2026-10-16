---
title: Singleton, e por que desconfiar dele
version: 1
---

**Um singleton é uma classe que permite exatamente uma instância de si mesma e dá a todo mundo um
jeito de alcançá-la.** É o padrão mais conhecido do livro e aquele contra o qual desenvolvedores
experientes mais argumentam, porque essas duas metades são promessas diferentes, e a segunda é uma
variável global com nome respeitável.

"Exatamente uma instância" costuma ser uma necessidade real. Um programa deve ter um pool de
conexões, uma configuração, um catálogo em memória. "Alcançável de qualquer lugar" é a parte que dá
problema, e ela não é necessária para a primeira: uma instância criada na inicialização e passada a
quem precisa também é exatamente uma.

## Dois singletons em Python

A forma clássica sobrescreve `__new__`, o método que o Python chama para criar uma instância, para
devolver o mesmo objeto toda vez. A forma pythônica é mais simples e você já a usou: **um módulo é
importado uma vez e guardado, então um objeto criado no nível do módulo é um singleton sem padrão
nenhum.**

```python
# catalogue.py
class Catalogue:
    def __init__(self):
        self.titles = []

    def add(self, title: str) -> None:
        self.titles.append(title)


shared = Catalogue()
```

```schooling-example
{"language": "python", "file": "singleton.py", "parts": [
 {"code": "# singleton.py\nimport catalogue\nfrom catalogue import shared", "note": "O módulo é importado duas vezes, com dois nomes. O Python roda `catalogue.py` uma vez e entrega aos dois nomes o mesmo objeto de módulo."},
 {"code": "\n\nclass Settings:\n    _instance = None\n\n    def __new__(cls):\n        if cls._instance is None:\n            cls._instance = super().__new__(cls)\n            cls._instance.daily_fine = 50\n        return cls._instance", "note": "O singleton clássico. A primeira chamada cria a instância e a guarda na classe; toda chamada seguinte devolve essa mesma."},
 {"code": "\n\ndef desk_a() -> None:\n    Settings().daily_fine = 75\n    shared.add(\"Vidas Secas\")\n\n\ndef desk_b() -> None:\n    print(\"desk b sees fine:\", Settings().daily_fine)\n    print(\"desk b sees titles:\", catalogue.shared.titles)", "note": "Duas funções que nunca citam uma à outra. A primeira muda a multa e acrescenta um título; nada na sua assinatura diz que ela mexe em algo compartilhado."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(\"same settings:\", Settings() is Settings())\n    print(\"same catalogue:\", shared is catalogue.shared)\n    desk_a()\n    desk_b()", "note": "Os dois singletons se confirmam, e então a segunda função vê o que a primeira fez."}
]}
```

Salve `catalogue.py` ao lado e rode `singleton.py`:

```
ana@laptop:~/patterns/gof$ python3 singleton.py
same settings: True
same catalogue: True
desk b sees fine: 75
desk b sees titles: ['Vidas Secas']
```

Os dois `True` são o padrão funcionando. As duas últimas linhas são o seu custo: `desk_b` informa uma
multa de 75 e um título que nunca acrescentou, mudados por uma função da qual nunca ouviu falar.

## Três motivos para desconfiar dele

**Ele esconde dependências.** `desk_b()` não recebe argumentos e depende de dois pedaços de estado
global. É o service locator da lição 5 com outro nome, com a mesma consequência: a assinatura mente,
e você descobre o que uma função usa lendo a função inteira.

**Ele vaza entre testes.** Um teste que põe a multa em 75 a deixa em 75 para o teste seguinte, e a
suíte passa a passar ou falhar conforme a ordem em que roda. Singletons costumam ganhar um método
`reset()` por esse motivo, um método que existe só para desfazer o padrão.

**Ele é uma armadilha com threads.** A verificação `if cls._instance is None` e a atribuição logo
abaixo são dois passos. Duas threads podem ver `None` e criar uma instância cada. A lição 18 roda
exatamente essa corrida e conta as duplicatas.

## O que fazer em vez disso

Fique com "exatamente uma" e largue "alcançável de qualquer lugar". Crie o objeto uma vez, na raiz de
composição da lição 5, e passe-o às classes que precisam dele. Continua havendo um só catálogo, e
agora cada classe que o usa diz isso no construtor, e um teste pode entregar um novo.

Um objeto no nível do módulo é aceitável para coisas que não guardam estado que importe a um teste:
um logger, uma expressão regular compilada, uma tabela de constantes. Quando o objeto guarda dados
que mudam, como configurações editáveis ou um cache, trate a instância do módulo como uma
conveniência para o `main` e passe-a adiante a partir dali.

| linguagem | como um singleton costuma ser escrito |
|---|---|
| Java | um construtor `private` com uma instância `static final`, ou um `enum` com um valor |
| Go | uma variável de pacote, muitas vezes preparada com `sync.Once` |
| TypeScript | um módulo que exporta uma instância: módulos são avaliados uma vez |
| Python | um objeto no nível do módulo; `__new__` só quando uma classe precisa impor isso |

Nas quatro, os frameworks que gerenciam objetos por você, os beans do Spring ou um contêiner como o
da lição 5 com `shared=True`, dão uma instância única sem o acesso global. Essa é a versão que vale a
pena ter.
