---
title: O custo de um padrão, contado em linhas e saltos
version: 1
---

**Todo padrão compra flexibilidade com indireção, e a indireção é paga por todo leitor, toda vez.**
A visão comum é que um padrão custa um pouco de esforço uma vez, quando é escrito, e depois só dá.
O esforço de escrever é a parte pequena. A parte grande é que uma pergunta sobre o código, *quanto
é a multa?*, agora exige vários arquivos e vários saltos para ser respondida, e esse custo se
repete a cada leitura, por cada pessoa, enquanto o código existir.

O custo pode ser contado, e contar é mais honesto do que discutir gosto. Crie `~/patterns/choosing`
e trabalhe lá:

```sh
mkdir -p ~/patterns/choosing
cd ~/patterns/choosing
```

## O mesmo aviso, escrito duas vezes

Um aviso de multa para um membro com quatro dias de atraso, primeiro do jeito mais simples possível:

```python
# plain.py
DAILY_FINE = 50  # cents


def notice(name: str, days_late: int) -> str:
    return f"{name}, you owe {max(days_late, 0) * DAILY_FINE} cents"


if __name__ == "__main__":
    print(notice("Bia", 4))
```

E depois do jeito que ele costuma acabar depois de alguns padrões aplicados de boa-fé: uma política
atrás de um protocolo, uma factory que escolhe a política, uma calculadora, um formatador e um
serviço que guarda os dois, ligados num único lugar como a lição 5 ensinou.

```schooling-example
{"language": "python", "file": "layered.py", "parts": [
 {"code": "# layered.py\nfrom typing import Protocol\n\n\nclass FinePolicy(Protocol):\n    def fine(self, days_late: int) -> int: ...\n\n\nclass DailyFine:\n    def __init__(self, cents: int):\n        self.cents = cents\n\n    def fine(self, days_late: int) -> int:\n        return max(days_late, 0) * self.cents", "note": "Um protocolo para políticas de multa, e a única política que existe."},
 {"code": "\nclass PolicyFactory:\n    def for_category(self, category: str) -> FinePolicy:\n        return DailyFine(50)\n\n\nclass FineCalculator:\n    def __init__(self, factory: PolicyFactory):\n        self.factory = factory\n\n    def compute(self, category: str, days_late: int) -> int:\n        return self.factory.for_category(category).fine(days_late)", "note": "Uma factory que escolhe uma política pela categoria, e uma calculadora que pergunta à factory."},
 {"code": "\nclass NoticeFormatter:\n    def format(self, name: str, cents: int) -> str:\n        return f\"{name}, you owe {cents} cents\"\n\n\nclass NoticeService:\n    def __init__(self, calculator: FineCalculator, formatter: NoticeFormatter):\n        self.calculator = calculator\n        self.formatter = formatter\n\n    def notice(self, name: str, category: str, days_late: int) -> str:\n        return self.formatter.format(name, self.calculator.compute(category, days_late))", "note": "Um formatador para a frase, e um serviço que guarda a calculadora e o formatador."},
 {"code": "\ndef build() -> NoticeService:\n    return NoticeService(FineCalculator(PolicyFactory()), NoticeFormatter())\n\n\nif __name__ == \"__main__\":\n    print(build().notice(\"Bia\", \"adult\", 4))", "note": "Uma raiz de composição que monta o grafo, e o mesmo aviso para Bia."}
]}
```

```
ana@laptop:~/patterns/choosing$ python3 plain.py
Bia, you owe 200 cents
ana@laptop:~/patterns/choosing$ python3 layered.py
Bia, you owe 200 cents
ana@laptop:~/patterns/choosing$ wc -l plain.py layered.py
  10 plain.py
  46 layered.py
  56 total
```

