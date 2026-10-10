---
title: Promoção é um pull request
version: 1
---

**Um release chega à produção sendo promovido, e nesta organização promoção é um pull request que faz
a pasta da produção dizer o que a do staging já diz** sobre a coisa sendo promovida, e nada mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Promoção. O repositório da aplicação recebe a tag v1.1 e o CI envia a imagem bulletin:1.1. Um pull request muda a pasta do staging para 1.1, e o staging a roda. Um segundo pull request muda só a linha da imagem na pasta da produção, e a produção a roda.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"270\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"40\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">repo bulletin</text><text x=\"95.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">tag v1.1</text><rect x=\"20\" y=\"170\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95.0\" y=\"190.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">registry</text><text x=\"95.0\" y=\"208.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">bulletin:1.1</text><line x1=\"95\" y1=\"90\" x2=\"95.0\" y2=\"158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"95,166 99.5,158.0 90.5,158.0\" fill=\"var(--paper-dim)\"/><text x=\"105\" y=\"134\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">o CI constrói</text><rect x=\"260\" y=\"40\" width=\"190\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"355.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pull request 1</text><text x=\"355.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">staging: 1.1</text><rect x=\"260\" y=\"170\" width=\"190\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"355.0\" y=\"190.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pull request 2</text><text x=\"355.0\" y=\"208.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">production: 1.1</text><rect x=\"540\" y=\"40\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"620.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">staging</text><text x=\"620.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">roda 1.1</text><rect x=\"540\" y=\"170\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"620.0\" y=\"190.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">production</text><text x=\"620.0\" y=\"208.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">roda 1.1</text><line x1=\"170\" y1=\"195\" x2=\"251.3\" y2=\"81.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"256,75 247.7,78.9 255.0,84.1\" fill=\"var(--paper-dim)\"/><line x1=\"450\" y1=\"65\" x2=\"528.0\" y2=\"65.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"536,65 528.0,60.5 528.0,69.5\" fill=\"var(--phosphor)\"/><line x1=\"450\" y1=\"195\" x2=\"528.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"536,195 528.0,190.5 528.0,199.5\" fill=\"var(--phosphor)\"/><line x1=\"355\" y1=\"90\" x2=\"355.0\" y2=\"158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"355,166 359.5,158.0 350.5,158.0\" fill=\"var(--paper-dim)\"/><text x=\"365\" y=\"134\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">conferido no staging</text></svg>", "caption": "A imagem é construída uma vez e promovida por referência: dois pull requests no fleet, cada um mudando a pasta de um ambiente.", "same": ["registry", "pull request 1", "pull request 2", "staging", "production", "tag v1.1", "bulletin:1.1", "staging: 1.1", "production: 1.1"]}
```

## Um release novo, do lado da aplicação

A versão 1.1 acrescenta uma linha à página, o nome do pod que respondeu, o que torna visíveis os
rollouts das próximas aulas. Este é o `~/bulletin/index.cgi` da 1.1:

```sh
#!/bin/sh
# Answers every request with what this copy of bulletin was given.
echo "Content-Type: text/plain"
echo
echo "bulletin $VERSION"
echo "message: ${MESSAGE:-none}"
echo "pod: $(hostname)"
if [ -r /secrets/token ]; then
  echo "token: sha256:$(sha256sum /secrets/token | cut -c1-12)"
else
  echo "token: none"
fi
```

O CI da aplicação faria o resto numa tag. Aqui você é o CI dela: commit, tag, build a partir do commit
com tag, push da imagem.

```
ana@laptop:~/bulletin$ git diff | grep '^+[^+]'
+echo "pod: $(hostname)"
ana@laptop:~/bulletin$ git commit --quiet -am "Show the pod that answered"
ana@laptop:~/bulletin$ git tag v1.1
ana@laptop:~/bulletin$ git push --quiet origin main v1.1
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.1 -t localhost:5001/bulletin:1.1 .
sha256:c779be3c44cc237f479a70963539914e714a33f64bbbefa9dcbbcb145d415d57
ana@laptop:~/bulletin$ docker push --quiet localhost:5001/bulletin:1.1
localhost:5001/bulletin:1.1
ana@laptop:~/bulletin$ curl -s localhost:5001/v2/bulletin/tags/list
{"name":"bulletin","tags":["1.0","1.1"]}
```

## O staging primeiro

A imagem existe, e nada a roda: um registry não é um deploy. O primeiro pull request leva o staging
para a 1.1, e o webhook da aula 4 a entrega:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-1.1
ana@laptop:~/fleet$ git commit --quiet -am "staging: bulletin 1.1"
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.1
message: Staging is updated by a webhook.
pod: bulletin-5c6966849-qs8ph
token: none
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.0
message: Welcome to the bulletin.
token: none
```

O staging responde como 1.1, com o nome do pod. A produção ainda responde como 1.0, porque nada mandou
outra coisa.

## Depois a produção

Antes da promoção, as duas pastas diferem em tudo o que as torna dois ambientes, e em mais uma linha:

```
ana@laptop:~/fleet$ diff apps/bulletin/staging/bulletin.yaml apps/bulletin/production/bulletin.yaml
4c4
<   name: staging
---
>   name: production
10c10
<   namespace: staging
---
>   namespace: production
12c12
<   replicas: 3
---
>   replicas: 2
23c23
<         image: localhost:5001/bulletin:1.1
---
>         image: localhost:5001/bulletin:1.0
26c26
<           value: Staging is updated by a webhook.
---
>           value: Welcome to the bulletin.
38c38
<   namespace: staging
---
>   namespace: production
46c46
<     nodePort: 30080
---
>     nodePort: 30081
```

O namespace, o número de réplicas, a mensagem e a porta devem diferir. **A imagem é a única diferença
que é um release em trânsito**, e a promoção muda exatamente essa linha:

```
ana@laptop:~/fleet$ git switch --quiet -c production-1.1
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-        image: localhost:5001/bulletin:1.0
+        image: localhost:5001/bulletin:1.1
ana@laptop:~/fleet$ git commit --quiet -am "production: bulletin 1.1"
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-86887c69f-vd55h
token: none
```

O diff do pull request é uma linha, e essa é a propriedade que vale proteger: quem revisa uma promoção
lê o release sendo promovido, e não um merge entre os históricos de dois branches. A aula 6 deixa isso
ainda mais nítido, tirando toda linha que os dois arquivos têm em comum.
