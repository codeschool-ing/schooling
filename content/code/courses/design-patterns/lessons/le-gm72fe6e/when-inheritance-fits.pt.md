---
title: Quando a herança é a ferramenta certa
version: 1
---

**A herança serve quando três coisas valem.** O filho é de fato um tipo do pai em todo lugar em que
o pai é usado, o pai foi projetado para ser estendido, e a hierarquia varia ao longo de um eixo só.
O *quase* do título desta lição são esses casos, e eles são comuns o bastante para que uma regra de
"nunca herde" fosse tão errada quanto "sempre".

A crença a substituir é a de que composição é a escolha moderna e herança a antiga, e que herança em
código novo é, portanto, um mau cheiro. A própria biblioteca padrão do Python herda o tempo todo, de
propósito, exatamente nos lugares em que as três condições valem. Estes são os três casos que você
mais vai encontrar.

## Uma família de erros

Exceções são o *é um* mais claro na maioria das bases de código. Um `LoanRefused` é um
`LibraryError` em todo sentido que importa: qualquer lugar que captura `LibraryError` também tem de
capturar `LoanRefused`, e deve. A hierarquia tem um eixo, *o que deu errado*, e ninguém precisa de
uma exceção que seja recusa e expiração ao mesmo tempo.

## Um esqueleto com buracos

O segundo caso é um pai que é dono de um algoritmo e deixa passos com nome para os filhos
preencherem. Todo aviso que a biblioteca manda tem o mesmo formato, uma saudação, um corpo e uma
assinatura, e só o corpo sempre muda:

```schooling-example
{"language": "python", "file": "fits.py", "parts": [
 {"code": "# fits.py\nfrom abc import ABC, abstractmethod\n\n\nclass LibraryError(Exception):\n    \"\"\"Anything the library refuses, with a sentence a person can read.\"\"\"\n\n\nclass LoanRefused(LibraryError):\n    pass\n\n\nclass ReservationExpired(LibraryError):\n    pass", "note": "Três linhas por exceção e nenhum comportamento próprio. O que as classes carregam é a hierarquia, para que um `except` possa escolher o quão amplo capturar."},
 {"code": "\n\nclass Notice(ABC):\n    def render(self, name: str) -> str:\n        return \"\\n\".join([f\"Dear {name},\", self.body(), self.sign_off()])", "note": "O pai é dono da ordem das partes. Um filho não tem como esquecer a saudação, porque nunca escreve `render`."},
 {"code": "\n    @abstractmethod\n    def body(self) -> str: ...\n\n    def sign_off(self) -> str:\n        return \"Biblioteca do Bairro\"", "note": "Dois buracos, documentados pelo jeito como são declarados. `body` tem de ser preenchido; `sign_off` tem um padrão que o filho pode trocar. Essas são as únicas chamadas a `self` em que um filho é convidado a confiar."},
 {"code": "\n\nclass OverdueNotice(Notice):\n    def __init__(self, title: str, cents: int):\n        self.title = title\n        self.cents = cents\n\n    def body(self) -> str:\n        return f\"'{self.title}' is late; the fine so far is {self.cents} cents.\"", "note": "Um filho preenche o único passo que lhe pedem."},
 {"code": "\n\nclass ReadyNotice(Notice):\n    def __init__(self, title: str):\n        self.title = title\n\n    def body(self) -> str:\n        return f\"'{self.title}' is waiting for you at the desk.\"\n\n    def sign_off(self) -> str:\n        return \"Biblioteca do Bairro, open until 19:00\"", "note": "Este também troca o passo opcional."},
 {"code": "\n\nif __name__ == \"__main__\":\n    print(OverdueNotice(\"Dom Casmurro\", 250).render(\"Bia\"))\n    print(ReadyNotice(\"Iracema\").render(\"Caio\"))\n    for error in (LoanRefused(\"Bia owes 250 cents\"), ReservationExpired(\"held for 3 days\")):\n        try:\n            raise error\n        except LibraryError as caught:\n            print(type(caught).__name__, \"->\", caught)\n    try:\n        Notice()\n    except TypeError as caught:\n        print(caught)", "note": "Dois avisos, dois erros capturados pelo pai comum, e uma tentativa de criar um aviso sem corpo."}
]}
```

```
ana@laptop:~/patterns/composition$ python3 fits.py
Dear Bia,
'Dom Casmurro' is late; the fine so far is 250 cents.
Biblioteca do Bairro
Dear Caio,
'Iracema' is waiting for you at the desk.
Biblioteca do Bairro, open until 19:00
LoanRefused -> Bia owes 250 cents
ReservationExpired -> held for 3 days
Can't instantiate abstract class Notice without an implementation for abstract method 'body'
```

Compare com a prateleira da primeira seção. `Shelf.add_all` chamar `self.add` era um acidente de
implementação do qual um filho por acaso dependia. `Notice.render` chamar `self.body` é o motivo de
a classe existir, declarado com `@abstractmethod` e cobrado quando alguém esquece, como mostra a
última linha. **Uma chamada a `self` é perigosa quando está escondida e segura quando é o contrato
documentado.** A lição 6 dá a esse formato o nome de template method.

Mesmo aqui a composição era possível: um `Notice` poderia guardar uma função `body` e um texto
`sign_off`. Com dois buracos e um eixo de variação, a subclasse é mais curta e se lê melhor, o que já
é motivo suficiente.

## Um framework que pede para você herdar

O terceiro caso é um framework que entrega um pai a você e chama os seus métodos. Você já escreveu
um: todo teste em `testing-cicd` era um método numa subclasse de `unittest.TestCase`, e o executor
de testes chamava `setUp` e os seus métodos `test_` nela. Os models do Django, os servlets do Java e
as activities do Android funcionam do mesmo jeito. Aqui o pai foi projetado para extensão por gente
que esperava milhares de filhos, os ganchos dele são documentados, e brigar com ele custa mais do
que economiza.

## As condições, em forma de perguntas

Antes de escrever `class X(Y)`, pergunte:

| pergunta | se a resposta for não |
|---|---|
| Um `X` pode ser usado em todo lugar em que um `Y` é usado, sem surpresas? | não é um *é um*; guarde um `Y` em vez disso (a lição 3 deixa isso preciso) |
| `Y` foi escrito para ser estendido, com as chamadas a `self` documentadas? | envolva-o; não crie subclasse dele |
| Só uma coisa varia entre os filhos? | um segundo eixo vai multiplicar; transforme esse eixo numa parte |
| A hierarquia tem um ou dois níveis? | uma árvore funda é uma corrente de bases frágeis |

As linguagens ajudam de jeitos diferentes com a segunda pergunta. Java e C# deixam uma classe
recusar filhos com `final` ou `sealed`, e as classes do Kotlin são fechadas a menos que marcadas
`open`, o que faz de "projetada para extensão" uma declaração em vez de uma esperança. O Python tem
`typing.final`, que um verificador de tipos cobra e o interpretador ignora. O TypeScript não tem
como proibir subclasses, e o Go, que não tem herança, nunca faz a pergunta.
