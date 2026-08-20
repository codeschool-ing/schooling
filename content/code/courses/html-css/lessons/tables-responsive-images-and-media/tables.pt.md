---
title: Tabela é para dado, não para layout
---

Tabela existe para dado tabular — coisa que tem linha, coluna e sentido em ambas. Uma tabela bem marcada diz ao leitor de tela a que coluna cada célula pertence, e a pessoa consegue navegar entre elas:

```html
<table>
  <caption>Notas do semestre</caption>
  <thead>
    <tr><th scope="col">Aluno</th><th scope="col">Nota</th></tr>
  </thead>
  <tbody>
    <tr><th scope="row">Ana</th><td>9,0</td></tr>
  </tbody>
</table>
```

O `scope` é o que faz a diferença: sem ele, o leitor de tela lê "9,0" sem dizer de quem nem de quê. Com ele, lê "Ana, Nota, 9,0".

Usar tabela para posicionar coisas na tela foi normal nos anos 90 e hoje é erro: cria estrutura de dados falsa, e Flexbox e Grid resolvem melhor. Layout é a próxima metade do curso.
