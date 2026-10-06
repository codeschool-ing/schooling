---
title: A sintaxe de classe
version: 1
---

**Uma classe é um jeito mais limpo de escrever uma função construtora e o seu protótipo**, num bloco
só, com algumas garantias que o jeito antigo não tinha. O mesmo `Book`, com dois recursos que a
sintaxe antiga tornava desajeitados:

```schooling-example
{
  "language": "javascript",
  "file": "class.js",
  "parts": [
    {
      "code": "class Book {",
      "note": "`class Book` declara o construtor e o protótipo num lugar só. O corpo é sempre modo estrito, o arquivo sendo ou não."
    },
    {
      "code": "  constructor(title, year) {\n    this.title = title;\n    this.year = year;\n  }",
      "note": "`constructor` é a função que o `new` chama no passo 3. Ela define as propriedades próprias da instância."
    },
    {
      "code": "  describe() {\n    return `${this.title} (${this.year})`;\n  }",
      "note": "Um método escrito no corpo da classe vai para `Book.prototype`, compartilhado por todo livro, exatamente como `Book.prototype.describe = …` fazia."
    },
    {
      "code": "  get age() {\n    return 2026 - this.year;\n  }",
      "note": "`get` cria uma propriedade que é calculada a cada leitura. `b.age` se escreve sem parênteses e roda esta função."
    },
    {
      "code": "  static fromLine(line) {\n    const [title, year] = line.split(\";\");\n    return new Book(title, Number(year));\n  }\n}",
      "note": "`static` põe uma função na própria classe e não nas instâncias. Um método estático que constrói uma instância a partir de outra entrada é um padrão comum, e `fromLine` é um."
    },
    {
      "code": "const b = Book.fromLine(\"Dom Casmurro;1899\");\nconsole.log(b.describe(), b.age);\nconsole.log(typeof Book, Object.getPrototypeOf(b) === Book.prototype);\nconsole.log(Object.keys(b), Object.hasOwn(Book.prototype, \"describe\"));\nconsole.log(b);",
      "note": "Leia a saída junto com o jeito antigo: `typeof Book` continua `\"function\"`, o protótipo da instância é `Book.prototype`, e `describe` mora lá, não no livro."
    }
  ],
  "output": "Dom Casmurro (1899) 127\nfunction true\n[ 'title', 'year' ] true\nBook { title: 'Dom Casmurro', year: 1899 }"
}
```

**Nada na cadeia de protótipos mudou.** Uma classe é uma função, e os métodos dela ficam no objeto
`prototype`, então tudo das três últimas seções vale para classes sem mudança. A saída do console
põe o nome da classe, `Book`, na frente das chaves, que é a diferença mais visível.

## O que uma classe acrescenta

```javascript
class Book {
  constructor(title) {
    this.title = title;
  }
}
const b = Book("Iracema");
```

```
ana@dev:~/js$ node class-no-new.js 2>&1 | head -n 5
/home/ana/js/class-no-new.js:6
const b = Book("Iracema");
          ^

TypeError: Class constructor Book cannot be invoked without 'new'
```

**Uma classe se recusa a ser chamada sem `new`**, com uma mensagem que diz o que está errado, em vez
da falha confusa da seção anterior. O corpo dela é modo estrito. Os métodos dela não podem ser
usados como construtores. E declarações de classe são içadas como o `let` (aula 3), então usar uma
classe acima da declaração é um `ReferenceError` da zona morta temporal, e não um `undefined`
silencioso.

Escreva classes quando precisar de muitos objetos de um tipo que compartilham comportamento, como
livros num catálogo ou componentes numa página. Quando precisar de um objeto só, um literal de
objeto é mais simples, e quando precisar de estado privado para algumas funções, uma closure
(aula 6) basta.
