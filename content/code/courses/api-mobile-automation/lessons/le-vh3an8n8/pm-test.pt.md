---
title: pm.test, e o que uma asserção diz
version: 1
---

**Um teste é um nome e uma função, e ele falha quando a função lança um erro.** Esse é o mecanismo
inteiro. `pm.test('status is 200', fn)` roda `fn`. Se nada lá dentro reclamar, o Newman imprime
`Pass  status is 200`; se algo reclamar, ele imprime um número e lista a falha no fim. Todo o resto
num teste do Postman é um jeito de reclamar com clareza.

Ajuda largar cedo uma crença: um script que roda sem erro não é um teste aprovado. Linhas fora de
qualquer `pm.test` também rodam, e uma asserção ali que falhe quebra o script inteiro sem nome nenhum.
**Toda conferência vai dentro de um `pm.test`**, para que cada uma passe ou falhe sozinha e diga qual
foi.

## Um script, pedaço por pedaço

O script de **List shows** tem três testes, e entre eles usa quase tudo de que esta lição precisa:

```schooling-example
{"language": "js", "file": "List shows: Post-response", "parts": [{"code": "pm.test('status is 200', () => {\n  pm.response.to.have.status(200);\n});", "note": "Um teste é um nome e uma função. Se a função lança um erro, o teste falha com aquele nome; se retorna, passa."}, {"code": "pm.test('the body is JSON', () => {\n  pm.response.to.have.header('content-type', 'application/json');\n});", "note": "Com um segundo argumento, `have.header` compara o valor também. Sem ele, o cabeçalho só precisa existir."}, {"code": "pm.test('every show has a whole number of seats left', () => {\n  const { shows } = pm.response.json();", "note": "`pm.response.json()` interpreta o corpo. Um corpo que não é JSON lança um erro aqui, o que derruba este teste e nenhum outro."}, {"code": "  pm.expect(shows).to.be.an('array').that.is.not.empty;", "note": "`pm.expect` é o `expect` do Chai. Algumas palavras estão ali só para serem lidas, como `to`, `be`, `that` e `is`; `an('array')`, `not` e `empty` é que conferem."}, {"code": "  shows.forEach((show) => pm.expect(show.seats_left).to.be.a('number').and.satisfy(Number.isInteger));\n});", "note": "Um teste, várias conferências: o primeiro espetáculo que falhar interrompe a função, e a mensagem diz qual valor foi."}]}
```

Três objetos carregam tudo:

| objeto | o que é | serve para |
|---|---|---|
| `pm.response` | a resposta desta requisição | `.code`, `.headers.get(name)`, `.json()`, `.text()`, `.responseTime` |
| `pm.response.to` | asserções sobre a resposta, do próprio Postman | `.have.status(201)`, `.have.header(name)`, `.have.header(name, value)` |
| `pm.expect(value)` | as asserções do Chai sobre qualquer valor | `.to.equal(x)`, `.to.eql(obj)`, `.to.be.a('string')`, `.to.have.lengthOf(3)`, `.to.include(x)` |

`equal` e `eql` são o par que convém não confundir. **`equal` pergunta se duas coisas são o mesmo
valor**, o que funciona para strings e números e falha para dois objetos que só parecem iguais.
**`eql` pergunta se têm o mesmo conteúdo**, campo a campo. `pm.expect({a: 1}).to.equal({a: 1})`
falha; a mesma linha com `eql` passa.

## O que uma falha diz

Um bom nome de teste é a afirmação, escrita para que uma falha se leia como uma frase. A execução da
seção 02 falhou num teste. No fim da saída o Newman escreveu o nome, `HEAD answers like GET`, e
embaixo `expected response to have status code 200 but got 405`.

Juntas, essas duas linhas são um relato de defeito completo: o que foi afirmado, o que se esperava,
o que voltou. Compare com um teste chamado `test 3` contendo `pm.expect(pm.response.code ===
200).to.be.true`, que falha com *expected false to be true* e não diz nada a ninguém. **Faça a
asserção sobre o próprio valor, não sobre uma comparação que você fez antes**, e o Chai escreve a
mensagem por você.

Mais dois hábitos, os dois visíveis na coleção. Dê ao teste o nome do que um leitor conferiria, não
do código: *location says where it lives*, não *header test*. E mantenha as afirmações de uma
requisição em testes separados, para que uma falha não esconda a seguinte. **Create order** confere
o status, o corpo e o `location` em três testes, então quando o status está errado você ainda fica
sabendo se o `location` veio.
