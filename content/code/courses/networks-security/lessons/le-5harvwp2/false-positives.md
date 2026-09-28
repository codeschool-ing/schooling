---
title: A false positive, and an exclusion that stays narrow
version: 1
---

A customer writes to the support form. They are a developer, and they paste the query they ran:

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

**Refused.** Rule 942100 found SQL in the `comment` field, which is true: the customer typed SQL,
because that was the subject of their message. The request was legitimate and the WAF was right
about what it saw. That combination is a **false positive**, and every WAF produces them.

The wrong fixes are the tempting ones: switch the engine back to detection-only, or remove rule
942100 everywhere. Either turns the protection off for the whole site to rescue one form. The right
fix is **as narrow as the problem**: this rule, this field, this location.

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

`SecRuleUpdateTargetById` keeps rule 942100 running and removes one thing from what it inspects: the
argument `comment`, and only under `/support`. Then the three requests that decide whether the
exclusion is right:

```
ana@remote:~$ curl -s -w "%{http_code}\n" -d "comment=select id from orders where total > 100" https://www.example.com/support
received
200
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -d "comment=<script>alert(1)</script>" https://www.example.com/support
403
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -d "name=select id from orders where total > 100" https://www.example.com/support
403
```

The customer's message goes through. **Script in the same field is still refused**, because the XSS
rules were never touched. And SQL in any other field of the same form is still refused, because the
exclusion named one field.

An exclusion is a decision to trust one input a little more, and it is worth writing down why. The
next person to read the configuration sees a rule switched off for a field and has no way to know
whether it was a careful choice or a shortcut taken on a busy afternoon.
