---
title: Codificar na saída, e uma política atrás
version: 1
---

O cross-site scripting, XSS, é injeção na página. Um texto que o usuário mandou é escrito no HTML sem
ser codificado, e o navegador lê parte dele como marcação ou script. O nome do titular de uma reserva,
um termo de busca devolvido, uma avaliação: qualquer coisa que a página mostra e que não foi ela que
escreveu. **A defesa é codificar na saída, para o contexto onde o texto cai**, e um cabeçalho
Content-Security-Policy como segunda camada para o dia em que a primeira falhar.

O teste é uma marca que é marcação mas não faz nada: `<em>nft-probe</em>`. Se ela voltar como `<em>`,
a página a mandou como marcação e a codificação está faltando. Se voltar como `&lt;em&gt;`, o
navegador vai mostrar os sinais de menor e maior como texto.

```
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/bookings -H "Authorization: Bearer $(cat ~/ana.token)" -d '{"show_id": 991, "seat": 3, "holder": "<em>nft-probe</em>"}'
{"id": 2}
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar localhost:8001/account | grep 'nft-probe'
<li>Show 991, seat 3, for &lt;em&gt;nft-probe&lt;/em&gt;
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar 'localhost:8001/account?q=nft%22probe' | grep 'name="q"'
<form action="/account"><label>Search <input name="q" value="nft&quot;probe"></label>
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -o /dev/null -D - localhost:8001/account | grep -i 'content-security\|nosniff'
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
```

Quatro respostas, quatro conferências:

- **O nome do titular** voltou como `&lt;em&gt;nft-probe&lt;/em&gt;`. O `account.py` o passa por
  `html.escape` antes de escrevê-lo na lista.
- **O termo de busca dentro de um atributo** voltou como `value="nft&quot;probe"`. Esse é o contexto
  que as pessoas esquecem: dentro de `value="…"` o caractere perigoso é a aspa dupla, porque ela
  encerraria o atributo. O `html.escape` a codifica por padrão; um escape escrito à mão que tratasse só
  `<` e `>` passaria na primeira conferência e reprovaria nesta.
- **`Content-Security-Policy: default-src 'none'`** diz ao navegador para não rodar script nenhum e
  não carregar nada de lugar nenhum, numa página que não precisa de nenhum dos dois. Mesmo um erro de
  codificação então não conseguiria rodar nada. Uma página que carrega scripts lista de onde, e o
  testador confere que a política não nomeia mais do que precisa.
- **`X-Content-Type-Options: nosniff`** impede o navegador de adivinhar um tipo diferente do que o
  servidor declarou, o que importa para os uploads da última seção.

**A codificação pertence à saída, não à entrada.** Tirar os sinais de menor e maior quando uma reserva
é salva estraga um nome real e ainda deixa passar todos os outros contextos: o mesmo texto escrito
numa URL, numa string de JavaScript ou num valor de CSS precisa de uma codificação diferente a cada
vez. Bibliotecas de template que codificam por padrão, como o Jinja2 com autoescape ou o JSX do React,
são o jeito comum de um time parar de esquecer; o teste é o mesmo nos dois casos.

O `HttpOnly` no cookie de sessão, da aula 17, é uma terceira camada: um script que chegasse a rodar
ainda não conseguiria ler a sessão. Nenhuma das três é motivo para dispensar as outras.
