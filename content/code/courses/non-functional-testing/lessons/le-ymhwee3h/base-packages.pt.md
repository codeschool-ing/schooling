---
title: Os pacotes da base
version: 1
---

A base é o que todos os terços do curso usam: Python para a aplicação e para dois dos geradores de
carga, Java para o JMeter e o Gatling, SQLite para olhar dentro do banco da aplicação, `curl` e `jq`
para conversar com ela, e `git` para as aulas que varrem um repositório. Tudo vem do próprio
repositório do Ubuntu, num comando só. No shell da VM:

```sh
sudo apt-get update
sudo apt-get install -y curl jq sqlite3 git nano unzip xz-utils python3 python3-venv \
    python3-pip openjdk-21-jdk-headless
```

A maior parte do que ele baixa é Java: o JDK, e não só o runtime, porque o Gatling compila os testes
antes de rodá-los, e um runtime não compila.

Depois confira se cada peça responde:

```
ana@nft:~$ grep PRETTY /etc/os-release; python3 --version
PRETTY_NAME="Ubuntu 24.04.5 LTS"
Python 3.12.3
ana@nft:~$ java -version 2>&1 | head -1; sqlite3 --version | cut -d" " -f1; git --version
openjdk version "21.0.12.1" 2026-08-18
3.45.1
git version 2.43.0
boxoffice/seed.py
boxoffice/app.py
```

As suas versões de correção podem ser mais altas que estas, porque o Ubuntu continua publicando
atualizações da mesma versão; as aulas dependem das versões principais. Se alguma linha disser
`command not found`, a instalação não terminou, e "Quando a montagem falha" é o lugar onde procurar.

Todo o resto é instalado na aula que o usa primeiro:

| aula | o que instala |
|---|---|
| 4 | JMeter, descompactado na sua pasta pessoal |
| 5 | k6, um programa só |
| 6 | Gatling, descompactado na sua pasta pessoal, e Locust num ambiente virtual Python |
| 7 | Node.js, depois o Artillery; e o Vegeta, um programa só |
| 10 | Lighthouse, e o Chromium que o Playwright baixa para ele |
| 13 | o motor do axe, num projeto Playwright próprio |
| 18 | gitleaks, um programa só |
| 21 | pip-audit, no ambiente virtual da aula 6 |
| 22 | Prometheus, do repositório do Ubuntu |
