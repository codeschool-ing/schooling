---
title: Instalando o nginx
version: 1
---

O Gunicorn e o Uvicorn não deveriam encarar a internet sozinhos. Um **proxy reverso** fica na frente:
ele encerra o TLS, serve arquivos estáticos do disco, acrescenta cabeçalhos, limita o tamanho das
requisições, e passa o resto à aplicação em `127.0.0.1`. Este curso usa o **nginx**, o mesmo que o
`servers-cache` ensina a fundo.

## Três lugares para tê-lo

| caminho | o que você ganha | o que custa ao seu computador |
|---|---|---|
| **na sua máquina virtual** (recomendado) | o nginx 1.24 do arquivo do Ubuntu, como serviço | alguns megabytes, e um servidor nas portas 80 e 443 da máquina virtual |
| **instalado no seu próprio computador** | o `nginx` do Homebrew no macOS; a versão para Windows do nginx.org, que a própria documentação chama de beta | o mesmo, no computador em que você também trabalha, onde as portas 80 e 443 podem estar ocupadas |
| **online** | o balanceador de carga de uma plataforma de hospedagem, que faz este trabalho sem arquivo de configuração | nada; e os arquivos abaixo viram as configurações da plataforma |

**A máquina virtual é a escolha**: a configuração abaixo nomeia os caminhos do Ubuntu, e é o mesmo
pacote que o `servers-cache` instala.

## Instalando

Na máquina virtual:

```sh
sudo apt update
sudo apt install -y nginx
```

O pacote inicia o nginx com um site padrão, uma página de boas-vindas na porta 80:

```
ana@vm:~/agenda$ nginx -v
nginx version: nginx/1.24.0 (Ubuntu)
ana@vm:~/agenda$ systemctl is-active nginx
active
ana@vm:~/agenda$ curl -s http://127.0.0.1/ | grep -o "<title>.*</title>"
<title>Welcome to nginx!</title>
```
