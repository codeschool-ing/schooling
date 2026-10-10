---
title: Escolhendo entre eles
version: 1
---

**Os três não são rivais; cada um responde uma pergunta diferente sobre quem está chamando.** Uma API de
verdade costuma aceitar dois deles, como o `keys.py` aceita os três: pessoas entram e recebem tokens,
programas recebem chaves, e o Basic fica, se ficar, para scripts e testes.

| | identifica | onde encaixa | a fraqueza |
|---|---|---|---|
| **Basic** | uma pessoa, por nome e senha | scripts e ferramentas internas, sempre sobre HTTPS | a senha viaja e é conferida em toda requisição, e o acesso só acaba quando a senha muda |
| **token bearer** | uma pessoa, depois de um login | tudo em que uma pessoa entra: um site, um app | quem o tiver é aquela pessoa até ele vencer ou ser revogado |
| **chave de API** | uma aplicação | um programa chamando outro, sem ninguém olhando | vale até alguém revogá-la, então uma chave vazada continua útil até alguém perceber |

Três perguntas resolvem a maioria dos casos:

1. **Tem alguém ali?** Uma pessoa que entra uma vez e trabalha por uma hora quer um token. Um programa
   que roda às três da manhã quer uma chave.
2. **Quem o log deve nomear?** Se a resposta é "o parceiro", é uma chave, porque a senha de uma pessoa
   na configuração de um parceiro nomeia a parte errada e vai embora com a pessoa.
3. **Com que rapidez o acesso precisa acabar?** Um token acaba sozinho e no logout; uma chave acaba
   quando é revogada; o Basic acaba quando a senha muda, em todo lugar ao mesmo tempo.

O que os três precisam, seja qual for a escolha, é o que as seções anteriores desta lição mostraram:
HTTPS no caminho (lição 13), um cabeçalho e nunca uma URL, um hash e nunca o segredo no armazenamento,
uma comparação que leva sempre o mesmo tempo, e uma recusa que não diz nada.

## Limpando

Três arquivos em `~/shelf` guardam credenciais que ainda valem, e um laboratório é um bom lugar para
praticar não deixá-las por aí. Saia, revogue a chave que sobrou e apague os arquivos:

```
ana@api:~/shelf$ curl -s -X POST -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/logout
ana@api:~/shelf$ curl -s -u ana:river-lamp-42 -X DELETE localhost:8000/v1/keys/$(jq -r .prefix partner-new.json)
ana@api:~/shelf$ rm login.json partner.json partner-new.json
ana@api:~/shelf$ ls
__pycache__
db.py
keys.py
rest.py
shelf.db
```

Depois pare o `keys.py` com `Ctrl+C` no segundo terminal. As próximas lições começam de novo pelo
`rest.py`, e os usuários e as tabelas que o `keys.py` acrescentou ao `shelf.db` ficam lá, sem uso por
ele.
