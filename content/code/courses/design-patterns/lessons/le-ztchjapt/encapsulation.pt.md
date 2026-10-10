---
title: "Encapsulamento: um objeto cumpre as próprias promessas"
version: 1
---

**Encapsulamento costuma ser ensinado como "deixe os campos privados", e isso é o mecanismo, não a
ideia.** A ideia é que um objeto guarda um estado junto com as regras que mantêm esse estado
coerente, e nada de fora consegue colocá-lo num estado que as regras proíbem. Campos privados são
uma das formas de a linguagem ajudar. O que importa é a promessa.

Pense num empréstimo na biblioteca que este curso usa como exemplo do começo ao fim. Um empréstimo
tem uma data de devolução, pode ser devolvido uma vez, e cada dia de atraso custa 50 centavos. São
três regras. Se a data de devolução e a data em que o livro voltou forem variáveis soltas que
qualquer parte do programa escreve, cada uma dessas regras vira uma esperança: toda função que mexe
num empréstimo precisa lembrar das três, e a que esquecer é onde mora o defeito.

```schooling-example
{"language": "python", "file": "loan.py", "parts": [
 {"code": "# loan.py\nfrom datetime import date, timedelta", "note": "As datas vêm da biblioteca padrão, como tudo neste curso."},
 {"code": "\nclass Loan:\n    DAILY_FINE = 50  # cents", "note": "Dinheiro é um número inteiro de centavos. Um float faria de 0.1 + 0.2 um problema que a contabilidade da biblioteca teria de explicar."},
 {"code": "\n    def __init__(self, title: str, lent_on: date, days: int = 14):\n        self.title = title\n        self._lent_on = lent_on\n        self._due = lent_on + timedelta(days=days)\n        self._returned_on: date | None = None", "note": "O construtor é o único lugar onde o estado é montado. O sublinhado na frente é o jeito do Python de dizer *isto é meu*: uma convenção, não uma tranca."},
 {"code": "\n    @property\n    def due(self) -> date:\n        return self._due", "note": "Uma property deixa quem está de fora ler a data com `loan.due` e não dá a ele nenhum jeito de escrevê-la."},
 {"code": "\n    def give_back(self, on: date) -> None:\n        if self._returned_on is not None:\n            raise ValueError(f\"{self.title!r} was already returned\")\n        if on < self._lent_on:\n            raise ValueError(\"a book cannot come back before it left\")\n        self._returned_on = on", "note": "As duas regras sobre devolver moram aqui e em nenhum outro lugar. Quem chama não consegue contorná-las, porque este método é a única porta para `_returned_on`."},
 {"code": "\n    def fine(self, today: date) -> int:\n        end = self._returned_on or today\n        days_late = (end - self._due).days\n        return max(days_late, 0) * self.DAILY_FINE", "note": "A multa é calculada, nunca guardada. Uma multa guardada é uma segunda cópia das datas, e duas cópias discordam no dia em que alguém atualiza uma delas."},
 {"code": "\n\nif __name__ == \"__main__\":\n    loan = Loan(\"Dom Casmurro\", date(2026, 3, 2))\n    print(\"due:\", loan.due)\n    print(\"fine on 20 March:\", loan.fine(date(2026, 3, 20)))\n    loan.give_back(date(2026, 3, 18))\n    print(\"fine after return:\", loan.fine(date(2026, 4, 30)))\n    try:\n        loan.give_back(date(2026, 3, 19))\n    except ValueError as err:\n        print(\"refused:\", err)", "note": "O bloco sob `if __name__ == \"__main__\"` roda quando o arquivo é executado diretamente, e não quando outro arquivo o importa."}
]}
```

Salve como `loan.py` num diretório novo, `~/patterns/oo`, e rode:

```
ana@laptop:~/patterns/oo$ python3 loan.py
due: 2026-03-16
fine on 20 March: 200
fine after return: 100
refused: 'Dom Casmurro' was already returned
```

Quatro dias de atraso em 20 de março são 200 centavos. Devolvido em 18 de março, com dois dias de
atraso, a multa para de andar: em 30 de abril continua 100. A segunda devolução é recusada com uma
frase que diz por quê.

## O que o sublinhado não faz

O Python não impõe o sublinhado. Qualquer código pode escrever `loan._returned_on = None` e o
interpretador deixa. O `private` do Java, o `private` do C# e o `#field` do TypeScript transformam
isso num erro de compilação ou de execução; o Go torna invisível fora do pacote um campo com
inicial minúscula. **A diferença é real e menor do que parece**: em todas essas linguagens quem
insiste consegue entrar, por reflexão ou editando a classe. O que todas dão é uma linha que quem lê
enxerga, e que uma revisão de código pode se recusar a deixar alguém atravessar.

## O teste de uma boa fronteira

Pergunte o que quem chama precisa saber para usar o objeto direito. Para `Loan`, a resposta são três
métodos: `due`, `give_back` e `fine`. Quem chama não sabe que a multa é de 50 centavos por dia, que
a data de devolução é calculada a partir de uma duração, nem que "não devolvido" é guardado como
`None`. Cada uma dessas coisas pode mudar sem tocar em nenhum chamador. É isso que o encapsulamento
compra, e é por isso que o princípio da responsabilidade única, na lição 3, e os agregados, na lição
12, são no fundo discussões sobre onde passar uma fronteira.

Uma fronteira mal traçada tem esta cara: uma classe com um getter e um setter para cada campo. Ela
tem a sintaxe do encapsulamento e nada da promessa, porque toda regra continua nas mãos de quem
chama os setters.
