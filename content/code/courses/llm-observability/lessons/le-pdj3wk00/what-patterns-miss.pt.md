---
title: O que os padrões deixam passar, e o que pegam por engano
version: 1
---

Uma expressão regular acha texto que tem forma. Dados pessoais quase sempre têm uma, às vezes não têm,
e às vezes outro texto tem a mesma forma. O `misses.py` passa seis frases pelo `redact()`:

```python
"""misses.py: what the patterns catch, what they miss, and what they catch by mistake."""
import redact

for text in ["Hi, I'm Joana Prado (joana.prado@example.com), order MG-20481937.",
             "my email is joana dot prado at example dot com",
             "call me on 11 5550-0142",
             "card 4111 1111 1111 1111, expires 09/28",
             "Is ISBN 978-0-14-143951-8 in stock?",
             "My CPF is 123.456.789-09"]:
    print(f"{text}\n  -> {redact.redact(text)}")
```

```
ana@lab:~/obs$ python misses.py
Hi, I'm Joana Prado (joana.prado@example.com), order MG-20481937.
  -> Hi, I'm Joana Prado ([email]), order [order].
my email is joana dot prado at example dot com
  -> my email is joana dot prado at example dot com
call me on 11 5550-0142
  -> call me on 11 5550-0142
card 4111 1111 1111 1111, expires 09/28
  -> card [card], expires 09/28
Is ISBN 978-0-14-143951-8 in stock?
  -> Is ISBN [card]in stock?
My CPF is 123.456.789-09
  -> My CPF is 123.456.789-09
```

Seis linhas, quatro tipos de resultado.

**Pego como se queria**: o endereço e o pedido na primeira linha, o cartão na quarta. A data de
validade continua lá, o que sozinho é inofensivo.

**Deixado passar porque a forma mudou.** Um endereço escrito por extenso, do jeito que as pessoas
escrevem para fugir de robôs de spam, não tem `@`. Um número de telefone sem o código do país não casa
com um padrão que começa com `+`. As duas coisas são o que os clientes de fato digitam, e as duas
passam direto.

**Deixado passar porque ninguém escreveu o padrão.** Um CPF é um dado pessoal que identifica alguém
diretamente, e o `redact.py` não tem padrão para ele. Para uma loja no Brasil, é uma lacuna para fechar
hoje. A lição geral é que a lista de padrões é uma lista das coisas em que alguém pensou, e precisa da
mesma revisão que qualquer outra lista de regras.

**Pego por engano.** Um ISBN são treze dígitos com hífens, que é exatamente a forma de um número de
cartão, então a pergunta sobre um livro em estoque perdeu o livro. Numa livraria isso não é um caso
raro: é o número que os clientes mais digitam. O padrão também comeu o espaço depois dele. Um falso
positivo não vaza nada, mas remove evidência de todo trace que toca, e quem estiver depurando diante
de `Is ISBN [card]in stock?` vai passar um tempo tentando entender o que aconteceu. Um padrão de cartão
pode ficar mais estrito conferindo o dígito de Luhn que todo número de cartão carrega e que nenhum
ISBN-13 é obrigado a ter; isso não foi acrescentado aqui.

## Nomes, e um modelo para achá-los

Nenhuma das seis linhas perdeu um nome, e nenhum span desta aula perdeu. Um nome não tem uma forma que
um padrão consiga achar sem achar também toda palavra com inicial maiúscula. Achar nomes exige
**reconhecimento de entidades nomeadas**: um modelo que lê a frase e marca quais palavras são uma
pessoa, um lugar, uma data. O **Presidio**, da Microsoft, é a ferramenta de código aberto de costume
para isso. Ele combina um modelo de linguagem do spaCy com padrões próprios, e dá uma nota a cada
achado. O `presidio_try.py` passa as mesmas seis frases por ele:

