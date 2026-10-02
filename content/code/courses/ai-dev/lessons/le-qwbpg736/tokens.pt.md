---
title: Tokens não são palavras
version: 1
---

O palpite óbvio é que um modelo lê palavras. Não lê: ele lê **tokens**, pedaços de texto de um
vocabulário fixo que um **tokenizador** escolheu antes de o modelo ser treinado. Palavras comuns
são um token. Palavras raras, outras línguas, números e código são divididos em vários. Como todo
limite e todo preço deste curso são contados em tokens, vale ver onde caem as fronteiras.

## Dividindo texto em tokens

O `lab/tokens.py` imprime, para cada linha, quantos tokens ela tem, quantos caracteres, e os
pedaços com um `|` entre eles. A codificação é a `o200k_base`, pela própria biblioteca `tiktoken`
da OpenAI; a próxima parte desta seção mostra de que modelos ela é:

```
ana@dev:~/shop$ printf "%s\n" "Tokenisation is not splitting on spaces." "Tokenization is not splitting on spaces." "A tokenização não divide o texto nos espaços." "def total(self) -> int:" "        return self.subtotal()" "1290 12900 129000 1290000" | python lab/tokens.py o200k_base
  8 tokens   40 chars  Token|isation| is| not| splitting| on| spaces|.
  8 tokens   40 chars  Token|ization| is| not| splitting| on| spaces|.
 10 tokens   45 chars  A| token|ização| não| divide| o| texto| nos| espaços|.
  7 tokens   23 chars  def| total|(self|)| ->| int|:
  6 tokens   30 chars         | return| self|.sub|total|()
 12 tokens   25 chars  129|0| |129|00| |129|000| |129|000|0
```

Cinco coisas para ler aí:

- **O espaço pertence à palavra depois dele.** ` is`, ` not` e ` splitting` são tokens únicos, com
  o espaço, e é por isso que a distribuição da seção anterior estava cheia de `' message'` e não
  de `'message'`.
- **Uma palavra que o tokenizador viu muito é um token; uma mais rara é dois.** `Tokenisation` e
  `Tokenization` se dividem em `Token` mais um sufixo.
- **A frase em português custa mais.** Dez tokens para uma frase que um leitor brasileiro não acha
  mais longa que a inglesa. Texto em línguas que eram mais raras nos dados de treino do tokenizador
  se divide em mais pedaços, então a mesma requisição custa mais e enche a janela mais depressa.
- **Código se divide na pontuação.** `(self`, `.sub` e `total` são tokens; os oito espaços de
  indentação são mais um.
- **Números são cortados em grupos de até três dígitos.** O modelo nunca vê `1290000` como um
  número, só como os pedaços `129`, `000` e `0`. Esse é um dos motivos de modelos não serem
  confiáveis em contas feitas dígito a dígito, e de a loja deste laboratório fazer as contas de
  dinheiro em código em vez de pedir a um modelo que some.

## Tokenizadores diferentes, contagens diferentes

Um tokenizador pertence a uma família de modelos. O `tiktoken` sabe qual codificação da OpenAI vai
com qual modelo:

```
ana@dev:~/shop$ python -c 'import tiktoken; [print(m, tiktoken.encoding_name_for_model(m)) for m in ("gpt-4", "gpt-4o", "gpt-5")]'
gpt-4 cl100k_base
gpt-4o o200k_base
gpt-5 o200k_base
```

E o mesmo texto dá contagens diferentes em codificações diferentes:

```
ana@dev:~/shop$ printf "%s\n" "A tokenização não divide o texto nos espaços." "        return self.subtotal()" | python lab/tokens.py cl100k_base
 11 tokens   45 chars  A| token|ização| não| divide| o| texto| nos| espa|ços|.
  6 tokens   30 chars         | return| self|.sub|total|()
```

O código saiu igual e o português não: `espaços` é um token no vocabulário novo e dois no antigo.
**Uma contagem de tokens só tem sentido para um tokenizador com nome.** A OpenAI publica as
codificações dela, e por isso o laboratório consegue rodá-las. A Anthropic e o Google não publicam
as deles, e oferecem um endpoint que conta os tokens por você, que a aula 2 usa. O que você mede
com o `tiktoken` para o modelo de outro provedor é uma estimativa.

## Quantos tokens tem um arquivo?

Código é mais denso em tokens que prosa. Estes são os arquivos de código da loja:

```
ana@dev:~/shop$ python -c 'import tiktoken, pathlib; e = tiktoken.get_encoding("o200k_base"); [print(f"{len(e.encode(p.read_text())):5} tokens {len(p.read_text().split()):5} words  {p}") for p in sorted(pathlib.Path("shop").glob("*.py"))]'
    0 tokens     0 words  shop/__init__.py
  265 tokens   121 words  shop/cart.py
   91 tokens    41 words  shop/coupons.py
  137 tokens    66 words  shop/money.py
```

O `cart.py` tem 265 tokens para 121 palavras separadas por espaço, pouco mais de dois tokens por
palavra. O corpus de documentação do laboratório, que é quase todo frases em inglês, tem 78.351
tokens para 51.699 palavras, cerca de um e meio (a aula 1 seção 08 imprime os dois números).
**Meça o seu próprio material em vez de confiar numa regra de bolso**, porque a razão muda com a
língua, o assunto e o tokenizador, e uma estimativa de custo herda o erro que a razão tiver.
