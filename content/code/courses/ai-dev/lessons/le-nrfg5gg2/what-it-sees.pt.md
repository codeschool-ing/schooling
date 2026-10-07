---
title: O que o assistente vê
version: 1
---

Um assistente no editor parece ler o seu projeto. **Ele lê o que o editor manda**, e o editor
decide isso no instante antes de cada requisição. Ele manda parte do arquivo em que você está, parte de
outros arquivos que parecem relacionados, e o arquivo de instruções do projeto se houver um, tudo
cortado para caber num orçamento. A aula 1 seção 10 disse que o modelo só sabe o que está na
requisição; esta seção é sobre quem preenche a requisição, e como.

Os assistentes reais não publicam as regras exatas, e as mudam com frequência. Então o laboratório
tem um pequeno o bastante para ler, o `assist`, escrito para o curso. Ele segue os mesmos três
passos que os reais descrevem na documentação deles, contra o labllm, e ao contrário deles imprime
o que mandou. **As respostas dele vêm do `scripted-1`, então toda sugestão desta aula foi escrita
pelo curso**, e as que estão erradas estão erradas de propósito.

## Uma requisição de completar

A ana começou um método no `shop/cart.py`: a assinatura e a docstring que diz para que ele serve.
O cursor está na linha vazia depois da docstring:

```
ana@dev:~/shop$ sed -n 28,34p shop/cart.py
    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """

```

Ela pede uma completação com outros dois arquivos abertos no editor, do jeito que estariam nas
abas dela:

```
ana@dev:~/shop$ assist complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py
context sent (602 of 3000 tokens):
    335  shop/cart.py (cursor at line 34)
     91  shop/coupons.py
    176  tests/test_cart.py
---
        for line in self.lines:
            if line.sku == sku:
                line.quantity -= quantity
                return
        raise ValueError(f"{sku} is not in the cart")

```

As linhas acima de `---` são o que o `assist` informa sobre a própria requisição: **602 tokens de
contexto de um orçamento de 3.000**, feitos do arquivo em que ela está e das duas abas abertas.
Abaixo de `---` está a sugestão, que as próximas seções julgam.

## O que estava na requisição

O labllm guarda toda requisição que recebe, então ela pode ser lida de volta exatamente como o
modelo a teria lido:

```
ana@dev:~/shop$ python lab/sent.py
system: You complete code. The text <CURSOR> marks the cursor. Reply with only the lines to insert there, nothing else.
### shop/cart.py (cursor at line 34)
from dataclasses import dataclass, field
(...)
        holds, or a sku it does not hold, raises ValueError.
        """

<CURSOR>
    def subtotal(self) -> int:
        return sum(line.unit_price * line.quantity for line in self.lines)
(...)
### shop/cart.py (cursor at line 34)
### shop/coupons.py
### tests/test_cart.py
```

Três coisas a notar, porque toda ferramenta de completar tem uma versão de cada:

- **O cursor é um marcador no texto.** O arquivo vai inteiro, com `<CURSOR>` onde a ana está
  digitando, então o modelo vê o que vem antes do cursor e o que vem depois. Preencher um vão entre
  um começo conhecido e um fim conhecido se chama **fill-in-the-middle** (preencher o meio), e é
  por isso que uma completação consegue fechar um bloco direito: o código abaixo do cursor também
  está no prompt.
- **Os outros arquivos são escolhidos pela ferramenta, não por você.** Aqui são os que a ana tinha
  abertos. Assistentes reais também usam arquivos editados há pouco e arquivos com nome parecido
  com o seu, e alguns fazem busca no repositório. Um arquivo que ninguém escolheu pode estar na
  requisição.
- **Um orçamento decide o que fica de fora.** 3.000 tokens aqui. Um arquivo grande, ou muitas abas
  abertas, quer dizer que algo fica de fora, e o modelo não vai lhe dizer o que não viu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"De onde vem uma requisição de completar. O editor tem o arquivo com o cursor, as abas abertas e o arquivo de instruções. O assist deixa de fora arquivos da lista de exclusão e arquivos com algo com cara de segredo, encaixa o resto num orçamento de 3.000 tokens e manda o resultado ao modelo.\"><defs><marker id=\"cx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">no editor</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">arquivo de instruções</text><rect x=\"20\" y=\"92\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o arquivo, com &lt;CURSOR&gt;</text><rect x=\"20\" y=\"144\" width=\"160\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abas abertas</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as regras do assistente</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lista de exclusão</text><rect x=\"270\" y=\"92\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">checagem de segredos</text><rect x=\"270\" y=\"144\" width=\"180\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">orçamento: 3.000 tokens</text><path d=\"M182 59 L266 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 111 L266 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M182 163 L266 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"610\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a requisição</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"142\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que o modelo vê</text><path d=\"M452 59 L516 59\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 111 L516 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M452 163 L516 163\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><path d=\"M360 196 L360 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-ah)\"></path><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o que ficou de fora: nada avisa</text></svg>", "caption": "O modelo vê a requisição, e a requisição é o que a ferramenta montou. Toda ferramenta de completar tem alguma versão destas três regras."}
```

**A conclusão prática é a mesma da aula 1, aplicada ao editor:** quando uma sugestão ignora uma
convenção ou chama uma função que não existe, a primeira pergunta é se o arquivo que a define
estava no contexto. Abri-lo numa aba, ou citá-lo numa pergunta no chat, muitas vezes resolve.
