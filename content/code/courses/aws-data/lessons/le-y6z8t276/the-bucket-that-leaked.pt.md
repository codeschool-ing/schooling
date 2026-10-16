---
title: O bucket que vazou
version: 1
---

**As exposições do S3 que chegaram ao noticiário foram, via de regra, uma configuração que alguém
escolheu, não uma invasão.** Ninguém adivinhou senha. Um bucket podia ser lido por qualquer um porque
uma política, uma ACL ou uma URL dizia isso, e continuava assim porque nada que alguém olhasse dizia o
contrário. Notícias de buckets expostos com cadastros de clientes, backups e logs correram por anos
antes de a AWS tornar o Block Public Access o padrão, e elas têm três formas.

## Três jeitos de um bucket virar público

**Uma política com `"Principal": "*"` e `"Effect": "Allow"`.** Escrita, tipicamente, para tornar
pública uma pasta de imagens de um site, com um `Resource` de `bucket/*` em vez de `bucket/images/*`, o
que tornou público todo objeto. Basta uma linha:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-logs-prod
make_bucket: quitanda-logs-prod
ana@laptop:~/aws$ printf '203.0.113.7 GET /checkout 200\n' > access.log && aws s3 cp access.log s3://quitanda-logs-prod/web/access.log
upload: ./access.log to s3://quitanda-logs-prod/web/access.log  
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/quitanda-logs-prod/web/access.log
403
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-logs-prod --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::quitanda-logs-prod/*"}]}'
ana@laptop:~/aws$ curl -s -w '%{http_code}\n' http://localhost:4567/quitanda-logs-prod/web/access.log
203.0.113.7 GET /checkout 200
200
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-logs-prod
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:4567/quitanda-logs-prod/web/access.log
403
```

**O `curl` não tem credencial nenhuma, e recebeu o arquivo.** Esse é o teste de que algo é público, e
o único em que vale confiar: uma requisição de fora, assinada por ninguém. Remover a política faz a
mesma requisição voltar a falhar. O moto avalia esse tipo de `Allow`, e é por isso que a demonstração
funciona aqui; o que o moto não faz é deixar o Block Public Access barrá-lo, como a seção sobre as
chaves mostrou.

**Uma ACL dando `READ` a todo mundo.** O grupo `AllUsers` numa ACL é a internet inteira. Havia um pior,
`AuthenticatedUsers`, cujo nome soava seguro: quer dizer qualquer conta da AWS no mundo, não qualquer
usuário seu. ACLs podiam ser postas objeto por objeto, então um bucket com uma política perfeitamente
privada podia guardar objetos públicos que ninguém tinha notado. O `BucketOwnerEnforced` acaba com
essa forma de vez.

**Uma URL pré-assinada que viveu demais.** Uma URL válida por sete dias, colada num chamado de
suporte, num canal de chat ou numa issue pública, é um link público de sete dias para o objeto,
legível por qualquer um que ache o texto. Nada na configuração do bucket mostra isso, porque nada é
guardado.

## Prevenindo

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"Quatro camadas aninhadas em volta de um objeto, que uma requisição sem credenciais vinda de fora precisa atravessar: o Block Public Access da conta, o do bucket, a política do bucket, onde um Deny vence, e o Object Ownership com as ACLs desligadas. Ao lado de cada camada, o que o moto faz com ela: guarda os dois Block Public Access sem aplicar; aplica um Deny sem ler a condição; guarda o Object Ownership e ainda aceita ACLs.\" data-fig=\"l04-layers\"><defs><marker id=\"bpa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"200.0\" y=\"20.0\" width=\"500.0\" height=\"330.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Block Public Access da conta</text><text x=\"688.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: guarda, não aplica</text><rect x=\"222.0\" y=\"56.0\" width=\"456.0\" height=\"278.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Block Public Access do bucket</text><text x=\"666.0\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: guarda, não aplica</text><rect x=\"244.0\" y=\"92.0\" width=\"412.0\" height=\"226.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"256.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">política do bucket: um Deny vence</text><text x=\"644.0\" y=\"106.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: aplica o Deny, ignora a condição</text><rect x=\"266.0\" y=\"128.0\" width=\"368.0\" height=\"174.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Object Ownership: ACLs desligadas</text><text x=\"622.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moto: guarda, ainda aceita ACLs</text><rect x=\"308.0\" y=\"184.0\" width=\"284.0\" height=\"82.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o objeto</text><text x=\"20.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma requisição</text><text x=\"20.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem credenciais</text><path d=\"M150.0 190.0 L306.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#bpa-ah)\"></path></svg>", "caption": "O que fica entre a internet e um objeto, de fora para dentro, e o que o moto faz com cada camada. Na AWS cada uma recusa sozinha; no moto, das quatro, só o Deny da política do bucket recusa alguma coisa."}
```

A ordem importa, da rede mais larga para a mais estreita:

1. **Block Public Access na conta**, as quatro chaves, para que nenhum bucket criado depois possa
   ser tornado público por uma política ou uma ACL.
2. **Object Ownership `BucketOwnerEnforced` em todo bucket**, para que as ACLs não sejam um segundo
   lugar onde se concede acesso.
3. **Políticas de bucket que negam**: só TLS, só a própria organização, da seção anterior.
4. **URLs pré-assinadas curtas e estreitas**: minutos, assinadas por um papel que lê um prefixo.

Numa organização, uma service control policy do tipo que a lição 4 de `aws-foundations` descreveu
pode negar `s3:PutAccountPublicAccessBlock` a todo mundo menos um papel de segurança, para que a
primeira chave não possa ser desligada de dentro de uma conta.

## Detectando

A prevenção falha, então alguém precisa ser avisado quando ela falhar. A documentação da AWS descreve
quatro serviços para isso, e nenhum deles pode rodar contra o moto:

| serviço | o que responde |
|---|---|
| IAM Access Analyzer for S3 | quais buckets estão compartilhados fora da conta ou da organização, e por onde: uma política, uma ACL, um access point |
| Amazon Macie | quais objetos guardam dados sensíveis, como nomes, CPFs e números de cartão, amostrando o conteúdo deles |
| Data events do CloudTrail | quem leu ou escreveu qual objeto, e quando; desligados por padrão e cobrados por evento, porque um bucket movimentado produz milhões |
| Regras do AWS Config | se cada bucket mantém uma configuração definida, como as regras gerenciadas `s3-bucket-public-read-prohibited` e `s3-bucket-level-public-access-prohibited` |

**Eles respondem a perguntas diferentes, e a diferença é o ponto.** O Access Analyzer diz que uma
porta está aberta. O Macie diz o que há atrás dela. Os data events do CloudTrail dizem quem passou por
ela, que é a pergunta que decide se uma exposição virou vazamento, e só respondem se estavam ligados
antes de acontecer. O Config diz que a porta estava fechada ontem e está aberta hoje.

Nada disso foi rodado aqui; está descrito a partir da documentação da AWS. A única verificação que
este laboratório pode rodar, e a que vale manter numa conta real, é o `curl` anônimo acima: peça um
objeto sem credenciais, de fora, e espere `403`.
