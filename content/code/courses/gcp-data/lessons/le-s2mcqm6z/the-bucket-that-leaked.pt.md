---
title: O bucket que vazou
version: 1
---

**Os buckets públicos que chegaram ao noticiário foram, em regra, uma configuração que alguém
escolheu, não uma invasão.** Ninguém adivinhou uma senha. Um bucket era legível por qualquer um porque
uma permissão, uma ACL ou uma URL dizia isso, e continuou assim porque nada que alguém olhasse dizia o
contrário. Notícias de buckets expostos com cadastros de clientes, backups e logs, em todo provedor,
correram por anos antes de a prevenção de acesso público e o acesso uniforme virarem o padrão, e elas
têm algumas formas em comum.

## As formas de um vazamento

**Uma permissão a `allUsers` no bucket.** Em geral feita para publicar uma pasta de imagens de produtos
para um site, no bucket em vez de num bucket só delas, o que tornou público todo objeto. É um comando,
`add-iam-policy-binding` com `--member=allUsers`, e as seções anteriores mostraram o emulador
respondendo `404` a ele, então aqui ele é descrito, não executado.

**Uma ACL em objetos.** Antes do acesso uniforme no nível do bucket, um bucket com IAM perfeitamente
privado podia guardar objetos públicos, cada um com a sua permissão a `allUsers`, definida pelo
programa que os escreveu com `--predefined-acl=publicRead`. Ninguém olhando o IAM do bucket os veria. A
seção desta aula sobre quem pode ler mostrou o emulador aceitando exatamente uma ACL assim.

**`allAuthenticatedUsers`, lido como "os nossos usuários".** Uma permissão pensada para colegas, feita
para qualquer um com uma conta do Google.

**Uma URL assinada que viveu demais, ou uma chave que vazou.** Uma URL válida por sete dias, colada num
chamado de suporte ou numa issue pública, é um link público de sete dias para o objeto. Uma chave de
conta de serviço commitada num repositório é pior: ela assina quantas URLs alguém quiser, até a chave
ser apagada.

## Prevenindo

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Cinco caixas aninhadas, de fora para dentro: restrições de política da organização, prevenção de acesso público, acesso uniforme no nível do bucket, a política de permissão do IAM com as condições, e o objeto. No Cloud Storage cada camada recusa sozinha uma requisição pública. No emulador a organização não existe, as duas configurações do bucket são aceitas e não guardadas, o IAM responde 404, e o objeto é servido a qualquer requisição.\" data-fig=\"l04-layers\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">a internet</text><text x=\"700.0\" y=\"18.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">o Cloud Storage recusa em cada camada</text><rect x=\"20\" y=\"34\" width=\"680\" height=\"276\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">restrições de política da organização</text><text x=\"688.0\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulador: não há organização</text><rect x=\"42\" y=\"84\" width=\"636\" height=\"226\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">prevenção de acesso público</text><text x=\"666.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulador: aceita, não guardada</text><rect x=\"64\" y=\"134\" width=\"592\" height=\"176\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">acesso uniforme no nível do bucket</text><text x=\"644.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulador: aceito, não guardado</text><rect x=\"86\" y=\"184\" width=\"548\" height=\"126\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"98.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">política de permissão do IAM, e as condições</text><text x=\"622.0\" y=\"202.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulador: 404, sem IAM</text><rect x=\"108\" y=\"234\" width=\"504\" height=\"76\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o objeto</text><text x=\"600.0\" y=\"252.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">emulador: servido a qualquer requisição</text></svg>", "caption": "O que fica entre a internet e um objeto, de fora para dentro, e o que o fake-gcs-server faz com cada camada. No Cloud Storage qualquer uma delas recusa sozinha; no emulador nenhuma recusa."}
```

A ordem importa, da rede mais ampla para a mais estreita:

1. **As políticas da organização da seção anterior**: prevenção de acesso público e acesso uniforme
   impostos em tudo, e chaves que não podem ser baixadas.
2. **Prevenção de acesso público e acesso uniforme em todo bucket mesmo assim**, para que um bucket
   continue protegido num projeto tirado de baixo da política.
3. **Permissões do IAM a grupos e contas de serviço, restritas por uma condição** onde um principal
   precisa de um prefixo.
4. **URLs assinadas curtas e estreitas**: minutos, assinadas por personificação, por uma conta que
   consegue ler um prefixo.

## Detectando

A prevenção falha, então alguém precisa ser avisado quando falhar. A documentação do Google descreve
as ferramentas, e nenhuma delas pode ser executada contra um emulador:

| ferramenta | o que responde |
|---|---|
| Cloud Audit Logs, Admin Activity | quem mudou o IAM, as ACLs ou as configurações de um bucket, e quando; sempre ligado, guardado por 400 dias, não cobrado |
| Cloud Audit Logs, Data Access | quem leu ou escreveu qual objeto; desligado por padrão para o Cloud Storage, e cobrado como volume de log quando ligado |
| Security Command Center | achados como uma ACL pública de bucket, levantados pelas varreduras do Security Health Analytics |
| Cloud Asset Inventory | toda política de IAM da organização que cita `allUsers` ou `allAuthenticatedUsers`, numa busca |
| Sensitive Data Protection | que objetos guardam dados pessoais, como nomes, números de CPF e de cartão, inspecionando-os |

**Elas respondem perguntas diferentes, e a diferença é o ponto.** O Asset Inventory diz que uma porta
está aberta. O Sensitive Data Protection diz o que há atrás dela. Os logs de auditoria dizem quem mudou
a porta e quem passou por ela, que é a pergunta que decide se uma exposição virou um vazamento. **Os
logs Data Access só a respondem se estavam ligados antes de acontecer.** A documentação dos logs de uso
acrescenta outra lacuna: requisições a objetos públicos nem são registradas nos logs de auditoria,
e os logs de uso, escritos num bucket com `--log-bucket`, são o jeito de acompanhá-las. Um bucket que
guarda qualquer coisa pessoal tem um ou outro ligado desde o primeiro dia.

A busca que uma analista faz primeiro, da aula 25 de `gcp-foundations`, é assim; ela exige uma
organização e não foi executada aqui:

```sh
gcloud asset search-all-iam-policies --scope=organizations/123456789012 --query='policy:allUsers'
gcloud asset search-all-iam-policies --scope=organizations/123456789012 --query='policy:allAuthenticatedUsers'
```

## A única verificação que sempre vale a pena

**Peça um objeto sem credenciais, de fora, e espere uma recusa.** É o teste de se algo é público e o
único em que vale confiar, porque confere o resultado em vez das configurações que deveriam produzi-lo:

```sh
curl -s -o /dev/null -w '%{http_code}\n' https://storage.googleapis.com/quitanda-curated-prod/reports/daily.csv
```

Contra o Cloud Storage um objeto privado responde com um código de erro e nenhum byte. **Neste
laboratório a verificação não tem como falhar**: a seção sobre quem pode ler mostrou o fake-gcs-server
entregando um relatório privado a uma requisição assinada por ninguém, então todo objeto aqui é como um
vazado. É a última coisa que o emulador desta aula ensina, e a mais útil: um teste que não distingue um
objeto privado de um público não é um teste de privacidade, e o único lugar onde essa pergunta tem
resposta é o serviço real.
