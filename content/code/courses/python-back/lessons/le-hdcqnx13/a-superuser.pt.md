---
title: Um superusuário, e ler o admin
version: 1
---

O admin do Django é um painel administrativo completo gerado a partir dos seus modelos: listas, busca,
filtros, formulários para incluir e alterar linhas, um histórico de quem mudou o quê. Ele está em
`/admin/` desde a aula 2, porque o `startproject` o pôs no `config/urls.py`. O que ele precisa antes
de tudo é de alguém com permissão para entrar.

## A primeira conta

Um **superusuário** é uma conta com todas as permissões. O `createsuperuser` pede um nome, um
endereço e uma senha, duas vezes, quando você o roda num terminal. O mesmo comando aceita tudo de uma
vez, e foi assim que ele rodou aqui, para a transcrição poder ser reproduzida:

```
ana@vm:~/agenda$ DJANGO_SUPERUSER_PASSWORD='x9-river-lantern-42' uv run python manage.py createsuperuser --noinput --username ana --email ana@example.org
Superuser created successfully.
```

Digite de forma interativa na sua máquina, `uv run python manage.py createsuperuser`, e a senha nunca
aparece na tela nem no histórico do shell. **A aula 11 é sobre para onde a senha foi**: não para o
banco do jeito que você digitou.

## Abrir no navegador

O admin é um site para navegador, e a sua máquina virtual não tem um. Dois jeitos de chegar a ele a
partir do computador em volta, nenhum rodado para este curso:

- **Um túnel SSH**, se você já consegue entrar na máquina virtual com `ssh`: no seu computador,
  `ssh -L 8000:127.0.0.1:8000 ana@<o endereço da máquina>` mantém aberta uma conexão que leva a porta
  8000 do seu computador para a da máquina. Depois abra `http://127.0.0.1:8000/admin/` no seu
  navegador, com o `runserver` rodando na máquina como sempre.
- **Uma regra de redirecionamento de porta** nas configurações de rede do VirtualBox, da porta 8000
  do seu computador para a do convidado, com `runserver 0.0.0.0:8000` para o Django escutar além da
  própria máquina. Navegar até o endereço da própria máquina, numa rede em modo bridge, também
  funciona depois que o `ALLOWED_HOSTS` citar esse endereço, o que a aula 15 faz direito.

## Ler no terminal

Para que toda tela aqui seja uma captura, esta aula lê as páginas do admin como texto, com o
**w3m**, um navegador web que roda no terminal:

```sh
sudo apt install -y w3m
```

Um script pequeno busca uma página com o curl, guardando os cookies de login num arquivo, e entrega o
HTML ao w3m para diagramar. Salve como `~/.local/bin/page` e torne executável com
`chmod +x ~/.local/bin/page`:

```sh
#!/bin/sh
# ~/.local/bin/page
# Print one of agenda's pages as text, keeping the admin's login cookies.
curl -s -b "$HOME/admin-cookies.txt" -c "$HOME/admin-cookies.txt" \
  "http://127.0.0.1:8000$1" | w3m -dump -T text/html -cols 100
```

O `~/.local/bin` está no seu `PATH` desde o `pipx ensurepath` da aula 1, então `page /admin/`
funciona de qualquer diretório. Pedir o admin sem fazer login rende um redirecionamento para o
formulário de login:

```
ana@vm:~/agenda$ curl -si http://127.0.0.1:8000/admin/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /admin/login/?next=/admin/
```

Fazer login é a dança do CSRF da aula 3: buscar o formulário para ganhar o cookie, depois mandar o
token, o nome e a senha com ele.

```
ana@vm:~/agenda$ curl -s -c ~/admin-cookies.txt -o /dev/null http://127.0.0.1:8000/admin/login/
ana@vm:~/agenda$ TOKEN=$(grep csrftoken ~/admin-cookies.txt | cut -f7); curl -si -b ~/admin-cookies.txt -c ~/admin-cookies.txt -d "csrfmiddlewaretoken=$TOKEN&username=ana&password=x9-river-lantern-42&next=/admin/" http://127.0.0.1:8000/admin/login/ | grep -E "^(HTTP|Location)"
HTTP/1.1 302 Found
Location: /admin/
```

Um **302 para `/admin/`** quer dizer que a senha foi aceita e o arquivo de cookies agora guarda uma
sessão. A página inicial, como o w3m a diagrama:

```
ana@vm:~/agenda$ page /admin/ | sed -n "/^Site administration/,/^Recent actions/p"
Site administration

      Authentication and Authorization
Model name Add link Change or view list link
  Groups   Add      Change
  Users    Add      Change

Recent actions
```

**Só o app do próprio Django está lá**: grupos e usuários. O app events tem modelos e nenhuma
configuração de admin ainda, e o admin não mostra nada de que não foi avisado.
