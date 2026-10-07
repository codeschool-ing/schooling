---
title: Quando a resposta não cabe
version: 2
---

O segundo e-mail é o que dá errado:

```
Hi. My lamp from order 1043 shipped on 30 September and the tracking has had
no update since. I need it for Saturday. Can you check? João
```

A primeira resposta a ele nem é JSON.

## Mais uma tentativa, com o motivo

```
ana@dev:~/shop$ python extract.py data/emails/2.txt
attempt 1: not JSON: Expecting ',' delimiter
{"order_id": "1043", "category": "delivery", "summary": "No update on lamp tracking since 30 September", "urgent": true}
```

A primeira linha é o programa falando consigo mesmo no `stderr`: **a tentativa 1 falhou, por um
motivo com nome**: o texto não é JSON, e o parser diz o que esperava onde desistiu. O `extract` então acrescentou à conversa a resposta ruim e uma mensagem citando
esses motivos, e pediu de novo. A segunda resposta passou. Esse é o laço de reparo inteiro:

```python
def extract(email, attempts=2):
    messages = [{"role": "user", "content": email}]
    for attempt in range(1, attempts + 1):
        r = model.messages.create(model="llama3.2:3b", max_tokens=300, system=SYSTEM, messages=messages, extra_body={"temperature": 0})
        text = r.content[0].text
        ticket, found = problems(text)
        if not found:
            return ticket
        print(f"attempt {attempt}: {'; '.join(found)}", file=sys.stderr)
        messages += [
            {"role": "assistant", "content": text},
            {"role": "user", "content": "That reply is not valid: " + "; ".join(found)
                                        + ". Reply again with the corrected JSON only."},
        ]
    return None
```

## Por que o motivo volta

**Repetir sem o motivo é uma segunda amostra da mesma distribuição.** Pode passar; pode falhar do
mesmo jeito. O motivo muda a requisição: o modelo agora vê a própria resposta, a regra que quebrou
e os valores que o esquema aceita, que é a informação que faltou da primeira vez.

A mesma ideia rodou na aula 8 seção 04, onde o host devolveu os erros de esquema como resultado de
ferramenta. Aqui não há ferramenta, então o erro volta como uma mensagem de usuário comum.

## Sabendo quando parar

O `attempts=2` é o limite, e quando ele acaba o `extract` devolve `None` e o programa diz **"this
email goes to a person"**. Essa última linha importa mais que o laço:

- **Uma terceira e uma quarta tentativa custam dinheiro e raramente consertam** o que a segunda não
  consertou.
- **Um chamado que nunca passou não pode ser registrado meio certo.** Um e-mail registrado com uma
  categoria chutada é pior que um na fila de uma pessoa, porque ninguém olha para ele de novo.
- **Conte as falhas.** Um esquema que falha muito está falando do prompt ou do esquema, e isso é um
  conserto no seu código, não no número de tentativas.

## Conferindo o que um esquema não consegue

O chamado reparado diz `"urgent": true`, uma leitura justa de *I need it for Saturday*, e o resumo
deixa o sábado de fora, uma escolha justa em menos de 120 caracteres. **Nenhum dos dois é algo que um
esquema consiga conferir**. A aula 8 seção 02 tinha
a mesma lacuna: os $21,000 da resposta eram a conversão do modelo, e errada por cem. Quando um valor importa, calcule-o a
partir da fonte, no código, como a loja faz com centavos, e use o campo do modelo só para
encaminhar.
