---
title: Confira antes de rodar
version: 1
---

A aula 8 seção 03 escreveu as verificações. Esta seção as põe no host, entre o pedido do modelo e a
função, e devolve cada falha ao modelo como um resultado que ele consegue ler. **Uma verificação que
falha não é uma quebra.** É informação que o modelo não tinha.

## A única função do host

```python
def run(name, args):
    """The text to send back, and whether it is an error."""
    found = problems(name, args)
    if found:
        return "invalid arguments: " + "; ".join(found), True
    try:
        return json.dumps(FUNCTIONS[name](**args)), False
    except ShopError as e:
        return str(e), True
```

Duas camadas, em ordem. **O esquema primeiro**, porque uma função chamada com um número onde espera
uma string falha em algum lugar lá dentro, com uma mensagem sobre Python em vez de sobre o pedido.
**As regras da loja depois**, lançadas como `ShopError`, cujas mensagens são escritas para o modelo
ler. Nos dois casos o host manda um `tool_result` com `is_error` ligado, e o laço segue.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas verificações entre o modelo e a função. Uma chamada do modelo passa primeiro pela verificação de esquema, depois pelas regras da loja, e só então a função roda e o resultado volta. Uma falha em qualquer das duas volta ao modelo como tool_result com is_error, dizendo o que estava errado.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma chamada do modelo</text><path d=\"M80 72 L80 100 L148 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"150\" y=\"72\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o esquema</text><text x=\"230.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">formato de uma chamada</text><path d=\"M312 100 L358 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"360\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as regras da loja</text><text x=\"450.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">estado: estoque, datas, devoluções</text><path d=\"M542 100 L578 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"580\" y=\"76\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a função roda</text><path d=\"M640 126 L640 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"640\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tool_result: o que ela fez</text><path d=\"M230 130 L230 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 130 L450 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 176 L232 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M230 176 L80 176 L80 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"340\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tool_result, is_error: o que estava errado</text></svg>", "caption": "Cada falha volta como um resultado que o modelo consegue ler, para ele corrigir a chamada em vez de o host quebrar."}
```

## Um modelo que erra, depois acerta

```
ana@dev:~/shop$ python returns.py "Please return one mug from order 1042, the customer changed their mind."
[1] call:   create_return({"order_id": 1042, "sku": "MUG-01", "quantity": 1, "reason": "customer changed their mind"})
[1] error:  invalid arguments: order_id: 1042 is not of type 'string'; reason: 'customer changed their mind' is not one of ['changed_mind', 'wrong_item', 'damaged', 'faulty']
[2] call:   create_return({"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"})
[2] result:  {"id": "R-1042-1", "order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}
[3] model:  Return R-1042-1 is open for one MUG-01 from order 1042. The customer will receive a prepaid label by email.
ana@dev:~/shop$ cat data/returns.json
[
 {
  "id": "R-1042-1",
  "order_id": "1042",
  "sku": "MUG-01",
  "quantity": 1,
  "reason": "changed_mind"
 }
]
```

**O passo 1 é a chamada da aula 8 seção 03**, e o host a recusa sem rodar nada. O erro nomeia os
dois problemas e lista os quatro motivos que a loja aceita. **O passo 2 é a mesma chamada,
corrigida**: o número do pedido entre aspas e `changed_mind` da lista. Ela passa pelas duas camadas
e abre a `R-1042-1`. O passo 3 é o modelo contando o que aconteceu, numa frase montada a partir do
resultado.

A correção só é possível porque o erro disse o que estava errado. Só "invalid arguments" deixaria o
modelo adivinhando, e um palpite é uma segunda chamada errada.

## As regras da própria loja

O esquema passou nestas duas, e a loja recusou mesmo assim:

```
ana@dev:~/shop$ python -c 'from shop_tools import create_return; create_return("1042", "MUG-01", 2, "changed_mind")' 2>&1 | tail -n 1
shop_tools.ShopError: order 1042 has 1 of MUG-01 left to return, not 2
ana@dev:~/shop$ python -c 'from shop_tools import create_return; create_return("1043", "LAMP-02", 1, "faulty")' 2>&1 | tail -n 1
shop_tools.ShopError: order 1043 is shipped, not delivered; it cannot be returned yet
```

**A primeira é aritmética sobre estado.** O pedido 1042 tinha duas canecas e uma já tem devolução,
então sobra uma; nenhum esquema saberia disso. **A segunda é o status do pedido**: um pacote ainda
em trânsito não pode ser devolvido. As duas mensagens dizem o que é verdade, com números que o
modelo pode repetir ao cliente, e nenhuma vaza algo sobre o qual o modelo já não estivesse
perguntando.

## Onde cada verificação fica

- **No esquema**: tudo sobre o formato de uma chamada, verdadeiro seja lá o que dizem os dados da
  loja.
- **Na função**: tudo o que depende de estado, como estoque, datas e o que já foi devolvido. A
  função confere isso seja quem for que a chame, modelo ou pessoa.
- **Nunca só no prompt.** "Só devolva pedidos entregues" no prompt de sistema é um pedido. O `if`
  no `create_return` é uma regra.
