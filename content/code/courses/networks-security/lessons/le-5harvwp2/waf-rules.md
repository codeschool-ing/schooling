---
title: A web application firewall reads the request
version: 1
---

A **web application firewall** (WAF) inspects each HTTP request for the patterns of known attacks
against web applications: script injected into a page, SQL smuggled into a query, a path climbing out
of its directory. Where the proxy's refusals of the previous sections describe what is allowed, a
WAF describes what is forbidden, which makes it the same kind of tool as a signature IDS (lesson 15).

The lab runs **ModSecurity**, the open-source WAF engine, as an nginx module, with the **OWASP Core
Rule Set** (CRS), the rule set most deployments start from. It is switched on for the site with two
lines, and its engine starts in **detection-only** mode:

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

921 rules loaded. To see whether they work, send a request containing a string they are written to
recognise. `<script>alert(1)</script>`, encoded into a query parameter, is the conventional test:
harmless to a well-written application, and exactly what the rules for cross-site scripting look for.

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

The request was **served**, `200`, and the audit log says what the WAF thought of it. Three rules
matched, each adding to an **anomaly score**, and rule 949110 compared the total, 15, with the
threshold and would have blocked. In detection-only mode it writes that down and does nothing.

**That is how a WAF should be introduced**: in detection-only mode, for long enough to see what it
would block among real traffic. Switched to blocking:

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

The test string is refused with `403`, the ordinary search is served. The same four lines in the log
now describe a request that never reached `app`.

## How the Core Rule Set decides

CRS does not block on the first match. Each rule that matches adds points according to how severe
the pattern is, and a final rule blocks if the total reaches the threshold, 5 by default. One
critical match is enough; several weak ones add up. The **paranoia level** decides how many rules
run at all: level 1 is the default and aims at few false positives, and higher levels catch more at
the cost of blocking more legitimate traffic.

A WAF has two limits worth stating plainly:

- **It knows patterns, not the application.** A flaw in the application's own logic, such as letting
  one customer read another's order by changing a number, looks like an ordinary request.
- **It needs to read the request**, so it works where TLS ends: on the proxy, as here.
