---
title: Nunca mudar o conteúdo de uma URL
version: 1
---

A limpeza funciona num cache que você controla. Ela não alcança a cópia no navegador de um visitante,
a quem disseram que a folha de estilo vale por uma hora e que vai acreditar nisso por uma hora. **O
jeito de contornar uma cópia que ninguém consegue limpar é garantir que nenhuma cópia fique errada: o
conteúdo de um arquivo nunca muda numa URL, e uma versão nova ganha uma URL nova.**

O jeito comum de nomear uma versão é com alguns caracteres do hash do próprio arquivo:

```
ana@web:~$ cd /var/www/ipe/css && sha256sum site.css | cut -c1-8
c867bf6d
ana@web:~$ cd /var/www/ipe/css && sudo cp site.css site.$(sha256sum site.css | cut -c1-8).css && ls
site.c867bf6d.css
site.css
ana@web:~$ sudo sed -i 's|/css/site.css|/css/site.c867bf6d.css|' /var/www/ipe/index.html && grep stylesheet /var/www/ipe/index.html
<link rel="stylesheet" href="/css/site.c867bf6d.css">
```

`site.c867bf6d.css` é a folha de estilo como ela é hoje. Quando alguém a edita, o hash muda, o arquivo
novo é `site.<outro hash>.css`, e o HTML aponta para o nome novo. Todo navegador que carrega o HTML novo
pede um arquivo que nunca viu, então a cópia antiga do nome antigo simplesmente nunca mais é pedida. Nada
precisou ser limpo, e nada podia estar velho.

Isso torna honesto o cabeçalho de cache mais forte:

```
ana@web:~$ cat /etc/nginx/snippets/versioned-assets.conf
# A file whose name carries eight hex digits of its own hash never changes:
# a new version is a new name. Keep it for a year and never ask again.
location ~* "\.[0-9a-f]{8}\.(css|js)$" {
    add_header Cache-Control "public, max-age=31536000, immutable";
}
ana@web:~$ sudo sed -i '0,/    index index.html;/s//    index index.html;\n    include snippets\/versioned-assets.conf;/' /etc/nginx/sites-available/ipelivros && grep -n 'versioned' /etc/nginx/sites-available/ipelivros
16:    include snippets/versioned-assets.conf;
ana@web:~$ curl -sI https://ipelivros.example/css/site.c867bf6d.css | grep -iE '^(HTTP|cache-control)'
HTTP/1.1 200 OK
Cache-Control: public, max-age=31536000, immutable
```

Um ano, e `immutable`, que diz ao navegador para nem revalidar quando a pessoa aperta recarregar. A
expressão regular está entre aspas porque o Nginx lê `{` como começo de um bloco; sem as aspas, o
`nginx -t` recusa o arquivo. Uma coisa ainda precisa ter vida curta para tudo isso funcionar: **o HTML
que dá nome aos arquivos.** Ele é o único lugar onde o nome novo aparece, então leva um tempo de vida
curto ou `no-cache`, e todo arquivo para o qual ele aponta pode ficar em cache para sempre.

Fazer isso à mão para cada arquivo é pedir erro, e na prática quem faz é a etapa de build de um projeto
front-end: todo bundler (Vite, webpack, esbuild) grava nomes de arquivo com hash e reescreve o HTML para
bater. O único trabalho do servidor é o cabeçalho.
