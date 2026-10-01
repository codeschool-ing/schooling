---
title: Quem quer fazer o quê, com qual coisa
version: 1
---

Tudo o que acontece numa conta de nuvem é uma chamada de API. Clicar em *Excluir* num console, rodar
um comando no terminal, um programa salvando um arquivo pela biblioteca do provedor: cada uma dessas
coisas vira um pedido HTTPS para a API do provedor, e cada pedido é julgado sozinho. **Um pedido
carrega quatro fatos: quem está pedindo, o que quer fazer, com qual coisa quer fazer isso e em que
circunstâncias.** O vocabulário para esses quatro é o mesmo em todo provedor:

| | a palavra | um exemplo |
|---|---|---|
| quem | o **principal** | o usuário `ana`, ou uma role que um servidor está usando |
| o quê | a ação | `s3:GetObject`, ler um objeto de um bucket |
| com qual coisa | o recurso | o objeto `2026/q3.csv` no bucket `example-reports` |
| em que circunstâncias | a condição | login feito com MFA, do endereço do escritório, sobre TLS |

## Acesso é propriedade de um pedido, não de uma pessoa

A imagem com que a maioria chega é a de uma pessoa que "tem acesso à produção", como se acesso fosse
um crachá que alguém usa. O provedor nunca faz essa pergunta. Ele pergunta se *este* pedido, *deste*
principal, para *esta* ação sobre *este* recurso, *agora*, é permitido. "A Ana pode ler os objetos
abaixo de `2026/` no bucket de relatórios, quando fez login com MFA" é o formato de toda resposta, e
cada uma das quatro partes pode ser o motivo de um pedido falhar.

Pegue um comando, que copia um objeto de dentro de um bucket como os da aula 5:

```sh
aws s3 cp s3://example-reports/2026/q3.csv .
```

Ele vira um pedido. O principal é a identidade cujas credenciais o assinaram. A ação é
`s3:GetObject`. O recurso é nomeado por um **ARN**, um Amazon Resource Name, que aqui é
`arn:aws:s3:::example-reports/2026/q3.csv`; os campos vazios entre os dois-pontos são a região e o
número da conta, que o nome de um bucket dispensa porque nomes de bucket são globais. As
circunstâncias vêm junto sem ninguém escrevê-las: o endereço de onde o pedido veio, a hora, se a
sessão foi aberta com um segundo fator, se ele trafegou por TLS. A AWS chama isso de **chaves de
contexto** e as nomeia `aws:SourceIp`, `aws:CurrentTime`, `aws:MultiFactorAuthPresent` e
`aws:SecureTransport`, e uma política pode testar qualquer uma delas.

## Dois portões, nesta ordem

O pedido passa por duas verificações, e elas respondem a perguntas diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 800 300\" role=\"img\" aria-label=\"Um pedido, à esquerda, carrega quatro coisas: quem pede, o usuário ana; o quê, a ação s3:GetObject; sobre qual coisa, o objeto example-reports/2026/q3.csv; e as circunstâncias, login feito com MFA a partir de um endereço do escritório. Ele passa por dois portões, um depois do outro. O primeiro, autenticação, pergunta quem está pedindo e confere a assinatura contra uma credencial que o provedor conhece; um pedido que não se liga a nenhuma identidade é recusado ali. O segundo, autorização, pergunta se essa identidade pode fazer isso, lendo todas as políticas que se aplicam; um pedido que nenhuma política permite é recusado ali com AccessDenied. Só o pedido que passa pelos dois chega ao serviço, que devolve o objeto.\"><defs><marker id=\"gat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"230\" height=\"206\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">o pedido</text><text x=\"34\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem</text><text x=\"34\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">ana</text><text x=\"34\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o quê</text><text x=\"34\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">s3:GetObject</text><text x=\"34\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sobre o quê</text><text x=\"34\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">example-reports/2026/q3.csv</text><text x=\"34\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">circunstâncias</text><text x=\"34\" y=\"189\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">login com MFA</text><text x=\"34\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">do endereço do escritório</text><rect x=\"290\" y=\"60\" width=\"170\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"375\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">autenticação</text><text x=\"375\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">quem está pedindo?</text><text x=\"375\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">confere a assinatura</text><text x=\"375\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">com uma credencial conhecida</text><rect x=\"500\" y=\"60\" width=\"170\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">autorização</text><text x=\"585\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pode fazer isso?</text><text x=\"585\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê todas as políticas</text><text x=\"585\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">que se aplicam</text><rect x=\"706\" y=\"70\" width=\"80\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"746\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">o serviço</text><text x=\"746\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">devolve</text><text x=\"746\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o objeto</text><path d=\"M250 115 L290 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gat-ah)\"></path><path d=\"M460 115 L500 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gat-ah)\"></path><path d=\"M670 115 L706 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gat-ah)\"></path><path d=\"M375 170 L375 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#gat-ah)\"></path><rect x=\"282\" y=\"222\" width=\"186\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"375\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado: sem identidade</text><text x=\"375\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as políticas nem são lidas</text><path d=\"M585 170 L585 222\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#gat-ah)\"></path><rect x=\"492\" y=\"222\" width=\"186\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"585\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recusado: AccessDenied</text><text x=\"585\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhuma política permitiu</text></svg>", "caption": "Toda chamada a uma API de nuvem passa por dois portões. O primeiro resolve quem está pedindo; o segundo decide se essa identidade pode fazer isso com essa coisa, agora. O resto desta aula é sobre o segundo portão."}
```

**A autenticação pergunta quem está pedindo.** Todo pedido é assinado com um segredo que quem chama
guarda (a AWS chama seu esquema de Signature Version 4), e o provedor confere a assinatura contra uma
credencial que ele conhece. Um pedido sem assinatura, com a assinatura errada ou com uma credencial
expirada nunca chega ao segundo portão; nenhuma política é lida para ele.

**A autorização pergunta se essa identidade pode fazer isso.** O provedor reúne todas as políticas que
se aplicam ao pedido e decide. Quase toda esta aula é sobre essa decisão: o que uma política diz,
como várias se combinam e como escrever políticas que permitam o trabalho e nada ao lado dele.

Você viu a mesma divisão no HTTP, no curso `networks`, com nomes que confundem todo mundo uma vez. O
status `401 Unauthorized` quer dizer que o primeiro portão falhou: o servidor não sabe quem você é, e
"não autorizado" é um nome histórico equivocado para "não autenticado". O status `403 Forbidden`
quer dizer que falhou o segundo: ele sabe exatamente quem você é, e a resposta é não. Nem toda API
de nuvem mantém os dois números separados, então leia o código do erro, não o status. O S3 responde a
uma assinatura que não consegue verificar com um 403 de código `SignatureDoesNotMatch`, o primeiro
portão; e responde a um pedido bem assinado que nenhuma política permite com um 403 de código
`AccessDenied`, o segundo.

Esta também é uma camada diferente da aula 6. **Um security group decide quais pacotes chegam a uma
máquina virtual; identidade e acesso decidem quais chamadas de API dão certo.** Uma VM atrás de um
security group perfeito ainda pode ser excluída por qualquer pessoa com uma credencial que permita
`ec2:TerminateInstances`, e nenhuma regra de firewall vai ver isso acontecer, porque esse pedido vai
para a API do provedor e nunca para a máquina.
