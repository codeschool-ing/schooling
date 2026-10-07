---
title: Montando
version: 1
---

Com os pacotes, o usuário e os quatro arquivos no lugar, a `ana` roda a montagem uma vez:

```
ana@vm:~$ sudo bash ~/pontofinal/setup.sh
customers 5079, orders 17012, lines 26620 at 2026-02-28; 31 days of changes
ready: log in again as ana, or run: . ~/.profile
```

A linha antes do `ready` é o gerador contando o que sorteou. **A primeira execução baixa todos os
pacotes de que os seis ambientes precisam, então quase todo o tempo dela é o download.** Na máquina
da gravação os pacotes já estavam lá, então a transcrição mostra só os dados sendo sorteados e
carregados. Uma segunda execução encontra tudo no lugar, confere e para.

Depois entre de novo como `ana`, ou rode `. ~/.profile`, para o shell ler o `/etc/etl.env`. Vá para
`~/etl`, o diretório de trabalho que a montagem criou, e confira o que você tem:

```
ana@vm:~/etl$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/etl$ python --version
Python 3.13.16
ana@vm:~/etl$ airflow version
3.3.2
ana@vm:~/etl$ dbt --version | head -2
Core:
  - installed: 1.12.5
```

E quanto custou:

```
ana@vm:~/etl$ du -sh /var/lib/etl-data /var/lib/etl-pg /opt/etl
19M	/var/lib/etl-data
78M	/var/lib/etl-pg
1.3G	/opt/etl
```

**Os dados são pequenos e as ferramentas não.** Dezenove megabytes de vendas e 1,3 GB de software
para movê-los. Essa proporção é normal num notebook e o contrário da produção, e a lição 19 é onde
os dados ficam grandes o bastante para importar.
