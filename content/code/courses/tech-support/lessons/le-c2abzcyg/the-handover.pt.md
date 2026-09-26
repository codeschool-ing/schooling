---
title: A passagem
version: 1
---

Os donos devem conseguir começar de onde você parou, sem perguntar nada. Então a evidência vai junto com o
chamado, não só uma descrição dela:

```
ana@srv1:~$ mkdir -p ~/esc && sudo tail -n 20 /var/log/nginx/error.log > ~/esc/nginx-error.log && sudo journalctl -u sales-api --no-pager > ~/esc/sales-api.journal && systemctl status sales-api --no-pager > ~/esc/sales-api.status; tar czf sales-502.tar.gz -C ~ esc && tar tzf sales-502.tar.gz && ls -l sales-502.tar.gz
esc/
esc/nginx-error.log
esc/sales-api.status
esc/sales-api.journal
-rw-rw-r-- 1 ana ana 1011 Sep 26 01:09 sales-502.tar.gz
```

**1011 bytes**, três arquivos: os erros recentes do nginx, o journal do serviço e o status dele. E uma
mensagem que se lê sozinha:

```localised
Para:        equipe do sistema de vendas
Impacto:     /sales/ responde 502 para todos das vendas, desde 01:09
Evidência:   nginx no srv1: connect() failed (111: Connection refused) para 127.0.0.1:9000
             nada escuta na 9000; sales-api está failed
             journal: PermissionError: [Errno 13] Permission denied: '/etc/sales/api.conf'
             api.conf é root:root, modo 600; o serviço roda como sales
Não feito:   as permissões do api.conf não foram mudadas: o arquivo é de vocês, e eu não
             sei por que está 600
Anexo:       sales-502.tar.gz (erros do nginx, journal e status do serviço)
Usuários:    avisados de que o sistema está fora e que vocês estão cuidando; próxima
             atualização minha em uma hora
```

Cada linha poupa uma pergunta a quem recebe. **"Não feito"** é a linha que mais falta, e talvez a mais
valiosa: diz em que estado eles vão encontrar as coisas, e que nada foi mudado pelas costas deles.
