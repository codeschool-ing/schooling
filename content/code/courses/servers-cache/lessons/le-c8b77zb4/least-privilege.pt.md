---
title: Menor privilégio, dos processos para baixo
version: 1
---

Tudo até aqui supõe que os programas estão corretos. Esta seção é sobre o dia em que um deles não
está: uma falha no código da loja, ou numa biblioteca que ela usa, deixa alguém rodar um comando como
a loja. **O que essa pessoa pode fazer em seguida é decidido pelo que a loja podia fazer**, e isso foi
decidido muito antes.

Cada programa já roda com o próprio usuário, e nenhum deles como root depois de subir:

```
ana@web:~$ ps -o user,pid,cmd -C nginx | head -n 3; ps -o user,pid,cmd -C python3
USER         PID CMD
root         177 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data    1647 nginx: worker process
USER         PID CMD
shop          83 /usr/bin/python3 /opt/shop/shop.py
shop          84 /usr/bin/python3 /opt/shop/shop.py
ana@web:~$ sudo -u www-data touch /var/www/ipe/defaced.html
touch: cannot touch '/var/www/ipe/defaced.html': Permission denied
```

O mestre do Nginx mantém o root só para abrir portas abaixo de 1024 e ler a chave privada; os workers
que atendem cada requisição são `www-data`, e o `www-data` não consegue gravar um único arquivo do
site. A loja roda como `shop`. E nada que não precise ser alcançado de fora é:

```
ana@web:~$ sudo ss -ltn | awk 'NR>1 {print $4}' | sort
0.0.0.0:443
0.0.0.0:80
127.0.0.1:14000
127.0.0.1:15000
127.0.0.1:8001
127.0.0.1:8002
127.0.0.53%lo:53
127.0.0.54:53
```

Só o Nginx escuta em todos os endereços. A loja, o Pebble e o resolvedor de DNS local escutam só no
loopback, então o único jeito de alcançar a loja de outra máquina é pelo Nginx e pelas regras dele.
**Um firewall acrescenta uma segunda camada, independente** (no Ubuntu, `sudo ufw allow 22,80,443/tcp`
e depois `sudo ufw enable`), e ele não foi rodado na máquina em que este curso foi gravado, cuja rede
já é privada; num servidor com endereço público, é a primeira coisa a configurar, antes de subir os
servidores da aula 1.

## Cercando a aplicação com o systemd

O systemd consegue tirar de um serviço o que o usuário dele sozinho não tira: o direito de gravar em
qualquer lugar além do próprio diretório, de ver as pastas pessoais de outros usuários, de carregar
módulos do kernel, de ganhar privilégios por um programa `setuid`. O `systemd-analyze security` dá uma
nota para quão exposto um serviço está:

```
ana@web:~$ systemd-analyze security shop@1.service --no-pager | tail -n 1
→ Overall exposure level for shop@1.service: 9.2 UNSAFE :-{
ana@web:~$ cat /etc/systemd/system/shop@.service.d/hardening.conf
[Service]
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/lib/shop
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
RestrictNamespaces=yes
LockPersonality=yes
SystemCallArchitectures=native
CapabilityBoundingSet=
```

`ProtectSystem=strict` torna o sistema de arquivos inteiro somente leitura para o serviço, exceto os
caminhos em `ReadWritePaths`, aqui o banco da loja. `NoNewPrivileges` quer dizer que nenhum programa
que a loja inicie pode ficar mais privilegiado que a loja. O resto fecha o kernel, os dispositivos e
os tipos de socket que a loja não usa. Um arquivo drop-in em `shop@.service.d/` os acrescenta à unidade
sem editá-la:

```
ana@web:~$ sudo systemctl daemon-reload && sudo systemctl restart shop@1 shop@2 && systemctl is-active shop@1 shop@2
active
active
ana@web:~$ systemd-analyze security shop@1.service --no-pager | tail -n 1
→ Overall exposure level for shop@1.service: 3.6 OK :-)
ana@web:~$ curl -s -X PUT -d '{"price_cents": 5290}' https://ipelivros.example/api/books/1 | jq -c '{id, price_cents}'
{"id":1,"price_cents":5290}
```

De 9.2 para 3.6, e a loja continua respondendo e gravando preços no banco. O que isso compra fica mais
fácil de ver com uma conta mais forte que a `shop`. O usuário `shop` não consegue gravar o código que
roda, porque o arquivo pertence ao root; e com as mesmas duas configurações, **nem o root** consegue
gravar fora do único diretório que recebeu:

```
ana@web:~$ sudo -u shop touch /opt/shop/shop.py
touch: cannot touch '/opt/shop/shop.py': Permission denied
ana@web:~$ sudo systemd-run --wait --pipe -p ProtectSystem=strict -p ReadWritePaths=/var/lib/shop sh -c 'touch /var/lib/shop/ok && echo wrote /var/lib/shop/ok; touch /opt/shop/x' 2>&1 | head -n 3
Running as unit: run-u135.service
wrote /var/lib/shop/ok
touch: cannot touch '/opt/shop/x': Read-only file system
```

`Read-only file system`, para o root. Cada uma dessas camadas supõe que a anterior já falhou, e é isso
que as torna valiosas juntas.

**E um vazamento que esta aula escolheu manter:** o `X-Served-By` ainda conta a todo visitante qual
cópia da loja respondeu. É útil enquanto se aprende, e as próximas aulas o leem. Num site de produção,
`proxy_hide_header X-Served-By;` no location da API o remove, pelo mesmo motivo de o número de versão
ter saído na primeira seção.
