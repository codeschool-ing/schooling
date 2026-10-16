---
title: "Segregação de interfaces: dependa só do que você usa"
version: 1
---

**O princípio da segregação de interfaces diz que nenhum cliente deve ser obrigado a depender de
métodos que não usa.** Quando uma interface serve a vários tipos de cliente, cada um deles depende
dela inteira, e uma mudança feita para um chega aos outros. A cura são várias interfaces pequenas,
cada uma com o formato do que um tipo de cliente precisa.

Às vezes o princípio é resumido como "interfaces devem ter um método só", o que o transforma numa
regra sobre tamanho. Tamanho não é a medida. Uma interface com cinco métodos que todo cliente chama
está bem segregada; uma interface com dois métodos, em que metade dos clientes usa um e metade usa o
outro, não está. A pergunta é a mesma da responsabilidade única da lição 3, feita pelo outro lado:
não quem muda este código, mas quem o **usa**.

Martin chegou ao princípio na Xerox, nos anos 1990, no software de uma impressora. Uma classe `Job`
servia à impressão, ao grampeamento e ao fax, então o código de grampear dependia dos métodos de
fax, e uma mudança no tratamento de fax exigia recompilar e reimplantar toda parte do sistema que
tocava num job, inclusive as que só grampeavam.

## O Python esconde isso, até você escrever um teste

Crie `~/patterns/solid-2` e trabalhe ali nesta lição:

```sh
mkdir -p ~/patterns/solid-2
cd ~/patterns/solid-2
```

O catálogo da biblioteca foi escrito como uma classe abstrata com tudo de que qualquer um
precisava, e um quiosque no saguão de entrada o usa para buscar:

```schooling-example
{"language": "python", "file": "catalogue.py", "parts": [
 {"code": "# catalogue.py\nfrom abc import ABC, abstractmethod\n\n\nclass Catalogue(ABC):\n    @abstractmethod\n    def search(self, words: str) -> list[str]: ...", "note": "O único método de que o quiosque precisa."},
 {"code": "\n    @abstractmethod\n    def lend(self, title: str, member: str) -> None: ...\n\n    @abstractmethod\n    def give_back(self, title: str) -> None: ...", "note": "Os dois métodos do balcão."},
 {"code": "\n    @abstractmethod\n    def add_title(self, title: str) -> None: ...\n\n    @abstractmethod\n    def remove_title(self, title: str) -> None: ...\n\n    @abstractmethod\n    def export_csv(self) -> str: ...", "note": "Os três da administração. Seis métodos para três tipos de cliente, e todo cliente é tipado contra os seis."},
 {"code": "\n\ndef kiosk(catalogue: Catalogue, words: str) -> None:\n    for title in catalogue.search(words):\n        print(\"found:\", title)", "note": "O quiosque chama um método e declara que precisa de um `Catalogue` inteiro."}
]}
```

Em produção nada dá errado: o catálogo de verdade implementa os seis métodos, e o quiosque chama um.
O custo aparece na primeira vez em que alguém testa o quiosque com um substituto que responde a uma
busca:

```python
# fake_kiosk.py
from catalogue import Catalogue, kiosk


class OneTitle(Catalogue):
    def search(self, words: str) -> list[str]:
        return ["Vidas Secas"]


kiosk(OneTitle(), "secas")
```

```
ana@laptop:~/patterns/solid-2$ python3 fake_kiosk.py
Traceback (most recent call last):
  File "/home/ana/patterns/solid-2/fake_kiosk.py", line 10, in <module>
    kiosk(OneTitle(), "secas")
          ^^^^^^^^^^
TypeError: Can't instantiate abstract class OneTitle without an implementation for abstract methods 'add_title', 'export_csv', 'give_back', 'lend', 'remove_title'
```

O Python se recusa a criar o substituto, e cita cinco métodos que o quiosque nunca vai chamar.
**Para testar uma caixa de busca, pedem que você implemente empréstimo, devolução e uma exportação
em CSV.** Alguém vai fazer isso, com cinco métodos que levantam `NotImplementedError`, e dali em
diante toda mudança nos métodos do balcão ou da administração também significa editar um dublê de
um quiosque que não liga para eles.

## O que as outras linguagens fazem disso

Em Java o mesmo arranjo falha na compilação: uma classe que `implements Catalogue` e deixa um método
de fora é recusada, e uma mudança na assinatura de qualquer método recompila todos os clientes.
TypeScript e Go verificam o formato na compilação, então um dublê passado onde se espera um
`Catalogue` também precisa ter os seis métodos. O Python com um `Protocol` no lugar da classe
abstrata rodaria o dublê sem reclamar e deixaria a queixa para um verificador de tipos. Nas quatro,
o conserto é o mesmo, e é sobre a declaração, não sobre a classe: deixar o quiosque dizer que precisa
de algo que saiba buscar, e nada mais. As duas próximas seções mostram aonde isso leva.
