---
title: npm audit, e como ler um alerta
version: 1
---

**O `npm audit` manda ao registry a lista do que você tem instalado e recebe de volta os alertas de
segurança publicados que se aplicam a ela.** Toda instalação o roda, e é dele a linha `found 0
vulnerabilities` embaixo de cada uma até aqui. Para ver como é uma resposta positiva, instale uma
versão antiga do Express num projeto de rascunho, a 4.17.1, de 2019:

```
ana@dev:~/server/audited$ echo '{ "name": "audited", "private": true }' > package.json
ana@dev:~/server/audited$ npm install express@4.17.1

added 50 packages, and audited 51 packages in 609ms

1 package is looking for funding
  run `npm fund` for details

7 vulnerabilities (3 low, 4 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues, run:
  npm audit fix --force

Run `npm audit` for details.
```

```
ana@dev:~/server/audited$ npm audit
# npm audit report

body-parser  <=1.20.5
Severity: high
body-parser vulnerable to denial of service when url encoding is enabled - https://github.com/advisories/GHSA-qwcr-r2fm-qrc7
body-parser vulnerable to denial of service when invalid limit value silently disables size enforcement - https://github.com/advisories/GHSA-v422-hmwv-36x6
Depends on vulnerable versions of qs
fix available via `npm audit fix`
node_modules/body-parser
  express  <=4.21.2 || 5.0.0-alpha.1 - 5.0.0
  Depends on vulnerable versions of body-parser
  Depends on vulnerable versions of cookie
  Depends on vulnerable versions of path-to-regexp
  Depends on vulnerable versions of qs
  Depends on vulnerable versions of send
  Depends on vulnerable versions of serve-static
  node_modules/express

cookie  <0.7.0
cookie accepts cookie name, path, and domain with out of bounds characters - https://github.com/advisories/GHSA-pxg6-pf52-xh8x
fix available via `npm audit fix`
node_modules/cookie


path-to-regexp  <=0.1.12
Severity: high
path-to-regexp outputs backtracking regular expressions - https://github.com/advisories/GHSA-9wv6-86v2-598j
path-to-regexp contains a ReDoS - https://github.com/advisories/GHSA-rhx6-c78j-4q9w
path-to-regexp vulnerable to Regular Expression Denial of Service via multiple route parameters - https://github.com/advisories/GHSA-37ch-88jc-xwx2
fix available via `npm audit fix`
node_modules/path-to-regexp

qs  <=6.15.3
Severity: high
qs vulnerable to Prototype Pollution - https://github.com/advisories/GHSA-hrpp-h998-j3pp
qs's arrayLimit bypass in comma parsing allows denial of service - https://github.com/advisories/GHSA-w7fw-mjwx-w883
qs's arrayLimit bypass in its bracket notation allows DoS via memory exhaustion - https://github.com/advisories/GHSA-6rw7-vpxm-498p
qs: Denial of Service via Attacker Controlled isBuffer - https://github.com/advisories/GHSA-4mjr-xmp4-gh2g
fix available via `npm audit fix`
node_modules/qs

send  <0.19.0
send vulnerable to template injection that can lead to XSS - https://github.com/advisories/GHSA-m6fv-jmcg-4jfg
fix available via `npm audit fix`
node_modules/send
  serve-static  <=1.16.0
  Depends on vulnerable versions of send
  node_modules/serve-static


7 vulnerabilities (3 low, 4 high)

To address all issues, run:
  npm audit fix
```

## Como ler

Cada entrada é um pacote vulnerável, e cada linha dela diz algo de que você precisa:

- **o pacote e a faixa vulnerável**: `qs <=6.15.3`. A sua versão instalada está dentro dela.
- **a severidade**, que é a estimativa do próprio alerta. `high` não é uma emergência por si só, e
  `low` não é seguro de ignorar por si só.
- **o título e o endereço do alerta**, `GHSA-...`, que dizem qual é a falha e em que condições ela
  pode ser usada. Leia: uma negação de serviço num parser que você nunca alimenta com entrada não
  confiável importa menos que uma no parser por trás de toda requisição.
- **o caminho**: o `qs` não é algo que você instalou. O Express depende do `body-parser`, que depende
  do `qs`, e as linhas recuadas dizem isso. A correção para um pacote profundo quase sempre é atualizar
  o pacote direto acima dele.
- **se existe correção**: `fix available via npm audit fix`.

## Corrigindo

O `npm audit fix` atualiza o que der dentro das suas faixas:

```
ana@dev:~/server/audited$ npm audit fix

added 18 packages, changed 23 packages, and audited 69 packages in 717ms

16 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/audited$ npm ls express
audited@ /home/ana/server/audited
└── express@4.22.3
```

As próprias versões de correção do Express 4 bastaram aqui: a 4.x mais nova traz versões corrigidas de
cada pacote do relatório. Quando não bastam, o relatório diz que a correção precisa de uma versão
major, e a decisão da seção anterior é o caminho, com o alerta como motivo para tomá-la agora.

**O que não se faz com um relatório é ignorá-lo até ele ficar longo.** Um projeto auditado toda semana
enfrenta um alerta de cada vez, e um projeto auditado uma vez por ano enfrenta esta tela. O `npm audit
--omit=dev` relata só o que a produção instala, que é a lista que mais importa num servidor.
