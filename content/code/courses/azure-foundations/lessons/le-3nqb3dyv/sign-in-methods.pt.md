---
title: Sincronização de hash de senha, autenticação de passagem e federação
version: 1
---

**Copiar a conta responde quem uma pessoa é no Entra ID. Não responde como ela prova isso.** Quando
`ana@shop.example` digita uma senha na página de login da Microsoft, alguém precisa conferi-la, e há três
escolhas de quem. A documentação da Microsoft chama as duas primeiras de *autenticação na nuvem* e a
terceira de *federação*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-methods\" aria-label=\"Quem confere a senha em cada um dos três métodos de login. Com a sincronização de hash de senha, o Entra ID a confere contra um hash que recebeu. Com a autenticação de passagem, o Entra ID a passa a um agente no escritório, que pergunta ao Active Directory. Com a federação, o Entra ID manda a pessoa ao servidor de federação da própria empresa, que confere e a manda de volta com uma declaração assinada.\"><defs><marker id=\"l12-methods-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">método</text><text x=\"450.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">quem confere a senha</text><text x=\"660.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">precisa do escritório</text><rect x=\"30.0\" y=\"50.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sincronização de hash</text><path d=\"M231.0 70.0 L269.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-methods-af-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"50.0\" width=\"360.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o Entra ID, contra um hash sincronizado</text><text x=\"660.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">não</text><rect x=\"30.0\" y=\"108.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">autenticação de passagem</text><path d=\"M231.0 128.0 L269.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-methods-af-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"108.0\" width=\"360.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um agente no escritório, perguntando ao Active Directory</text><text x=\"660.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sim</text><rect x=\"30.0\" y=\"166.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">federação</text><path d=\"M231.0 186.0 L269.0 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-methods-af-ah-paper-dim)\"></path><rect x=\"270.0\" y=\"166.0\" width=\"360.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o servidor de federação da empresa</text><text x=\"660.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sim</text></svg>", "caption": "Quanto mais longe da nuvem fica a conferência, mais o escritório precisa estar no ar para alguém entrar."}
```

## Sincronização de hash de senha

**O próprio Entra ID confere a senha, contra um hash que recebeu.** A sincronização copia, a cada dois
minutos, um hash derivado do hash que o Active Directory já guarda; a documentação da Microsoft é
explícita em que nenhuma senha é guardada em texto puro nem numa forma que possa ser revertida. O login
então não precisa de nada no chão: o escritório pode perder a energia e a internet, e quem trabalha de
casa continua entrando no Azure.

A documentação da Microsoft o descreve como o método de menor esforço para implantar e manter. Ele
também traz um benefício que os outros dois não têm: com os hashes na nuvem, **o Entra ID consegue avisar uma
empresa de que a senha de um dos usuários dela apareceu num vazamento**, e ele precisa desses hashes para
esse relatório seja qual for o método de login que a empresa escolheu. A fraqueza dele é o tempo: uma
conta desativada no chão continua ativa na nuvem até a próxima sincronização levar a mudança.

## Autenticação de passagem

**O Entra ID recebe a senha e a entrega a um agente no chão, que pergunta ao Active Directory.** Os
agentes, programas leves em servidores da rede, mantêm só conexões de saída com a Microsoft, então nada
precisa ser aberto para a internet. A Microsoft recomenda três deles, pela disponibilidade.

Ela serve a uma empresa que precisa impor, no momento do login, o que o Active Directory diz: uma conta
recém-desativada, uma senha recém-expirada, horários fora dos quais uma pessoa não pode entrar. O preço
é que o login agora depende desses agentes e dos controladores de domínio atrás deles. **Uma empresa
que a escolhe deveria sincronizar os hashes também**, como a documentação da Microsoft aconselha: um
plano B no dia em que os agentes não conseguirem responder, e a origem do relatório de credenciais
vazadas.

## Federação

**O Entra ID manda a pessoa para outro sistema, que confere a senha e a manda de volta com uma
declaração assinada.** Para a maioria das empresas, esse sistema era o Active Directory Federation
Services, o AD FS, um conjunto de servidores no chão e proxies na frente deles. A federação consegue
fazer coisas que os outros dois não conseguem, como login com cartão inteligente conferido no local, e
leva todo o login para uma infraestrutura que a empresa roda, atualiza e mantém no ar.

É por isso que a documentação da Microsoft oferece o *staged rollout*, um jeito de mover grupos de
usuários da federação para a autenticação na nuvem aos poucos, e por isso que a direção de quase todas
as empresas é o primeiro método. **A loja escolheu a sincronização de hash de senha**: ela não tem
nenhum requisito que os outros dois atendam, e quanto menos servidores entre uma pessoa e o Azure, menos
servidores podem estar fora do ar.

## Perguntando ao Entra ID como um domínio faz login

Antes de uma pessoa digitar uma senha, a página de login da Microsoft precisa saber para onde mandá-la:
para a sua própria caixa de senha, ou para o servidor de federação de uma empresa. Ela pergunta ao Entra
ID, num endereço que qualquer um pode chamar. **A Microsoft não documenta este endereço como uma API**,
então leia os campos dele como uma observação e não como um contrato; as respostas abaixo são do
próprio Entra ID:

```
ana@laptop:~/azure$ curl -sS 'https://login.microsoftonline.com/getuserrealm.srf?login=ana@shop.example&json=1' | jq '{NameSpaceType, DomainName}'
{
  "NameSpaceType": "Unknown",
  "DomainName": null
}
ana@laptop:~/azure$ curl -sS 'https://login.microsoftonline.com/getuserrealm.srf?login=ana@microsoft.com&json=1' | jq '{NameSpaceType, DomainName}'
{
  "NameSpaceType": "Managed",
  "DomainName": "microsoft.com"
}
```

`shop.example` é um nome reservado para exemplos, que nenhum tenant pode ter, e a resposta diz isso:
`Unknown`, nenhum domínio. `microsoft.com` é o da própria Microsoft, e a resposta é `Managed`: **as
pessoas da Microsoft fazem login com autenticação na nuvem**, na página do próprio Entra ID, e não por um
servidor de federação. Uma empresa que federa recebe `Federated`, com o endereço do servidor de
federação ao lado, e é exatamente assim que a página de login sabe mandar as pessoas dela para lá.

Esta é a única parte da lição que o laboratório consegue mostrar, e ela mostra o fim da cadeia e não a
cadeia: qual dos três métodos um domínio usa, como o Entra ID conta a todo mundo que pergunta.
