---
title: Cabeçalhos que dizem ao navegador o que recusar
version: 1
---

As duas seções anteriores trataram do que o servidor diz. Estes cabeçalhos são instruções ao
**navegador**: coisas que ele deve recusar em nome deste site, mesmo que o site seja enganado a
pedi-las. Nenhum deles é mandado por padrão:

```
ana@web:~$ curl -sI https://ipelivros.example/ | grep -ciE "^(strict-transport|content-security|x-content-type|referrer-policy|permissions-policy)"
0
```

Cinco linhas num snippet, incluído no bloco server do HTTPS:

```
ana@web:~$ cat /etc/nginx/snippets/security-headers.conf
add_header Strict-Transport-Security "max-age=31536000" always;
add_header X-Content-Type-Options    "nosniff" always;
add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
add_header Permissions-Policy        "camera=(), microphone=(), geolocation=()" always;
add_header Content-Security-Policy   "default-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" always;
ana@web:~$ sudo sed -i 's|    include snippets/ipelivros-tls.conf;|    include snippets/ipelivros-tls.conf;\n    include snippets/security-headers.conf;|' /etc/nginx/sites-available/ipelivros && grep -n 'include snippets' /etc/nginx/sites-available/ipelivros
11:    include snippets/ipelivros-tls.conf;
12:    include snippets/security-headers.conf;
ana@web:~$ curl -sI https://ipelivros.example/ | grep -iE "^(strict-transport|content-security|x-content-type|referrer-policy|permissions-policy)"
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Content-Security-Policy: default-src 'self'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'
```

| cabeçalho | o que diz ao navegador |
|---|---|
| `Strict-Transport-Security` | no próximo ano, use só HTTPS para este nome, mesmo que um link ou uma pessoa digite `http://` |
| `X-Content-Type-Options: nosniff` | acredite no `Content-Type`; não adivinhe que um arquivo servido como texto é um script |
| `Referrer-Policy` | ao seguir um link para outro site, mande só a origem deste site, não o endereço completo da página |
| `Permissions-Policy` | este site nunca usa câmera, microfone nem localização, então recuse qualquer página que peça |
| `Content-Security-Policy` | carregue scripts, estilos, imagens e formulários só destes lugares |

**O `always` importa em cada uma dessas linhas.** Sem ele, o `add_header` acrescenta o cabeçalho só a
respostas de sucesso, como o teste de location da aula 2 mostrou, e as páginas de erro são justamente
as que um atacante procura.

E o HSTS é mandado só por HTTPS, nunca no redirecionamento:

```
ana@web:~$ curl -sI http://ipelivros.example/ | grep -iE "^(HTTP|strict-transport)"
HTTP/1.1 301 Moved Permanently
```

Isso é proposital e correto. Um navegador ignora o HSTS recebido por HTTP simples, porque qualquer um
no caminho poderia tê-lo acrescentado, então mandá-lo ali só pareceria proteção.

## HSTS, e o ano que você não pode desfazer

**O HSTS conserta a única requisição que o HTTPS não protege: a primeira.** Alguém digita
`ipelivros.example`, o navegador tenta `http://` primeiro, e um atacante no Wi-Fi do café responde a
essa requisição antes de o redirecionamento chegar. Depois de uma visita com HSTS, o navegador vai
direto para `https://` por `max-age` segundos, sem nunca perguntar por HTTP.

A mesma propriedade é o perigo dele. **Depois que um navegador viu o cabeçalho, nada que você mude no
servidor o remove até o `max-age` acabar.** Se o HTTPS quebrar nesse ano, um certificado vencido por
exemplo, os visitantes não conseguem passar pelo aviso, porque o HSTS proíbe exatamente isso. Dois
acréscimos o tornam mais forte e ampliam o compromisso: `includeSubDomains` cobre todo nome abaixo
deste, inclusive os que outra equipe roda em HTTP simples; `preload` pede aos navegadores que tragam o
nome na lista embutida deles, o que leva meses para desfazer. Comece com um `max-age` curto, uma hora,
aumente depois de a renovação estar provada, e acrescente os outros dois só quando todo subdomínio
estiver em HTTPS de vez.

## CSP, o que mais faz e o que mais quebra

`Content-Security-Policy` é o mais forte dos cinco: se um atacante conseguir injetar um `<script>`
numa página, por um campo de comentário ou um nome de produto que a aplicação não escapou, o navegador
se recusa a rodá-lo a não ser que tenha vindo de uma origem permitida. A política da livraria diz,
diretiva por diretiva: tudo só deste site (`default-src 'self'`), imagens também de endereços `data:`
embutidos, nenhum outro site pode pôr este num frame (`frame-ancestors 'none'`, o substituto moderno
do `X-Frame-Options`), e formulários só podem enviar para cá.

A página da livraria passa, porque o único script dela é um arquivo próprio, `/js/app.js`. **Uma
página com um script escrito dentro do HTML, ou um atributo `onclick=`, quebra com essa política**, e
isso é a maioria dos sites antigos. É por isso que uma política entra primeiro como
`Content-Security-Policy-Report-Only`: o navegador não bloqueia nada, relata toda violação que teria
bloqueado, e a política é apertada até os relatos pararem. Este curso não tem navegador no
laboratório para mostrar isso, e por isso o CSP é o único cabeçalho aqui conferido só por ser
mandado; no seu computador, as ferramentas de desenvolvedor do navegador listam cada violação no
console.
