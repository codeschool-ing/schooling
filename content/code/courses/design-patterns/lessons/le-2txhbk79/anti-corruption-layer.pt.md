---
title: "Camada anticorrupção: traduzir na fronteira"
version: 1
---

**Uma camada anticorrupção é um trecho de código na borda do seu contexto que transforma os dados de
outro modelo no seu próprio modelo, para que as palavras, as formas e os hábitos do outro modelo
nunca cheguem ao seu código.** Tudo lá fora fala a língua deles; tudo aqui dentro fala a sua; a
camada é o único lugar que conhece as duas.

A tentação a que ela resiste é a conveniência. O serviço bibliográfico nacional manda registros com
um campo chamado `ttl`, então o código mais rápido escreve `record["ttl"]` onde quer que precise de
um título: na busca, na tela do balcão, nas cartas de atraso. Cada uso é uma pequena dívida. No dia
em que o serviço renomear `ttl` para `titulo`, ou mandar títulos em maiúsculas, ou acrescentar um
status que quer dizer "retirado de circulação", cada um desses lugares precisa descobrir. **Um modelo
estrangeiro se espalha por um código uma linha conveniente de cada vez**, e a camada existe para
pará-lo na primeira.

## Os registros do serviço, e os nossos

O serviço manda um feed de registros como este:

```json
{"isbn13": "9786555550016", "ttl": "VIDAS SECAS", "aut": ["RAMOS, Graciliano"],
 "assnt": ["Ficção brasileira", "Seca"], "stat": "A"}
```

O modelo do próprio catálogo é o `catalogue.Book` de duas seções atrás: um ISBN escrito com hífens,
um título com maiúsculas normais, autores como os nomes aparecem numa capa, e assuntos. A camada
abaixo transforma um no outro, e recusa o que não consegue transformar. Ela importa `catalogue.py`,
que precisa estar no mesmo diretório:

```schooling-example
{"language": "python", "file": "acl.py", "parts": [
 {"code": "# acl.py\nimport json\nfrom catalogue import Book\n\nFEED = \"\"\"[\n {\"isbn13\": \"9786555550016\", \"ttl\": \"VIDAS SECAS\", \"aut\": [\"RAMOS, Graciliano\"],\n  \"assnt\": [\"Ficção brasileira\", \"Seca\"], \"stat\": \"A\"},\n {\"isbn13\": \"9786555550023\", \"ttl\": \"GRANDE SERTÃO: VEREDAS\", \"aut\": [\"ROSA, João Guimarães\"],\n  \"assnt\": [], \"stat\": \"A\"},\n {\"isbn13\": \"9786555550031\", \"ttl\": \"IRACEMA\", \"aut\": [\"ALENCAR, José de\"],\n  \"assnt\": [\"Romantismo\"], \"stat\": \"A\"},\n {\"isbn13\": \"9786555550047\", \"ttl\": \"O GUARANI\", \"aut\": [], \"assnt\": [], \"stat\": \"D\"}\n]\"\"\"", "note": "O feed do serviço, como chega: nomes de campo próprios, títulos em maiúsculas, autores como \"SOBRENOME, Nome\" e uma letra de status. Um feed de verdade viria pela rede; uma string mantém o programa rodando em qualquer lugar."},
 {"code": "\n\nclass Untranslatable(ValueError):\n    pass", "note": "Um registro que a camada não consegue transformar em `Book` levanta um erro próprio, para o catálogo nunca receber meio livro."},
 {"code": "\n\ndef isbn_ok(digits: str) -> bool:\n    if len(digits) != 13 or not digits.isdigit():\n        return False\n    total = sum(int(d) * (1 if i % 2 == 0 else 3) for i, d in enumerate(digits))\n    return total % 10 == 0\n\n\ndef author(name: str) -> str:\n    surname, _, given = name.partition(\", \")\n    return f\"{given} {surname.title()}\" if given else name.title()\n\n\ndef title(text: str) -> str:\n    small = {\"de\", \"da\", \"do\", \"e\"}\n    words = text.lower().split()\n    return \" \".join(w if i and w in small else w[:1].upper() + w[1:] for i, w in enumerate(words))", "note": "Três traduções pequenas: o dígito verificador do ISBN é conferido, \"RAMOS, Graciliano\" vira \"Graciliano Ramos\", e \"VIDAS SECAS\" vira \"Vidas Secas\". Cada uma é sobre o formato deles, e cada uma mora aqui e em nenhum outro lugar."},
 {"code": "\n\ndef translate(record: dict) -> Book:\n    if record.get(\"stat\") != \"A\":\n        raise Untranslatable(f\"{record.get('isbn13')}: withdrawn by the service\")\n    digits = record[\"isbn13\"]\n    if not isbn_ok(digits):\n        raise Untranslatable(f\"{digits}: check digit does not match\")\n    isbn = f\"{digits[:3]}-{digits[3:5]}-{digits[5:9]}-{digits[9:12]}-{digits[12]}\"\n    return Book(isbn=isbn, title=title(record[\"ttl\"]),\n                authors=tuple(author(a) for a in record[\"aut\"]),\n                subjects=tuple(record[\"assnt\"]))", "note": "`translate` é a única porta da camada. As palavras deles entram (`ttl`, `aut`, `assnt`, `stat`), o `Book` do catálogo sai, e um status diferente de `A` é recusado em vez de adivinhado."},
 {"code": "\n\nif __name__ == \"__main__\":\n    for record in json.loads(FEED):\n        try:\n            book = translate(record)\n            print(\"in: \", book.isbn, book.citation())\n        except Untranslatable as err:\n            print(\"out:\", err)"}
]}
```

