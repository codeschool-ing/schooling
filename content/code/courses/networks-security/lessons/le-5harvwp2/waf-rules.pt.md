---
title: Um firewall de aplicação web lê a requisição
version: 1
---

Um **firewall de aplicação web** (*web application firewall*, WAF) inspeciona cada requisição HTTP
em busca dos padrões de ataques conhecidos contra aplicações web: script injetado numa página, SQL
contrabandeado numa consulta, um caminho escalando para fora do seu diretório. Enquanto as recusas
do proxy nas seções anteriores descrevem o que é permitido, um WAF descreve o que é proibido, o que
faz dele o mesmo tipo de ferramenta que um IDS por assinatura (aula 15).

O laboratório roda o **ModSecurity**, o motor de WAF de código aberto, como módulo do nginx, com o
**OWASP Core Rule Set** (CRS), o conjunto de regras de que a maioria das implantações parte. Ele é
ligado para o site com duas linhas, e seu motor começa no modo **somente detecção**
(*detection-only*). No `www`, escreva o `waf.conf` como ele aparece impresso abaixo e depois faça três
edições. O log de auditoria vai para o diretório de logs do próprio nginx, as duas linhas
`modsecurity` entram abaixo de `client_max_body_size`, e o burst do limite de taxa sobe para 50. A
última é para que os testes desta seção sejam julgados pelo WAF e não recusados pela velocidade:

```sh
# on www, as root
sed -i "s#^SecAuditLog .*#SecAuditLog /var/log/nginx/modsec_audit.log#" /etc/nginx/modsecurity.conf
sed -i "0,/client_max_body_size 16k;/s||client_max_body_size 16k;\n    modsecurity on;\n    modsecurity_rules_file /etc/nginx/waf.conf;|" /etc/nginx/sites-enabled/shop
sed -i "s/limit_req zone=perip burst=10 nodelay;/limit_req zone=perip burst=50 nodelay;/" /etc/nginx/sites-enabled/shop
```

```
root@www:~# cat /etc/nginx/waf.conf; grep -E "^SecRuleEngine" /etc/nginx/modsecurity.conf; grep -n modsecurity /etc/nginx/sites-enabled/shop
include /etc/nginx/modsecurity.conf
include /etc/modsecurity/crs/crs-setup.conf
include /usr/share/modsecurity-crs/rules/*.conf
SecRuleEngine DetectionOnly
16:    modsecurity on;
17:    modsecurity_rules_file /etc/nginx/waf.conf;
root@www:~# nginx -t 2>&1 | grep -o "rules loaded.*"; nginx -s reload
rules loaded inline/local/remote: 0/921/0)
2026/09/28 15:23:59 [notice] 32386#32386: ModSecurity-nginx v1.0.3 (rules loaded inline/local/remote: 0/921/0)
2026/09/28 15:23:59 [notice] 32386#32386: signal process started
```

921 regras carregadas. Para ver se funcionam, envie uma requisição contendo uma string que elas
foram escritas para reconhecer. `<script>alert(1)</script>`, codificado num parâmetro de consulta, é
o teste convencional: inofensivo para uma aplicação bem escrita, e exatamente o que as regras de
cross-site scripting procuram.

```
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" "https://www.example.com/?q=%3Cscript%3Ealert(1)%3C/script%3E"
200
root@www:~# grep -o "\[id \"[0-9]*\"\]\|\[msg \"[^\"]*\"\]" /var/log/nginx/modsec_audit.log
[id "941100"]
[msg "XSS Attack Detected via libinjection"]
[id "941110"]
[msg "XSS Filter - Category 1: Script Tag Vector"]
[id "941160"]
[msg "NoScript XSS InjectionChecker: HTML Injection"]
[id "949110"]
[msg "Inbound Anomaly Score Exceeded (Total Score: 15)"]
```

A requisição foi **atendida**, `200`, e o log de auditoria diz o que o WAF achou dela. Três regras
casaram, cada uma somando a uma **pontuação de anomalia** (*anomaly score*), e a regra 949110
comparou o total, 15, com o limiar e teria bloqueado. No modo somente detecção, ela registra isso e
não faz nada.

**É assim que um WAF deve ser introduzido**: no modo somente detecção, por tempo suficiente para ver
o que ele bloquearia no tráfego real. Passando para o bloqueio, depois de esvaziar o log de auditoria
com `: > /var/log/nginx/modsec_audit.log` e trocar `DetectionOnly` por `On` em
`/etc/nginx/modsecurity.conf`:

```
root@www:~# grep -E "^SecRuleEngine" /etc/nginx/modsecurity.conf; nginx -s reload
SecRuleEngine On
2026/09/28 15:24:01 [notice] 32475#32475: ModSecurity-nginx v1.0.3 (rules loaded inline/local/remote: 0/921/0)
2026/09/28 15:24:01 [notice] 32475#32475: signal process started
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" "https://www.example.com/?q=%3Cscript%3Ealert(1)%3C/script%3E"
403
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" "https://www.example.com/?q=running+shoes"
200
root@www:~# grep -o "\[id \"[0-9]*\"\]\|\[msg \"[^\"]*\"\]" /var/log/nginx/modsec_audit.log
[id "941100"]
[msg "XSS Attack Detected via libinjection"]
[id "941110"]
[msg "XSS Filter - Category 1: Script Tag Vector"]
[id "941160"]
[msg "NoScript XSS InjectionChecker: HTML Injection"]
[id "949110"]
[msg "Inbound Anomaly Score Exceeded (Total Score: 15)"]
```

A string de teste é recusada com `403`, a busca comum é atendida. As mesmas quatro entradas de regra
no log agora descrevem uma requisição que nunca chegou a `app`.

## Como o Core Rule Set decide

O CRS não bloqueia no primeiro casamento. Cada regra que casa soma pontos conforme a gravidade do
padrão, e uma regra final bloqueia se o total alcançar o limiar, 5 por padrão. Um casamento crítico
basta; vários fracos se somam. O **nível de paranoia** (*paranoia level*) decide quantas regras
rodam: o nível 1 é o padrão e mira em poucos falsos positivos, e os níveis mais altos pegam mais ao
custo de bloquear mais tráfego legítimo.

Um WAF tem dois limites:

- **Ele conhece padrões, não a aplicação.** Uma falha na lógica da própria aplicação, como deixar um
  cliente ler o pedido de outro trocando um número, parece uma requisição comum.
- **Ele precisa ler a requisição**, então funciona onde o TLS termina: no proxy, como aqui.
