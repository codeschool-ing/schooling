---
title: "MVVM: a tela se liga sozinha"
version: 1
---

**O model-view-viewmodel dá à tela um modelo próprio, o view-model, feito de propriedades às quais a
view se liga, de modo que ninguém escreve código para atualizar a tela.** Quando uma propriedade
muda, todo widget ligado a ela muda junto. O view-model guarda o estado e a lógica da tela, se o
botão Lend está habilitado e o que diz a linha de status, e não guarda referência nenhuma à view.
John Gossman o descreveu em 2005 para o WPF da Microsoft, cuja linguagem de marcação fazia de um
binding uma declaração de uma linha, e desde então ele virou a forma nativa do `ViewModel` do
Android, do Vue, do Angular e do Knockout.

A crença a abandonar é que um view-model é um presenter com outro nome. Um presenter **manda** a
view mostrar coisas, método por método. Um view-model só **expõe** estado, e os bindings o levam
até a tela. O view-model não tem como mandar nada a uma view, porque não sabe que ela existe.

```schooling-example
{"language": "python", "file": "mvvm.py", "parts": [
 {"code": "# mvvm.py\nfrom datetime import date\nfrom desk_model import Desk"},
 {"code": "\n\nclass Observable:\n    def __init__(self, value):\n        self._value = value\n        self._subscribers = []\n\n    def get(self):\n        return self._value\n\n    def set(self, value) -> None:\n        if value != self._value:\n            self._value = value\n            for fn in self._subscribers:\n                fn(value)\n\n    def subscribe(self, fn) -> None:\n        self._subscribers.append(fn)\n        fn(self._value)", "note": "Toda a maquinaria de binding, em menos de vinte linhas. Um observable guarda um valor e uma lista de inscritos, chama cada um quando o valor muda, e chama um inscrito novo na hora para ele começar em sintonia. Atribuir o mesmo valor de novo não avisa ninguém."},
 {"code": "\n\nclass LendViewModel:\n    def __init__(self, desk: Desk, today: date):\n        self.desk, self.today = desk, today\n        self.code = Observable(\"\")\n        self.member = Observable(\"\")\n        self.can_lend = Observable(False)\n        self.status = Observable(\"\")", "note": "O view-model é o estado da tela, feito de observables: o que está digitado nas duas caixas, se emprestar é possível, e a linha de status. Ele guarda o modelo e nunca a view."},
 {"code": "        self.code.subscribe(lambda _: self._recompute())\n        self.member.subscribe(lambda _: self._recompute())\n        desk.subscribe(self._recompute)", "note": "Sempre que uma das caixas muda, ou o balcão muda, o view-model recalcula seu estado. Estas três linhas são a única ligação que ele mesmo faz."},
 {"code": "\n    def _recompute(self) -> None:\n        code, member = self.code.get(), self.member.get()\n        if not code or not member:\n            self.can_lend.set(False)\n            self.status.set(\"type a code and a member\")\n        elif code not in self.desk.on_shelf:\n            self.can_lend.set(False)\n            self.status.set(f\"{code} is out\")\n        elif self.desk.held_by(member) >= self.desk.limit:\n            self.can_lend.set(False)\n            self.status.set(f\"{member} is at the limit\")\n        else:\n            self.can_lend.set(True)\n            self.status.set(f\"ready to lend {code} to {member}\")", "note": "A lógica da tela, num lugar só: todo motivo pelo qual o botão Lend pode ficar cinza, cada um com a frase que a linha de status deve mostrar. Ele lê as regras do modelo por `on_shelf`, `held_by` e `limit`, e não guarda nenhuma regra própria."},
 {"code": "\n    def lend(self) -> None:\n        if self.can_lend.get():\n            self.desk.lend(self.code.get(), self.member.get(), self.today)", "note": "Um comando. A view o chama quando o botão é apertado; o view-model confere o próprio estado e chama o modelo."},
 {"code": "\n\nclass TextBox:\n    def __init__(self, name: str):\n        self.name, self.text, self.on_edit = name, \"\", None\n\n    def type(self, text: str) -> None:\n        print(f\"(types {text!r} into {self.name})\")\n        self.text = text\n        if self.on_edit:\n            self.on_edit(text)\n\n\nclass Button:\n    def __init__(self, label: str):\n        self.label, self.enabled = label, False\n\n    def set_enabled(self, enabled: bool) -> None:\n        self.enabled = enabled\n        print(f\"  [{self.label}] {'enabled' if enabled else 'greyed out'}\")\n\n\nclass Label:\n    def set_text(self, text: str) -> None:\n        print(f\"  status: {text}\")", "note": "Três substitutos de widgets, cada um imprimindo o que um de verdade desenharia. Nenhum deles ouviu falar do balcão nem do view-model."},
 {"code": "\n\ndef bind_text(box: TextBox, prop: Observable) -> None:\n    box.on_edit = prop.set", "note": "Um binding: quando a caixa é editada, a propriedade é atribuída. Frameworks de verdade escrevem isto em marcação em vez de código."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\n    vm = LendViewModel(desk, date(2026, 3, 2))\n    code_box, member_box = TextBox(\"code\"), TextBox(\"member\")\n    button, label = Button(\"Lend\"), Label()\n    bind_text(code_box, vm.code)\n    bind_text(member_box, vm.member)\n    vm.can_lend.subscribe(button.set_enabled)\n    vm.status.subscribe(label.set_text)\n\n    code_box.type(\"B1\")\n    member_box.type(\"bia\")\n    print(\"(clicks Lend)\")\n    vm.lend()\n    code_box.type(\"B2\")\n    print(\"(clicks Lend)\")\n    vm.lend()\n    code_box.type(\"B3\")", "note": "A composição: quatro bindings, e então uma pessoa digitando e clicando. Ninguém manda o botão ficar cinza com um `if`; o `enabled` dele acompanha `can_lend`."}
]}
```

