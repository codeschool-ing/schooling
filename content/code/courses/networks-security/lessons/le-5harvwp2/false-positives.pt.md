---
title: Um falso positivo, e uma exclusão que continua estreita
version: 1
---

Um cliente escreve no formulário de suporte. É um desenvolvedor, e cola a consulta que executou:

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -d "comment=select id from orders where total > 100" https://www.example.com/support
403
root@www:~# grep -o "\[id \"[0-9]*\"\]\|\[msg \"[^\"]*\"\]\|\[data \"[^\"]*\"\]" /var/log/nginx/modsec_audit.log
[id "942100"]
[msg "SQL Injection Attack Detected via libinjection"]
[data "Matched Data: Enknk found within ARGS:comment: select id from orders where total > 100"]
[id "949110"]
[msg "Inbound Anomaly Score Exceeded (Total Score: 5)"]
[data ""]
```

**Recusado.** A regra 942100 encontrou SQL no campo `comment`, o que é verdade: o cliente digitou
SQL, porque esse era o assunto da mensagem. A requisição era legítima e o WAF estava certo sobre o
que viu. Essa combinação é um **falso positivo** (*false positive*), e todo WAF os produz.

As correções erradas são as tentadoras: voltar o motor para o modo somente detecção, ou remover a
regra 942100 de todo lugar. Qualquer uma desliga a proteção do site inteiro para salvar um
formulário. A correção certa é **tão estreita quanto o problema**: esta regra, este campo, este
location.

```
root@www:~# sed -n "/location \/support/,/}/p" /etc/nginx/sites-enabled/shop
    location /support {
        modsecurity_rules 'SecRuleUpdateTargetById 942100 "!ARGS:comment"';
        proxy_pass http://192.168.20.10:8080;
    }
root@www:~# nginx -t 2>&1 | tail -1 && nginx -s reload
nginx: configuration file /etc/nginx/nginx.conf test is successful
2026/09/28 15:24:03 [notice] 32627#32627: ModSecurity-nginx v1.0.3 (rules loaded inline/local/remote: 0/921/0)
2026/09/28 15:24:03 [notice] 32627#32627: signal process started
```

`SecRuleUpdateTargetById` mantém a regra 942100 rodando e tira uma coisa do que ela inspeciona: o
argumento `comment`, e só sob `/support`. Depois, as três requisições que decidem se a exclusão está
certa:

```
ana@remote:~$ curl -s -w "%{http_code}\n" -d "comment=select id from orders where total > 100" https://www.example.com/support
received
200
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -d "comment=<script>alert(1)</script>" https://www.example.com/support
403
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -d "name=select id from orders where total > 100" https://www.example.com/support
403
```

A mensagem do cliente passa. **Script no mesmo campo continua sendo recusado**, porque as regras de
XSS nunca foram tocadas. E SQL em qualquer outro campo do mesmo formulário continua sendo recusado,
porque a exclusão nomeou um campo só.

Uma exclusão é uma decisão de confiar um pouco mais numa entrada, e vale registrar por quê. A
próxima pessoa a ler a configuração vê uma regra desligada para um campo e não tem como saber se
foi uma escolha cuidadosa ou um atalho tomado numa tarde corrida.
