---
title: Mantido rodando pelo systemd
version: 2
---

Uma imagem não é um serviço. Algo precisa subi-la, reiniciá-la quando morre e subi-la de novo quando o
servidor liga, e num servidor Linux esse algo é o **systemd**. O *Quadlet* do Podman escreve o serviço do
systemd por você a partir de um arquivo curto:

```schooling-example
{"language": "ini", "file": "deploy/loanbook.container", "parts": [{"code": "[Unit]\nDescription=loanbook, the equipment loan register", "note": "Um arquivo Quadlet: o Podman lê os arquivos `.container` em `/etc/containers/systemd/` e transforma cada um num serviço do systemd. A seção `[Unit]` é do próprio systemd."}, {"code": "[Container]\nImage=localhost/loanbook:latest\nPublishPort=127.0.0.1:8000:8000", "note": "A imagem construída um momento antes, e a porta dela publicada só em `127.0.0.1`. Nada de fora do servidor chega nela diretamente; o Caddy chega, e o Caddy é a única porta."}, {"code": "Volume=loanbook-data:/data:U", "note": "O banco mora num volume com nome, fora do container, então sobrevive à troca do container. `:U` entrega o volume ao usuário do container, o 1000, que de outro modo não conseguiria escrever nele."}, {"code": "HealthCmd=python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')\"\nHealthInterval=30s", "note": "A cada trinta segundos o Podman pergunta ao `/healthz` de dentro do container. Uma falha marca o container como não saudável, que é o que um monitor olha."}, {"code": "[Service]\nRestart=always\n\n[Install]\nWantedBy=multi-user.target", "note": "`Restart=always` traz de volta quando morre; `WantedBy` sobe no boot. Juntos, são o que *continua no ar* quer dizer."}]}
```

Instalar é uma cópia e dois comandos:

```
ana@srv:~/loanbook$ cat deploy/loanbook.container
[Unit]
Description=loanbook, the equipment loan register

[Container]
Image=localhost/loanbook:latest
PublishPort=127.0.0.1:8000:8000
Volume=loanbook-data:/data:U
HealthCmd=python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')"
HealthInterval=30s

[Service]
Restart=always

[Install]
WantedBy=multi-user.target
ana@srv:~/loanbook$ sudo cp deploy/loanbook.container /etc/containers/systemd/
ana@srv:~/loanbook$ sudo systemctl daemon-reload
ana@srv:~/loanbook$ sudo systemctl start loanbook
ana@srv:~/loanbook$ systemctl status loanbook --no-pager | head -4
● loanbook.service - loanbook, the equipment loan register
     Loaded: loaded (/etc/containers/systemd/loanbook.container; generated)
     Active: active (running) since Wed 2026-10-07 10:58:47 UTC; 3s ago
   Main PID: 2143 (conmon)
ana@srv:~/loanbook$ curl -s 127.0.0.1:8000/healthz
{"ok": true}
```

`daemon-reload` faz o systemd ler o arquivo novo e gerar o `loanbook.service`; `status` mostra ele ativo,
com o monitor do container, o `conmon`, como processo principal. E o `/healthz` responde do próprio
servidor. O banco começa vazio, então o script de dados de exemplo da aula 17 roda **dentro** do
container, onde o banco está:

```
ana@srv:~/loanbook$ sudo podman exec systemd-loanbook python3 seed.py
seeded 8 items, 4 of them out
```

Duas decisões no arquivo da unidade carregam a maior parte do peso. A porta é publicada só em `127.0.0.1`,
então **o container não é alcançável pela rede**: a próxima seção põe o Caddy na frente, e o Caddy é a única
entrada. E os dados estão num **volume com nome**, não no container, então trocar o container por uma imagem
nova, que é o que todo deploy futuro faz, mantém cada empréstimo.