```
ana@laptop:~/patterns/presentation$ python3 mvvm.py
  [Lend] greyed out
  status: type a code and a member
(types 'B1' into code)
(types 'bia' into member)
  [Lend] enabled
  status: ready to lend B1 to bia
(clicks Lend)
  [Lend] greyed out
  status: B1 is out
(types 'B2' into code)
  [Lend] enabled
  status: ready to lend B2 to bia
(clicks Lend)
  [Lend] greyed out
  status: B2 is out
(types 'B3' into code)
  status: bia is at the limit
```

Leia as duas primeiras linhas, de antes de alguém digitar qualquer coisa: o botão começa cinza e a
linha de status pede um código e um membro, porque `subscribe` chama cada inscrito novo com o valor
atual. Digitar `B1` não imprimiu nada, já que o status continuava "type a code and a member" e um
valor que não muda não avisa ninguém. Digitar `bia` provocou as duas mudanças de uma vez. Depois do
clique o balcão mudou, o balcão avisou o view-model, e o botão ficou cinza sozinho porque o B1 não
estava mais na estante. A última linha é o limite: a Bia tem dois empréstimos, o botão já estava
cinza e continuou assim, então só o status se mexeu.

## O que os bindings compraram

**Não existe linha nenhuma que diga `button.set_enabled(False)` depois de um empréstimo.** Em
`mvp.py` o presenter precisava lembrar de chamar `_refresh` depois de cada mudança, e um presenter
que esquecesse deixaria a tela desatualizada. Aqui o botão acompanha `can_lend` não importa o que o
mudou: digitação, clique, ou o balcão mudando por causa de algo numa outra tela.

**O view-model se testa como qualquer objeto.** Atribua `vm.code` e `vm.member`, leia
`vm.can_lend`:

```python
vm = LendViewModel(Desk(["B1"], limit=1), date(2026, 3, 2))
vm.code.set("B1"); vm.member.set("bia")
assert vm.can_lend.get() is True
```

Não é preciso view falsa, porque não há interface de view para falsificar. É o código repetitivo da
seção anterior, sumindo.

## O que custa

**O fluxo fica invisível.** No MVP, "por que o botão ficou cinza?" se responde lendo o presenter de
cima a baixo. Aqui se responde seguindo inscrições: o balcão avisou o view-model, que recalculou,
que atribuiu `can_lend`, que rodou o inscrito do botão. Com algumas dezenas de propriedades
alimentando umas às outras, uma mudança num lugar pode disparar atualizações que ninguém esperava, e
o depurador mostra uma pilha de callbacks em vez de uma linha de lógica.

As inscrições também têm tempo de vida. O `Observable` acima guarda todo inscrito para sempre; uma
tela fechada mas ainda inscrita continua recebendo atualizações, e continua segurando memória.
Frameworks de binding de verdade cancelam a inscrição quando uma view some, e essa contabilidade é
parte do tamanho deles. A lição 16 constrói observables direito, com cancelamento de inscrição e
operadores; esta seção precisava só do suficiente para mostrar um binding.

## Na sua linguagem

| linguagem | de onde vem o binding | o que é o view-model |
|---|---|---|
| TypeScript / JavaScript | a reatividade do Vue, os templates do Angular, o `observable` do Knockout | o objeto de estado de um componente, ou uma classe de signals |
| Java | objetos `Property` do JavaFX; Data Binding ou Compose no Android | o `ViewModel` do Android com `LiveData` ou `StateFlow` |
| Go | raramente necessário: Go quase não desenha telas | uma struct com channels, quando desenha |
| Python | a classe `Observable` acima; toolkits gráficos oferecem variáveis como o `StringVar` do Tkinter | uma classe comum |

O React merece uma frase, porque é o framework sobre o qual as pessoas perguntam. Ele renderiza a
tela como uma função do estado e roda essa função de novo quando o estado muda, então a direção do
fluxo é a mesma do MVVM: estado entra, tela sai, nenhum código atualizando um widget. O que falta é o
binding de mão dupla, já que uma caixa de texto informa mudanças chamando um handler que você
escreveu.
