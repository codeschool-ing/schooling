---
title: Injeção, quando o dado é lido como código
version: 1
---

Quatro dos defeitos mais comuns da web têm uma mesma forma. **Algo que o usuário digitou chega a um
programa que interpreta texto, e o programa lê parte dele como instrução em vez de dado.** O
intérprete muda: um banco lê SQL, um navegador lê HTML e JavaScript, um servidor lê um formulário como
uma decisão que alguém tomou, um sistema de arquivos lê um nome e um tipo. A defesa muda junto, e cada
uma tem um teste que um testador consegue escrever sem saber como alguém abusaria do defeito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l20-boundaries\" aria-label=\"O texto que um usuário mandou, à esquerda, chega a quatro programas que interpretam texto, um em cada linha. O banco lê SQL, e a defesa é a consulta parametrizada. O navegador lê HTML, e a defesa é a codificação por contexto, com uma Content-Security-Policy atrás. O serviço lê um formulário como uma decisão, e a defesa é um token CSRF com cookies SameSite. O sistema de arquivos lê um nome e um tipo, e a defesa é limite de tamanho, conferência do conteúdo, nome feito pelo servidor e armazenamento que nunca é servido. Cada linha termina no teste inofensivo que a confere.\"><defs><marker id=\"l20-boundaries-nf-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"70.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">entrada do usuário</text><text x=\"250.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">intérprete</text><text x=\"450.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">defesa</text><text x=\"635.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">teste inofensivo</text><rect x=\"20.0\" y=\"50.0\" width=\"100.0\" height=\"230.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"70.0\" y=\"145.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma busca,</text><text x=\"70.0\" y=\"158.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um nome,</text><text x=\"70.0\" y=\"171.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um formulário,</text><text x=\"70.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um arquivo</text><path d=\"M120.0 75.0 L182.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"55.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">banco</text><text x=\"250.0\" y=\"81.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SQL</text><path d=\"M315.0 75.0 L372.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"55.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consulta parametrizada</text><path d=\"M525.0 75.0 L557.0 75.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">'</text><path d=\"M120.0 133.0 L182.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"113.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">navegador</text><text x=\"250.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTML</text><path d=\"M315.0 133.0 L372.0 133.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"113.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">codificar por contexto</text><text x=\"450.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+ CSP</text><path d=\"M525.0 133.0 L557.0 133.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"133.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&lt;em&gt;nft-probe&lt;/em&gt;</text><path d=\"M120.0 191.0 L182.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"171.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o serviço</text><text x=\"250.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma decisão</text><path d=\"M315.0 191.0 L372.0 191.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"171.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">token CSRF</text><text x=\"450.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">+ SameSite</text><path d=\"M525.0 191.0 L557.0 191.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">form sem token</text><path d=\"M120.0 249.0 L182.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"185.0\" y=\"229.0\" width=\"130.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"250.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivos</text><text x=\"250.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nome, tipo</text><path d=\"M315.0 249.0 L372.0 249.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-boundaries-nf-ah-paper-dim)\"></path><rect x=\"375.0\" y=\"229.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tamanho, conteúdo,</text><text x=\"450.0\" y=\"255.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nome do servidor</text><path d=\"M525.0 249.0 L557.0 249.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"562.0\" y=\"249.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">CSV com nome .png</text></svg>", "caption": "Uma forma, quatro intérpretes. Cada defesa fica onde o texto entra no programa que o leria como instrução.", "same": ["+ CSP", "+ SameSite", "HTML", "SQL"]}
```

Esta aula testa essas quatro defesas nos seus próprios dois serviços, em `127.0.0.1`, com testes
inofensivos de propósito: uma aspa, um sinal de porcentagem, uma marca de texto, um formulário mandado
sem o seu token, um arquivo que não é imagem. Mandar até mesmo isso a um sistema que não é seu, sem
permissão por escrito, é crime na maioria dos países, o Brasil incluído; e é desnecessário, porque
tudo o que um testador precisa saber sobre uma defesa se aprende com o serviço que está na frente
dele.

## A defesa é o parâmetro

A injeção de SQL acontece quando uma consulta é montada colando o texto do usuário dentro do próprio
SQL. O texto passa a fazer parte do comando, e uma aspa nele encerra a string em que o autor queria
que ele ficasse. **A defesa é a consulta parametrizada**: o comando é mandado com marcadores de lugar,
`?` no SQLite, e os valores viajam separados, então o banco nunca os lê como SQL. O `app.py` da aula
1 faz isso em toda consulta, `title LIKE ?` entre elas, e o `account.py` também.

Um testador confere isso de fora com o único caractere que o SQL trata de modo especial numa string:

```
ana@nft:~/boxoffice$ curl -s 'localhost:8000/search?q=Hamlet' | jq length
4
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' "localhost:8000/search?q='"
[{"id": 1000, "title": "A Doll's House", "day": "2027-05-21"}]
 200
ana@nft:~/boxoffice$ curl -s 'localhost:8000/search?q=%25' | jq length
20
```

A aspa recebe `200` e um espetáculo, **porque para o banco ela era uma letra**: achou o único título
que tem um apóstrofo, *A Doll's House*. Uma consulta montada colando texto teria falhado nessa aspa e
respondido `500`, e é por isso que uma aspa recebendo uma resposta comum é a evidência que o testador
anota, e um `500` numa aspa é um achado.

O último pedido merece um segundo olhar. `%25` é um sinal de porcentagem, e a busca por ele devolveu
os 20 espetáculos à venda. **Um parâmetro mantém o valor fora do SQL, mas o `LIKE` continua lendo `%`
e `_` como curingas dentro do valor.** Aqui isso é inofensivo, já que `/shows` lista os mesmos 20
espetáculos para qualquer um, e a decisão certa é anotar em vez de corrigir. Numa busca sobre os
registros privados de alguém, o mesmo comportamento seria um achado, e a correção é `LIKE ? ESCAPE
'\'` com os curingas escapados no valor.

## A mesma conferência no serviço de contas

O `account.py` guarda o que um cliente digita e devolve depois, que é a outra metade da pergunta: a
aspa sobrevive à ida e volta como texto?

```
ana@nft:~/boxoffice$ curl -s -c ~/ana.jar -X POST localhost:8001/login -d '{"name": "ana", "password": "correct horse battery"}' | jq -r .token > ~/ana.token
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/bookings -H "Authorization: Bearer $(cat ~/ana.token)" -d '{"show_id": 990, "seat": 12, "holder": "Ana O'\''Brien"}'
{"id": 1}
ana@nft:~/boxoffice$ curl -s localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/ana.token)"
{"show_id": 990, "seat": 12, "holder": "Ana O'Brien"}
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar -o /dev/null -w '%{http_code}\n' "localhost:8001/account?q='"
200
ana@nft:~/boxoffice$ curl -s -b ~/ana.jar "localhost:8001/account?q='" | grep '<li>'
<ul><li>Show 990, seat 12, for Ana O&#x27;Brien
```

O titular `Ana O'Brien` entrou e voltou igual, e a busca por uma aspa achou a reserva dele. Na
página, o apóstrofo chega como `&#x27;`, que é o assunto da próxima seção: o banco e o navegador são
dois intérpretes, e cada um precisa da sua defesa.
