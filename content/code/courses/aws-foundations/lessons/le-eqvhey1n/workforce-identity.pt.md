---
title: Identidade da força de trabalho, e onde deve morar o login de uma pessoa
version: 1
---

**As pessoas fazem login uma vez, no IAM Identity Center, e chegam a cada conta em que podem entrar
como uma role, por algumas horas.** Nenhuma conta guarda um usuário para elas e nenhum laptop guarda
uma chave. A lição 6 apresentou o usuário do IAM, e a lição 12 explica por que a chave de acesso
dele é o último recurso. Esta lição é o arranjo que substitui os dois para todo mundo que trabalha
na loja.

A imagem errada é a que cresce sozinha. A loja começa numa conta, dá à `bia` um usuário do IAM ali,
e depois ganha uma segunda conta. **Agora a `bia` tem dois usuários, duas senhas, dois dispositivos
de MFA e duas chaves**. Quando ela sair, alguém tem de lembrar dos dois. Seis contas, como a lição 3
montou, e cinco pessoas dão trinta usuários, cada um para criar, auditar e apagar no dia certo.

## Três peças: uma identidade, um permission set, uma atribuição

O Identity Center separa as três perguntas que um usuário do IAM responde de uma vez só:

- quem a pessoa é fica numa **fonte de identidade**, fora de toda conta;
- o que um tipo de acesso significa é um **permission set**: um nome, uma duração de sessão e as
  políticas, escrito uma vez para a organização inteira;
- quem recebe qual acesso onde é uma **atribuição de conta** (account assignment): um usuário ou um
  grupo, um permission set e uma conta.

Quando você faz uma atribuição, o Identity Center provisiona o permission set na conta. Ele cria ali
uma role chamada `AWSReservedSSO_<permission set>_<sufixo>`, sob o caminho
`/aws-reserved/sso.amazonaws.com/`. A role leva as políticas do permission set e uma política de
confiança que só o Identity Center consegue satisfazer. Quando o `caio` abre `shop-prod` com
`ReadOnly`, ele está assumindo essa role, e o CloudTrail registra
`assumed-role/AWSReservedSSO_ReadOnly_…/caio`. Mude o permission set e o Identity Center atualiza a
role em toda conta que a tem. Apague a atribuição e a role deixa de aceitá-lo.

Essas roles são gerenciadas pelo Identity Center, e **ninguém deve editá-las à mão**. O Identity
Center sobrescreve uma edição feita dentro de uma conta na próxima vez que provisionar o permission
set. Até lá aquela conta discorda das outras em silêncio.

## A fonte de identidade, dentro ou fora da AWS

O Identity Center tem exatamente uma fonte de identidade por vez, escolhida quando é configurado e
trocável depois:

| fonte de identidade | onde ficam usuários e senhas | quando serve |
|---|---|---|
| o **diretório do Identity Center** | dentro do Identity Center | uma equipe pequena sem diretório próprio |
| **Active Directory** | um AWS Managed Microsoft AD, ou o seu, por um conector | uma empresa que já roda AD |
| um **provedor de identidade externo** | Google Workspace, Microsoft Entra ID, Okta e outros | uma empresa cujas pessoas já entram ali para todo o resto |

As pessoas da loja já têm contas do Google Workspace para o e-mail, então a escolha da loja é a
terceira linha. **Dois protocolos ligam um provedor externo, e fazem trabalhos diferentes.**

**O SAML 2.0 é o login.** Quando o `caio` abre o portal de acesso, o Identity Center manda o
navegador dele ao Google. O Google confere a senha e o segundo fator, e devolve uma asserção
assinada que diz quem ele é. O Identity Center confia nessa asserção porque os dois lados trocaram
certificados quando o provedor foi ligado. Nenhuma senha chega à AWS.