```python
"""presidio_try.py: the same sentences through Presidio, which finds entities with a language model as well as patterns."""
import logging
import sys

from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine

logging.disable(logging.WARNING)   # tldextract warns that it could not fetch a list; it uses its own copy
threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 0.0
analyzer, anonymizer = AnalyzerEngine(), AnonymizerEngine()
for text in ["Hi, I'm Joana Prado (joana.prado@example.com), order MG-20481937.",
             "my email is joana dot prado at example dot com",
             "call me on 11 5550-0142",
             "card 4111 1111 1111 1111, expires 09/28",
             "Is ISBN 978-0-14-143951-8 in stock?",
             "My CPF is 123.456.789-09"]:
    found = analyzer.analyze(text=text, language="en", score_threshold=threshold)
    print(f"{anonymizer.anonymize(text=text, analyzer_results=found).text}")
    print("    " + (", ".join(f"{r.entity_type} {r.score:.2f}" for r in sorted(found, key=lambda r: r.start))
                     or "nothing found"))
```

```
ana@lab:~/obs$ python presidio_try.py
Hi, I'm <PERSON> (<EMAIL_ADDRESS>), order <DATE_TIME>.
    PERSON 0.85, EMAIL_ADDRESS 1.00, URL 0.50, URL 0.50, DATE_TIME 0.85, US_BANK_NUMBER 0.05, US_DRIVER_LICENSE 0.01
my email is <PERSON> at example dot com
    PERSON 0.85
call me on <PHONE_NUMBER>
    PHONE_NUMBER 0.40
card <CREDIT_CARD>, expires <DATE_TIME>
    CREDIT_CARD 1.00, DATE_TIME 0.10
Is ISBN 978-0-14-<US_DRIVER_LICENSE>-8 in stock?
    US_DRIVER_LICENSE 0.01
My CPF is <DATE_TIME>
    DATE_TIME 0.85, PHONE_NUMBER 0.40
```

**Os nomes são achados**: Joana Prado na primeira linha, e na segunda o endereço por extenso perdeu a
primeira metade porque o modelo leu *joana dot prado* como uma pessoa. O telefone sem código do país
também é achado, e o CPF também.

Leia os rótulos antes de comemorar. O número do pedido foi removido como **data**, com 0,85. O CPF foi
removido como data também, e como telefone. O ISBN perdeu seis dígitos para um reconhecedor de
**carteira de motorista americana**, com nota 0,01. O Presidio é ajustado para documentos americanos
em inglês, e os identificadores de uma loja brasileira não são aquilo para que os seus padrões foram
escritos. O que devia sair quase sempre saiu, às vezes pelo motivo errado, o que é sorte e não
garantia.

Todo achado tem uma nota, e por padrão todo achado é usado, até 0,01. Um limiar muda a troca:

```
ana@lab:~/obs$ python presidio_try.py 0.5
Hi, I'm <PERSON> (<EMAIL_ADDRESS>), order <DATE_TIME>.
    PERSON 0.85, EMAIL_ADDRESS 1.00, URL 0.50, URL 0.50, DATE_TIME 0.85
my email is <PERSON> at example dot com
    PERSON 0.85
call me on 11 5550-0142
    nothing found
card <CREDIT_CARD>, expires 09/28
    CREDIT_CARD 1.00
Is ISBN 978-0-14-143951-8 in stock?
    nothing found
My CPF is <DATE_TIME>
    DATE_TIME 0.85
```

Com 0,5 o ISBN sobrevive e a data de validade fica. O telefone também fica, com nota 0,40, e agora é
um vazamento. **Não existe limiar que remova tudo o que é pessoal e nada mais**; existe uma escolha de
qual erro preferir, e para um armazém de traces o mais seguro é remover demais. Os padrões do
`redact.py` e um reconhecedor como este funcionam melhor juntos: os padrões para os identificadores
que o negócio conhece com exatidão (os seus números de pedido, um CPF, os seus formatos de cartão), o
modelo para os nomes para os quais ninguém consegue escrever um padrão.

Mesmo com os dois, reconhecer é uma probabilidade. A posição honesta é aquela a que esta aula não para
de voltar: **a remoção diminui quanto dado pessoal se guarda; ela não torna o texto anônimo**. Uma
pergunta limpa que diz *My order has not arrived, I live on the street behind the school* ainda pode
apontar para uma pessoa. É por isso que o texto ganha uma vida mais curta que os números, que é a
última seção.