A mesma frase, a partir de mais de quatro vezes as linhas. Nenhuma das classes de `layered.py` está
errada sozinha, e cada uma é um padrão que você viu neste curso. Juntas, elas são uma resposta a
forças que este programa não tem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l19-two-arrangements\" aria-label=\"Duas arrumações do mesmo aviso de multa. À esquerda, plain.py: um módulo com uma constante, DAILY_FINE, e uma função, notice. À direita, layered.py como diagrama de classes: NoticeService tem um FineCalculator e um NoticeFormatter; FineCalculator tem uma PolicyFactory e chama fine num protocolo FinePolicy; PolicyFactory cria um DailyFine, a única classe que implementa FinePolicy. A esquerda tem 10 linhas; a direita tem 46 linhas e seis classes.\"><defs><marker id=\"l19-two-arrangements-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"105.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">plain.py</text><rect x=\"25.0\" y=\"70.0\" width=\"160.0\" height=\"82.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«module»</text><text x=\"105.0\" y=\"95.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plain.py</text><path d=\"M25.0 107.0 L185.0 107.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"33.0\" y=\"118.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">DAILY_FINE = 50</text><path d=\"M25.0 129.5 L185.0 129.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"33.0\" y=\"140.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notice()</text><text x=\"105.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">10 linhas, 1 função</text><path d=\"M212.0 10.0 L212.0 266.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"470.0\" y=\"16.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">layered.py</text><rect x=\"235.0\" y=\"40.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NoticeService</text><path d=\"M235.0 62.5 L375.0 62.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"243.0\" y=\"73.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">notice()</text><rect x=\"235.0\" y=\"170.0\" width=\"140.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NoticeFormatter</text><path d=\"M235.0 192.5 L375.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"243.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">format()</text><rect x=\"415.0\" y=\"40.0\" width=\"135.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.5\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FineCalculator</text><path d=\"M415.0 62.5 L550.0 62.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"423.0\" y=\"73.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">compute()</text><rect x=\"415.0\" y=\"170.0\" width=\"135.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.5\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PolicyFactory</text><path d=\"M415.0 192.5 L550.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"423.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">for_category()</text><rect x=\"600.0\" y=\"40.0\" width=\"110.0\" height=\"59.5\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">«protocol»</text><text x=\"655.0\" y=\"65.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">FinePolicy</text><path d=\"M600.0 77.0 L710.0 77.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"608.0\" y=\"88.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><rect x=\"600.0\" y=\"170.0\" width=\"110.0\" height=\"45.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"655.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">DailyFine</text><path d=\"M600.0 192.5 L710.0 192.5\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"608.0\" y=\"203.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fine()</text><path d=\"M375.0 62.0 L415.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M375.0 62.0 L384.0 67.5 L393.0 62.0 L384.0 56.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M305.0 85.0 L305.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M305.0 85.0 L299.5 94.0 L305.0 103.0 L310.5 94.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M482.0 85.0 L482.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M482.0 85.0 L476.5 94.0 L482.0 103.0 L487.5 94.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--paper-dim)\"></path><path d=\"M550.0 62.0 L598.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l19-two-arrangements-dp-ah-paper-dim)\"></path><text x=\"574.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">chama</text><path d=\"M550.0 192.0 L598.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l19-two-arrangements-dp-ah-paper-dim)\"></path><text x=\"574.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">cria</text><path d=\"M655.0 170.0 L655.0 99.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M655.0 99.5 L662.0 111.5 L648.0 111.5 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"var(--panel)\"></path><text x=\"470.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">46 linhas, 6 classes, 1 função</text></svg>", "caption": "A mesma frase, de uma função ou de seis classes. Cada caixa à direita é um lugar que quem lê pode ter de visitar."}
```

## Contando os saltos

Linhas são a medida barata. A cara é quantos lugares quem lê precisa visitar para acompanhar um
pedido, e o Python consegue contar isso para você. `sys.setprofile` chama uma função sua toda vez
que qualquer função Python começa ou retorna, e este programa a usa para anotar cada chamada feita
dentro dos dois arquivos enquanto um aviso é produzido:

```schooling-example
{"language": "python", "file": "hops.py", "parts": [
 {"code": "# hops.py\nimport sys\n\nimport layered\nimport plain\n\nMINE = (\"plain.py\", \"layered.py\")", "note": "As duas versões são importadas como módulos. Só contam as chamadas a funções definidas nesses dois arquivos."},
 {"code": "\ndef trace(job) -> list[str]:\n    lines: list[str] = []\n    depth = 0\n\n    def watch(frame, event, arg):\n        nonlocal depth\n        if not frame.f_code.co_filename.endswith(MINE):\n            return\n        if event == \"call\":\n            lines.append(\"  \" * depth + frame.f_code.co_qualname)\n            depth += 1\n        elif event == \"return\":\n            depth -= 1\n\n    sys.setprofile(watch)\n    answer = job()\n    sys.setprofile(None)\n    return [answer] + lines", "note": "`watch` é chamada a cada chamada e retorno. Ela indenta pela profundidade, então a saída mostra quem chamou quem."},
 {"code": "\nfor label, job in ((\"plain.py\", lambda: plain.notice(\"Bia\", 4)),\n                   (\"layered.py\", lambda: layered.build().notice(\"Bia\", \"adult\", 4))):\n    answer, *calls = trace(job)\n    print(f\"{label}: {answer!r}\")\n    print(f\"  function calls: {len(calls)}\")\n    for line in calls:\n        print(\"    \" + line)", "note": "Um aviso de cada versão, com a resposta primeiro, para mostrar que as duas dizem a mesma coisa."}
]}
```

```
ana@laptop:~/patterns/choosing$ python3 hops.py
plain.py: 'Bia, you owe 200 cents'
  function calls: 1
    notice
layered.py: 'Bia, you owe 200 cents'
  function calls: 9
    build
      FineCalculator.__init__
      NoticeService.__init__
    NoticeService.notice
      FineCalculator.compute
        PolicyFactory.for_category
          DailyFine.__init__
        DailyFine.fine
      NoticeFormatter.format
```

Uma chamada contra nove, com quatro níveis de profundidade. **Para responder *quanto é a multa?* na
versão em camadas, quem lê abre `NoticeService.notice`, depois `FineCalculator.compute`, depois
`PolicyFactory.for_category`, e só então chega à multiplicação em `DailyFine.fine`.** Numa base de
código de verdade essas quatro ficam em quatro arquivos, e o *ir para a definição* do editor cai no
protocolo em vez de na classe, o que acrescenta uma busca a cada salto.

## O que a indireção teria comprado

As camadas não são inúteis; são precoces. A factory é onde uma segunda política seria escolhida. O
protocolo é onde um teste trocaria a política por uma falsa. O serviço é onde um segundo canal
seria acrescentado. Cada uma dessas é uma força real em alguma biblioteca. O custo vale a pena no
dia em que uma delas chega, e a seção 05 mostra a menor estrutura que paga pela força que recebeu.

A medida para guardar é esta: **um padrão merece sua indireção quando a mudança que ele absorve
custa mais que os saltos extras de todos os leitores**. Uma mudança que acontece toda semana num
código lido todo mês merece bastante indireção. Uma mudança que talvez aconteça um dia, num código
lido todo dia, não merece nenhuma.

A mesma conta vale em qualquer linguagem, com um peso diferente por salto. Os editores de Java e
TypeScript saltam bem por interfaces, e uma interface custa um arquivo. Em Go, as interfaces são
pequenas e declaradas pelo código que as usa, então uma interface de um método ao lado do seu único
chamador sai barata. Em Python, um protocolo que ninguém confere com o mypy é documentação que pode
se descolar do código que descreve.