**O SCIM é o provisionamento.** O SAML diz quem está entrando no momento em que entra. Ele não
consegue dizer ao Identity Center que uma pessoa existe antes de ela chegar, a quais grupos ela
pertence, ou que ela saiu. O SCIM é uma API que o provedor de identidade chama para criar, atualizar
e desativar usuários e grupos no Identity Center conforme eles mudam do lado dele. **Sem SCIM,
alguém faz toda mudança duas vezes.** Uma pessoa nova precisa ser criada à mão no Identity Center
antes do primeiro login. Uma pessoa removida do Google não consegue mais entrar, mas deixa para trás
usuário, grupos e atribuições para alguém lembrar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-federation\" aria-label=\"Como uma pessoa chega a uma conta pelo Identity Center. O Caio faz login, com o segundo fator, no provedor de identidade, o Google Workspace. O provedor fala com o IAM Identity Center de dois jeitos: o SAML diz quem está entrando naquele momento, e o SCIM diz de antemão quais usuários e grupos existem. O Identity Center provisiona uma role em cada conta que uma atribuição nomeia: AWSReservedSSO_ReadOnly em shop-prod, AWSReservedSSO_Developer em shop-staging, e assim por diante. Nenhuma conta guarda um usuário para ele.\"><defs><marker id=\"l11-federation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-federation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-federation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"30.0\" width=\"150.0\" height=\"44.0\" rx=\"20\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">caio, num navegador</text><path d=\"M105.0 76.0 L105.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-phosphor)\"></path><text x=\"115.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">faz login, com MFA</text><rect x=\"30.0\" y=\"150.0\" width=\"150.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">provedor de identidade</text><text x=\"105.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Google Workspace</text><rect x=\"280.0\" y=\"140.0\" width=\"170.0\" height=\"94.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"365.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">IAM Identity Center</text><text x=\"365.0\" y=\"195.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permission sets</text><text x=\"365.0\" y=\"208.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e atribuições</text><path d=\"M182.0 166.0 L278.0 166.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-phosphor)\"></path><text x=\"230.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">SAML: quem, agora</text><path d=\"M182.0 210.0 L278.0 210.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-amber)\"></path><text x=\"230.0\" y=\"221.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">SCIM: quem</text><text x=\"230.0\" y=\"234.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">existe</text><rect x=\"530.0\" y=\"28.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-prod</text><text x=\"615.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">AWSReservedSSO_ReadOnly_…</text><path d=\"M452.0 170.3 L527.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"128.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">shop-staging</text><text x=\"615.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">AWSReservedSSO_Developer_…</text><path d=\"M452.0 187.0 L527.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-paper-dim)\"></path><rect x=\"530.0\" y=\"228.0\" width=\"170.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sandbox</text><text x=\"615.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">AWSReservedSSO_…</text><path d=\"M452.0 203.7 L527.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-federation-af-ah-paper-dim)\"></path><text x=\"365.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">provisiona uma role por</text><text x=\"365.0\" y=\"277.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">conta atribuída</text><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nenhuma conta guarda um usuário para uma pessoa</text></svg>", "caption": "A pessoa mora no provedor de identidade; as contas guardam só roles que o Identity Center gerencia.", "same": ["Google Workspace", "IAM Identity Center", "permission sets"]}
```

Nada disso foi executado. **Ligar um provedor de identidade real exige um Identity Center real, um
diretório real e um navegador**, e o moto não tem nenhum dos três. A descrição é o arranjo
documentado pela AWS. O que o moto tem é o lado do Identity Center: os permission sets, os usuários,
os grupos e as atribuições, que a próxima seção monta.

## Por que uma sessão curta vence um usuário com chave

Para uma pessoa, a sessão do Identity Center vence em cada quesito que importa quando algo dá
errado:

- **ela vence sozinha.** O permission set da próxima seção pede quatro horas; uma chave funciona
  até alguém apagá-la, e a lição 12 lê a idade das chaves no relatório de credenciais;
- **ela herda o segundo fator.** Toda sessão começa no provedor de identidade, onde o MFA é exigido
  uma vez para tudo, em vez de por usuário em cada conta;
- **sair é uma ação só.** Desativar a pessoa no Google recusa todo login depois disso, o SCIM leva a
  remoção adiante, e as sessões já abertas acabam dentro da sua duração;
- **o registro nomeia a pessoa.** A sessão da role leva o nome do usuário, então uma auditoria lê
  `caio` e não um usuário compartilhado.

O que sobra para usuários do IAM é a lista curta com que a lição 12 termina: um programa que roda
fora da AWS e não pode usar nenhum dos mecanismos da lição 10, e o acesso de emergência da conta.
**Pessoas não estão nessa lista.**

O portal de acesso é a página onde uma pessoa que fez login vê as contas e os permission sets
atribuídos a ela. Dali ela abre o console numa delas, ou copia credenciais de vida curta para a
linha de comando. O endereço é `https://<algo>.awsapps.com/start`, mostrado nas configurações do
Identity Center. A última seção desta lição aponta a linha de comando para ele.
