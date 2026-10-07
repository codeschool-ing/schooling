---
title: Conferindo as citações
version: 2
---

Uma resposta com citações parece confiável, e isso é um risco próprio. Uma citação é uma afirmação
sobre de onde veio uma frase, e **um modelo pode produzir uma citação do mesmo jeito que produz
qualquer outro texto**: o id com cara de provável, depois da frase com cara de provável. A boa notícia
é que essa afirmação, ao contrário da maior parte do que um modelo diz, pode ser conferida por um
programa.

## Três checagens que um programa consegue fazer

```python
def check_citations(answer, found):
    """Every sentence cites a passage that was retrieved, and every quoted phrase is in it."""
    given = {c["id"]: c["text"] for c, _ in found}
    if answer.strip() == NOT_THERE:
        return []
    problems = []
    for sentence in re.split(r"(?<=[.!?\]])\s+(?!\[)", answer.strip()):
        cited = re.findall(r"\[([\w.-]+#\d+)\]", sentence)
        if not cited:
            problems.append(f'cites nothing: "{sentence[:50]}"')
        for cid in cited:
            if cid not in given:
                problems.append(f"cites {cid}, which was not among the passages")
        for quote in re.findall(r'"([^"]+)"', sentence):
            if cited and not any(quote.lower() in given.get(c, "").lower() for c in cited):
                problems.append(f'quotes "{quote}", which {", ".join(cited)} does not say')
    return problems
```

- **A frase fixa passa como está.** "The handbook does not say." é a única resposta que pode não
  citar nada, e é reconhecida comparando strings, que é por isso que o prompt a pede exata.
- **Toda outra frase tem de citar um trecho, e só um trecho que foi recuperado.** Uma frase sem id
  pode ter vindo dos trechos ou do treino do modelo, e nada na resposta diz de onde. Uma frase que
  cita um trecho que não estava no prompt veio de outro lugar.
- **Toda expressão entre aspas tem de estar no trecho que ela cita.** Uma citação literal é a
  afirmação mais conferível que existe, e a que os leitores mais levam a sério.

A resposta é cortada em frases depois de um ponto final, de interrogação ou de exclamação, ou de um
colchete que fecha, e nunca logo antes de um que abre, então `abroad. [shipping.md#3]` fica uma frase
só, com a citação. A primeira versão deste verificador esqueceu o colchete que fecha, e uma frase
depois de um era colada nele em silêncio e pegava emprestada a citação. A caneca quebrada abaixo
achou isso.

## Três respostas, conferidas

```
ana@dev:~/shop$ python scratch/ask.py "My lamp stopped working after two months. What can I do?"
retrieved: warranty.md#1, shipping.md#1, returns.md#4
You can return the lamp to the shop, but since it's been more than 30 days, you won't be eligible for a refund. However, since the lamp stopped working within the 90-day warranty period, you can file a claim under the warranty described in [warranty.md#1].
citations: cites nothing: "You can return the lamp to the shop, but since it'"
```

**A segunda frase está certa e citada**: dois meses estão dentro da garantia de 90 dias do
`warranty.md#1`. A primeira é marcada, e merece ser. A segunda metade dela vem do `returns.md#4`, que
estava no prompt e diz que a loja não aceita devoluções depois de 30 dias, e a primeira metade
contradiz esse trecho: "You can return the lamp to the shop". Ela não cita nada, então nada na
resposta diz em qual metade acreditar. Um programa não percebe que a frase está confusa. Percebe que
ela não tem fonte, e aqui isso bastou.

```
ana@dev:~/shop$ python scratch/ask.py "Is support open on Saturday?"
retrieved: contact.md#1, account.md#2, contact.md#2
The handbook does not say.
citations: every citation checks out
```

**Passa, e está errada.** O primeiro trecho recuperado é o `contact.md#1`, e ele diz que o suporte
atende "Monday to Friday". A resposta à pergunta é não, ela está no prompt, e o modelo respondeu que o
manual não diz. A frase fixa pode não citar nada, então o verificador não tem a que prendê-la. Uma
recusa é mais segura que uma resposta inventada, e ainda assim é uma falha: o cliente que perguntou
não recebe nada que não teria recebido sem resposta nenhuma.

```
ana@dev:~/shop$ python scratch/ask.py "My mug arrived broken. Can I get my money back?"
retrieved: payment-errors.md#3, returns.md#3, warranty.md#1
The refund goes back to the original payment method once the item arrives at the warehouse and is checked, which takes up to five working days. [returns.md#3]

Note: The warranty information does not mention refunds for broken items, only manufacturing faults.
citations: cites nothing: "Note: The warranty information does not mention re"
```

A primeira frase copia o `returns.md#3` com fidelidade e o cita, e não responde à pergunta: diz como
um reembolso é pago, não se este cliente recebe um. A nota depois dela não cita nada e é marcada. A
resposta de verdade do manual, que uma quebra no transporte é uma entrega danificada e não uma
devolução, está no `returns.md#1`, que a busca não trouxe para a palavra *broken*, e a aula 6, seção
09, mede quantas vezes isso acontece.

**Em todas as rodadas feitas para esta aula, o `llama3.2:3b` nunca citou um trecho que não tinha
recebido e nunca pôs entre aspas uma expressão que o trecho dela não continha.** As duas checagens
para isso ficam mesmo assim. Custam uma linha cada, outro modelo ou uma resposta mais longa pode
falhar nelas, e no dia em que um falhar elas já estão lá.

## O que fazer com uma resposta marcada

- **Não a mostre como conferida.** A resposta mais barata é mostrar a resposta sem a frase que não
  cita nada, ou cair para mostrar os próprios trechos.
- **Pergunte de novo, dizendo o problema**, o laço da aula 5 seção 07: "a primeira frase não cita
  nenhum trecho; cite um, ou deixe a frase de fora".
- **Conte.** A fração de respostas com problemas de citação é um número para acompanhar, por prompt e
  por modelo, na avaliação da próxima seção.

A checagem prova que uma frase cita alguma coisa, que o que ela cita foi dado, e que uma citação
literal está nele. Não prova que o trecho diz o que a frase afirma, e não diz nada sobre uma recusa: o
sábado acima é um trecho mal lido, e passou. Essa parte ainda precisa de uma pessoa, numa amostra.
