---
title: Roles, a identidade em que ninguém faz login
version: 1
---

Uma **role** é uma identidade com permissões e sem senha nem chaves de longa duração. Ninguém faz
login como uma role. Ela é **assumida**: algo que já tem uma identidade pede a role e, se tiver
permissão, recebe um conjunto de credenciais temporárias que agem como a role até expirar.

A imagem errada vem da palavra. No português do dia a dia, e no Google Cloud e no Azure, como mostra a
seção sobre outros provedores, um papel é um pacote de permissões, algo como "editor". Na AWS a role
não é um pacote: é um principal, o mesmo tipo de coisa que um usuário, e é por isso que ela pode
aparecer no log de auditoria fazendo chamadas. A diferença para um usuário é só a forma como as
credenciais dela passam a existir.

## O que assumir uma role entrega

Na AWS o serviço que entrega credenciais temporárias é o STS, o Security Token Service, e a chamada é
`sts:AssumeRole`. O que volta são quatro coisas:

- um access key id, que nas credenciais temporárias começa com `ASIA`, enquanto o de longa duração de
  um usuário começa com `AKIA`;
- uma chave de acesso secreta;
- um token de sessão, que precisa acompanhar todo pedido assinado com as outras duas;
- uma expiração.

Por padrão a sessão dura uma hora. Quem chama pode pedir apenas quinze minutos, ou mais, até um
máximo configurado na role entre uma e doze horas. **Quando o tempo acaba as credenciais param de
funcionar, esteja com quem estiverem.** Uma credencial copiada da memória de um servidor vale uma hora
para quem a copiou, não um ano, e ninguém precisou lembrar de fazer rotação de nada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 350\" role=\"img\" aria-label=\"Três colunas: quem chama, que é uma máquina virtual ou uma pessoa; o serviço de tokens, STS; e o serviço usado, S3. Um: quem chama pede ao STS sts:AssumeRole na role report-reader, assinando o pedido com a própria identidade. Dois: o STS lê a política de confiança da role e confere se esse chamador é um em quem a role confia. Três: o STS responde com credenciais temporárias, um access key id, uma chave secreta e um token de sessão, que expiram em uma hora. Quatro: quem chama assina a chamada ao S3 com essas credenciais, e o S3 autoriza contra a política de permissões da role, não contra a do chamador. Depois da expiração as credenciais param de funcionar e é preciso assumir a role de novo.\"><defs><marker id=\"rol-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">quem chama</text><text x=\"110\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma VM, ou uma pessoa</text><rect x=\"310\" y=\"16\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">STS</text><text x=\"400\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o serviço de tokens</text><rect x=\"570\" y=\"16\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">S3</text><text x=\"660\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o serviço usado</text><path d=\"M110 62 L110 336\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M400 62 L400 146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M400 192 L400 336\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><path d=\"M660 62 L660 300\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"128\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  pede para assumir a role</text><text x=\"146\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">assinado como si mesmo</text><text x=\"146\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sts:AssumeRole  role/report-reader</text><path d=\"M110 134 L400 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rol-ah)\"></path><rect x=\"310\" y=\"146\" width=\"180\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2  lê a política de confiança:</text><text x=\"400\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">este chamador pode assumi-la?</text><path d=\"M400 240 L110 240\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rol-ah)\"></path><text x=\"128\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  credenciais temporárias</text><text x=\"146\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">key id, segredo, token de sessão</text><text x=\"146\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">expiram em uma hora</text><path d=\"M110 290 L660 290\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rol-ah)\"></path><text x=\"430\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  a chamada, assinada com elas</text><rect x=\"560\" y=\"300\" width=\"190\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"655\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5  conferida contra a política</text><text x=\"655\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de permissões da role</text></svg>", "caption": "Ninguém faz login numa role. Um chamador que a política de confiança nomeia pede por ela, recebe credenciais que expiram e as usa; o serviço então julga a chamada pelo que a ROLE pode fazer. Os passos 1 a 3 se repetem antes de a hora acabar.", "same": ["STS", "S3"]}
```

## Duas políticas em toda role

Uma role carrega dois documentos, e eles respondem a perguntas diferentes.

**A política de confiança diz quem pode assumir a role.** Ela nomeia principais: outra conta AWS, um
serviço do provedor ou um provedor de identidade de fora. Esta deixa as máquinas virtuais da lição 4
assumirem a role, e ninguém mais:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**A política de permissões diz o que a role pode fazer depois de assumida**, e é escrita como qualquer
outra política; a próxima seção desmonta uma. As duas precisam dizer sim. Uma role cuja política de
confiança nomeia você e cuja política de permissões não permite nada deixa você entrar para não fazer
nada; uma role cuja política de permissões permite tudo é inofensiva para quem a política de confiança
não nomeia.

Essa divisão também é onde mora a maior parte do perigo. Uma política de confiança que diz
`"Principal": {"AWS": "*"}` confia em toda conta AWS do mundo, e aí a única coisa entre um estranho e
as permissões da role são as condições que a política acrescentar. Ler uma política de confiança é ler
a lista de quem pode se tornar esta identidade.

## O que usa uma role

Tudo o que não é uma pessoa sentada no console, e cada vez mais as pessoas também:

- uma máquina virtual, pela role anexada a ela, que a AWS chama de instance profile;
- uma função, pela sua role de execução, que a lição 8 dá a toda função que escreve;
- uma pessoa de outra conta, que assume uma role nesta em vez de ter um usuário aqui;
- uma pessoa que fez login pelo provedor de identidade da organização;
- um pipeline de build fora da nuvem, que prova quem é com um token emitido pela própria plataforma.

Os três últimos são a seção de federação. Em cada caso a pergunta que a política de confiança
responde é a mesma: qual identidade já conhecida pode se tornar esta, e em que condições.
