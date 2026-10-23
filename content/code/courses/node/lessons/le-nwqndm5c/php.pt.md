---
title: PHP
version: 1
---

**O PHP roda uma fatia muito grande dos sites da web**, o WordPress à frente. O modelo dele é o mais
antigo dos seis e o mais diferente: **um programa PHP não roda um servidor.** Um servidor web roda o
arquivo PHP uma vez por pedido, do começo, e tudo o que ele montou é jogado fora quando a resposta é
mandada.

```sh
sudo apt install php8.3-cli        # Ubuntu and WSL
brew install php                   # a Mac, with Homebrew (not run for this course)
```

```
ana@dev:~/server/other/php$ php --version
PHP 8.3.6 (cli) (built: Oct 19 2026 15:16:58) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.6, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.6, Copyright (c), by Zend Technologies
```

```schooling-example
{"language": "php", "file": "hello.php", "parts": [
 {"code": "<?php\n// hello.php: the same server in PHP. Each request runs this file from the top.\n$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);\nheader('content-type: application/json');", "note": "**O arquivo é o handler.** Não há `listen` nem função de roteamento: o pedido já está em variáveis quando a primeira linha roda."},
 {"code": "if ($path === '/hello') {\n    echo json_encode(['hello' => $_GET['name'] ?? 'world']);\n} elseif ($path === '/slow') {\n    sleep(1);\n    echo json_encode(['slept' => 1000]);\n} else {\n    http_response_code(404);\n    echo json_encode(['error' => \"nothing at $path\"]);\n}", "note": "**O `$_GET` é a query string, já lida**, e o `json_encode` faz parte da linguagem. O `echo` escreve o corpo da resposta."}
]}
```

O PHP tem um servidor web pequeno embutido, para desenvolvimento, que roda um arquivo a cada pedido. A
porta vai na linha de comando dele em vez de no `PORT`, porque o programa é o servidor, não o arquivo:

```
ana@dev:~/server/other/php$ php -S 127.0.0.1:3000 hello.php
[Thu Oct 22 20:11:34 2026] PHP 8.3.6 Development Server (http://127.0.0.1:3000) started
[Thu Oct 22 20:11:34 2026] 127.0.0.1:35538 Accepted
[Thu Oct 22 20:11:34 2026] 127.0.0.1:35538 Closed without sending a request; it was probably just an unused speculative preconnection
[Thu Oct 22 20:11:34 2026] 127.0.0.1:35538 Closing
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35540 Accepted
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35540 Closing
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35542 Accepted
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35542 Closing
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35558 Accepted
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35572 Accepted
[Thu Oct 22 20:11:36 2026] 127.0.0.1:35572 Closing
[Thu Oct 22 20:11:36 2026] 127.0.0.1:35576 Accepted
[Thu Oct 22 20:11:37 2026] 127.0.0.1:35558 Closing
[Thu Oct 22 20:11:37 2026] 127.0.0.1:35592 Accepted
[Thu Oct 22 20:11:38 2026] 127.0.0.1:35576 Closing
[Thu Oct 22 20:11:38 2026] 127.0.0.1:35594 Accepted
[Thu Oct 22 20:11:39 2026] 127.0.0.1:35592 Closing
[Thu Oct 22 20:11:39 2026] 127.0.0.1:35604 Accepted
[Thu Oct 22 20:11:40 2026] 127.0.0.1:35594 Closing
[Thu Oct 22 20:11:40 2026] 127.0.0.1:35610 Accepted
[Thu Oct 22 20:11:41 2026] 127.0.0.1:35604 Closing
[Thu Oct 22 20:11:41 2026] 127.0.0.1:35626 Accepted
[Thu Oct 22 20:11:42 2026] 127.0.0.1:35610 Closing
[Thu Oct 22 20:11:42 2026] 127.0.0.1:35632 Accepted
[Thu Oct 22 20:11:43 2026] 127.0.0.1:35626 Closing
[Thu Oct 22 20:11:43 2026] 127.0.0.1:35636 Accepted
[Thu Oct 22 20:11:44 2026] 127.0.0.1:35632 Closing
[Thu Oct 22 20:11:45 2026] 127.0.0.1:35636 Closing
^C
```

```
ana@dev:~/server/other/php$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}
ana@dev:~/server/other/php$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at \/nope"} 404
ana@dev:~/server/other/php$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m10.017s
user	0m0.034s
sys	0m0.027s
```

**As respostas concordam, a não ser pelo `\/`**: o `json_encode` escapa as barras, o que o JSON permite
e nenhum leitor estranha. **E dez pedidos lentos levaram dez segundos.** O servidor embutido atende um
pedido por vez, então cada `sleep(1)` esperou o anterior. Dá para mandar ele iniciar mais processos:

```
ana@dev:~/server/other/php$ PHP_CLI_SERVER_WORKERS=10 php -S 127.0.0.1:3000 hello.php
[1186] [Thu Oct 22 20:11:47 2026] PHP 8.3.6 Development Server (http://127.0.0.1:3000) started
[1187] [Thu Oct 22 20:11:47 2026] PHP 8.3.6 Development Server (http://127.0.0.1:3000) started
^C
```

```
ana@dev:~/server/other/php$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.017s
user	0m0.025s
sys	0m0.032s
```

**Dez processos, um segundo.** É essa a resposta do PHP à concorrência, e em produção ela é o
**PHP-FPM**, um pool de processos PHP atrás do nginx ou do Apache, cada um atendendo um pedido por vez. O
modelo tem uma propriedade a que este curso dedicou uma seção: **nada sobrevive entre pedidos**, então o
problema que a aula 10 achou no `cluster` não pode acontecer. Todo pedaço de estado fica num banco, num
cache ou no store de sessões desde o início, porque não há outro lugar para pô-lo.

| o quê | em termos de Node |
|---|---|
| **Laravel** ou **Symfony** | Express, com camada de banco e mais incluídos |
| **Composer**, e o `composer.json` | `npm` e `package.json` |
| PHP-FPM atrás do nginx | `node server.js` atrás de um proxy |
