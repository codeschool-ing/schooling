---
title: Um valor, quatro lugares
version: 1
---

A aula 2 se recusou a decidir na entrada se um caractere é perigoso, porque a resposta depende de
para onde o valor vai em seguida. Esta aula é para onde ele vai. **Tratar a saída é codificar um
valor para o lugar exato em que ele é escrito**, no momento em que é escrito, para que o leitor
daquele lugar (o interpretador de HTML do navegador, o motor de JavaScript, um interpretador de URL)
o leia como dado e nunca como parte da estrutura da própria página.

A ideia errada mais comum é que existe uma função chamada *escape* e que chamá-la uma vez basta.
Há várias codificações, uma por contexto, e elas não são intercambiáveis. Eis um valor,
`Lu "B" <3 & co`, um apelido perfeitamente comum, e o que ele precisa virar em cada um de quatro
lugares:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-four\" aria-label=\"O mesmo valor, Lu &quot;B&quot; &lt;3 &amp; co, escrito em quatro lugares de uma página, com o que ele precisa virar em cada um. No texto de um elemento HTML vira Lu &amp;#34;B&amp;#34; &amp;lt;3 &amp;amp; co. Num atributo entre aspas vira o mesmo, e são as aspas em volta do atributo que tornam isso suficiente. Dentro de um script vira um literal de string JavaScript escrito pelo tojson, com o sinal de menor e o e comercial como \\u003c e \\u0026. Numa query de URL vira Lu+%22B%22+%3C3+%26+co.\"><defs><marker id=\"l04-four-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260\" y=\"14\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Lu \"B\" &lt;3 &amp; co</text><rect x=\"20\" y=\"80\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">texto HTML</text><rect x=\"200\" y=\"80\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lu &amp;#34;B&amp;#34; &amp;lt;3 &amp;amp; co</text><text x=\"515\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escrito por</text><text x=\"590\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">escape()</text><path d=\"M170 100 L200 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path><rect x=\"20\" y=\"132\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">atributo entre aspas</text><rect x=\"200\" y=\"132\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lu &amp;#34;B&amp;#34; &amp;lt;3 &amp;amp; co</text><text x=\"515\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escrito por</text><text x=\"590\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">escape()</text><path d=\"M170 152 L200 152\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path><rect x=\"20\" y=\"184\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dentro de &lt;script&gt;</text><rect x=\"200\" y=\"184\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"Lu \\\"B\\\" \\u003c3 \\u0026 co\"</text><text x=\"515\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escrito por</text><text x=\"590\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">|tojson</text><path d=\"M170 204 L200 204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path><rect x=\"20\" y=\"236\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">query de URL</text><rect x=\"200\" y=\"236\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Lu+%22B%22+%3C3+%26+co</text><text x=\"515\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escrito por</text><text x=\"590\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">quote_plus()</text><path d=\"M170 256 L200 256\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-four-ah-paper-dim)\"></path></svg>", "caption": "Um valor, quatro lugares, quatro codificações. O lugar decide a codificação, e nada no valor decide."}
```

Cada linha responde a um leitor diferente:

- **Texto HTML.** Entre as tags, `<` começaria uma tag e `&` uma entidade. O escape de HTML os troca
  por `&lt;` e `&amp;`, e o navegador volta a mostrar os caracteres.
- **Um atributo entre aspas.** Dentro de `value="…"`, um `"` terminaria o atributo antes da hora e o
  que viesse depois seria lido como mais marcação. O escape de HTML o transforma em `&#34;`. **As
  aspas em volta do atributo fazem parte da defesa**: um atributo sem aspas termina num espaço, e o
  escape não mexe em espaços.
- **Dentro de um `<script>`.** Uma string JavaScript precisa do próprio escape para `"` e `\`, e ela
  também está dentro de HTML, onde `</script>` termina o script não importa o que o JavaScript ache.
  O `tojson` do Flask escreve um literal JavaScript e transforma `<`, `>`, `&` e `'` em escapes `\u`,
  para que o interpretador de HTML nunca veja uma tag.
- **Uma query de URL.** Em `/search?q=…`, um espaço, `&` ou `#` terminaria o valor ou começaria outro
  parâmetro. A codificação de URL, `%26` para `&`, mantém o valor como um parâmetro só.

### As quatro codificações, pelo Python

Nada disso precisa de framework para ser visto. A pasta desta aula é `~/sc/profile`; crie a pasta e
o repositório como na aula 2, e salve isto nela como `contexts.py`:

```python
# contexts.py
import json
from urllib.parse import quote_plus

from jinja2.utils import htmlsafe_json_dumps
from markupsafe import escape

value = 'Lu "B" <3 & co'
print("HTML text and quoted attribute:", escape(value))
print("JavaScript, json.dumps:        ", json.dumps(value))
print("JavaScript, as tojson writes it:", htmlsafe_json_dumps(value))
print("URL query:                     ", quote_plus(value))
```

```
(.venv) ana@vm:~/sc/profile$ python3 contexts.py
HTML text and quoted attribute: Lu &#34;B&#34; &lt;3 &amp; co
JavaScript, json.dumps:         "Lu \"B\" <3 & co"
JavaScript, as tojson writes it: "Lu \"B\" \u003c3 \u0026 co"
URL query:                      Lu+%22B%22+%3C3+%26+co
```

A segunda e a terceira linhas são o par que ensina. `json.dumps` escreve uma string JavaScript
correta, e **deixa `<` em paz**, porque `<` não significa nada para o JavaScript. Dentro de
`<script>` significa muito para o interpretador de HTML, que roda primeiro. `htmlsafe_json_dumps`, a
função por trás do filtro `tojson` do Flask, é o `json.dumps` mais essa camada extra.

### Contextos se aninham

Um link para a página de busca com o nome do paciente é uma URL dentro de um atributo: dois
contextos, um dentro do outro. **Codifique de dentro para fora**: codifique o valor para a query, e
depois escape para HTML a URL inteira, para o atributo. O navegador desfaz na ordem contrária.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-layers\" aria-label=\"Uma URL dentro de um atributo HTML precisa de duas codificações, aplicadas de dentro para fora. Primeiro o valor é codificado para URL, para entrar na query string. Depois a URL inteira é escapada para HTML, para entrar no atributo. Lendo a página, o navegador desfaz na ordem contrária: decodifica o atributo primeiro, depois a URL.\"><defs><marker id=\"l04-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"140\" y=\"20\" width=\"440\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escapado para HTML: entra em href=\"…\"</text><rect x=\"190\" y=\"52\" width=\"340\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">codificado para URL: entra na query</text><rect x=\"260\" y=\"90\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o valor</text><path d=\"M40 190 L330 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-layers-ah-paper-dim)\"></path><text x=\"185\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o servidor escreve, de dentro para fora</text><path d=\"M680 190 L390 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-layers-ah-paper-dim)\"></path><text x=\"535\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o navegador lê, de fora para dentro</text></svg>", "caption": "Contextos se aninham. Cada camada recebe a própria codificação, a mais interna primeiro."}
```

Erre a ordem, ou pule uma camada, e a página continua aparecendo certa para nomes comuns. É por isso
que essas falhas sobrevivem: o teste que as pegaria precisa usar um valor com os caracteres que
importam naquele contexto, e o nome real de ninguém tem todos eles.
