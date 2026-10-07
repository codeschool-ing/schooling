---
title: Caddy, e uma configuração que é quase só padrão
version: 1
---

O Caddy é o mais novo dos três, escrito em Go, e parte de outra premissa: **o comportamento certo não
deveria precisar de configuração.** O padrão mais conhecido dele é que um site com nome de domínio
ganha um certificado TLS, buscado e renovado pelo próprio Caddy, sem ninguém pedir. A aula 3 mostra
isso funcionando. Aqui ele fica desligado escrevendo `http://` na frente do endereço, porque os nomes
da livraria só existem dentro desta máquina e nenhuma autoridade certificadora conseguiria
verificá-los.

O site inteiro, na porta 8081:

```
ana@web:~$ cat /etc/caddy/Caddyfile
http://ipelivros.example:8081, http://www.ipelivros.example:8081 {
	root * /var/www/ipe
	file_server
	log {
		output file /var/log/caddy/ipelivros.access.log
	}
}
ana@web:~$ caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile 2>&1 | tail -1
Valid configuration
```

Compare com o bloco server do Nginx de duas seções atrás. `root` e os nomes são a mesma ideia;
`file_server` é a linha que diz "sirva arquivos daquela raiz", o que o Nginx supõe e o Caddy quer
dito; e não há diretiva `index`, porque servir `index.html` para um diretório é o padrão. O log é
escrito como um objeto JSON por linha, fácil de consultar e mais difícil de ler a olho; a seção sobre
logs mostra um.

`caddy validate` lê o arquivo do jeito que o serviço vai ler, e é o `nginx -t` do Caddy. Depois suba
e peça a folha de estilo:

```
ana@web:~$ sudo systemctl start caddy
ana@web:~$ curl -sI http://ipelivros.example:8081/css/site.css
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 237
Content-Type: text/css; charset=utf-8
Etag: "tkos406l"
Last-Modified: Tue, 01 Sep 2026 13:00:00 GMT
Server: Caddy
Date: Wed, 07 Oct 2026 03:11:23 GMT
```

O mesmo arquivo, os mesmos bytes, o mesmo `Last-Modified`; um terceiro formato de `ETag`. Repare
também no que o Caddy não disse: nenhuma versão no cabeçalho `Server`, onde o Nginx e o Apache dizem
a versão exata. A aula 4 explica por que isso importa.

## O Caddyfile e o JSON por baixo

Um Caddyfile é uma conveniência. A configuração de verdade do Caddy é um documento JSON, o Caddyfile
é traduzido para ele ao carregar, e esse JSON pode ser mudado num Caddy em execução por uma API em
`localhost:2019`. Isso torna o Caddy fácil de comandar a partir de outro programa, e é por isso que
algumas equipes o rodam sem Caddyfile nenhum. Este curso usa o Caddyfile e nunca precisa da API.

**Onde o Caddy é a escolha certa:** poucos sites que precisam de HTTPS e de muito pouco além disso,
mantidos por alguém que prefere não cuidar de certificados. **Onde ele é menos comum:** na frente de
instalações grandes e antigas, onde a configuração do Nginx já foi escrita, revisada e depurada por
alguém, e a equipe conhece cada diretiva.