```
ana@laptop:~/patterns/ddd-strategic$ python3 acl.py
in:  978-65-5555-001-6 Graciliano Ramos. Vidas Secas.
in:  978-65-5555-002-3 João Guimarães Rosa. Grande Sertão: Veredas.
out: 9786555550031: check digit does not match
out: 9786555550047: withdrawn by the service
```

Dois registros entram como livros de catálogo de verdade, com "RAMOS, Graciliano" virando "Graciliano
Ramos" e "GRANDE SERTÃO: VEREDAS" virando "Grande Sertão: Veredas". O terceiro é recusado porque o
dígito verificador está errado, e o quarto porque o serviço o marcou como retirado. Nenhuma das
recusas chega ao catálogo como um `Book` preenchido pela metade.

## O que faz dela uma camada

Três propriedades, todas visíveis em `acl.py`:

- ela é o único código que cita os campos deles. Procure `ttl` no resto do catálogo e você não acha
  nada. Quando o serviço muda, um arquivo muda;
- ela fala o nosso modelo na saída. `translate` devolve um `catalogue.Book`, a mesma classe que o
  resto do catálogo já usa, e o código que a chama não sabe que existe um feed;
- ela decide o que não aceitamos. Um status `D` poderia virar uma flag `withdrawn` no nosso `Book`,
  e o catálogo teria então de lidar com livros retirados em todo lugar. A camada preferiu recusá-los
  na fronteira, o que manteve fora do modelo um conceito de que o catálogo não precisa.

Num sistema maior a camada costuma ter mais partes: um cliente que busca o feed, um *adapter* que faz
a tradução e às vezes uma *facade* que faz uma API externa enorme parecer uma chamada simples. São o
adapter e a facade da lição 6, postos a serviço da estratégia. A ideia continua do tamanho de
`translate`: o modelo deles entra, o nosso sai.

## Quando não construir uma

Uma camada é código para escrever, testar e manter em dia com o outro lado. Quando o modelo do
upstream já é parecido com o seu, conformar-se a ele sai mais barato, como o empréstimo faz com o
provedor de pagamentos. Construa a camada quando o upstream não vai mudar por você **e** o modelo
dele entortaria o seu. O serviço bibliográfico passa nos dois testes: atende milhares de
bibliotecas, e as maiúsculas e abreviações dele estariam, de outro modo, em todas as telas do
catálogo.
