---
title: Slots, aquecimento e a troca
version: 1
---

**Um slot de deploy é uma segunda cópia em execução de um app do App Service**, com o seu próprio nome de
host, `app-shop-api-staging.azurewebsites.net`, no mesmo plano e nas mesmas máquinas. A loja implanta toda
versão nova em `staging`, nunca em produção, e depois troca. A lição 18 de `azure-compute` apresenta os slots;
esta seção é sobre usá-los como o mecanismo de deploy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois painéis, antes e depois de uma troca. Antes: o slot de produção de app-shop-api roda a versão 41 e recebe todo o tráfego; o slot staging roda a versão 42, aquecida, sem receber nada. Depois da troca: produção roda a 42 e recebe todo o tráfego; staging guarda a 41, pronta para trocar de volta. A configuração marcada como fixa no slot, a conexão com o banco, fica com o seu slot nos dois painéis.\"><defs><marker id=\"ah-swap\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">antes da troca</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">depois da troca</text><rect x=\"40\" y=\"50\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">slot de produção</text><text x=\"180\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v41</text><text x=\"180\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todo o tráfego</text><rect x=\"40\" y=\"150\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">slot staging</text><text x=\"180\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v42</text><text x=\"180\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aquecida, sem tráfego</text><path d=\"M330 140 L390 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-swap)\"></path><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">swap</text><rect x=\"400\" y=\"50\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">slot de produção</text><text x=\"540\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v42</text><text x=\"540\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todo o tráfego</text><rect x=\"400\" y=\"150\" width=\"280\" height=\"80\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">slot staging</text><text x=\"540\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">v41</text><text x=\"540\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a uma troca de voltar</text><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fixa: DB_CONNECTION fica com cada slot</text></svg>", "caption": "Uma troca permuta o que roda, não para onde vai o tráfego. Uma configuração fixa fica com o seu slot."}
```

**Uma troca permuta o conteúdo de dois slots; ela não move tráfego entre dois hosts.** Antes da virada, o App
Service aplica as configurações de produção aos processos do slot staging e espera que eles subam, mandando
requisições à raiz da aplicação, ou aos caminhos listados em `applicationInitialization`, até responderem. Só
então muda o roteamento. Feito assim, a primeira requisição de cliente na versão nova cai num processo que já
carregou o código e abriu as conexões, que é todo o sentido do slot: **a partida a frio acontece antes do
cliente, e não com o cliente.**

## Configurações que ficam

A maior parte da configuração viaja com o código numa troca. Algumas não podem: o banco do slot staging não é
o de produção, e uma troca que levasse `DB_CONNECTION` junto apontaria a produção para o banco de staging. Uma
configuração marcada como **específica do slot**, ou fixa, fica com o seu slot. Em Bicep o slot e a lista de
fixas ficam assim; o arquivo **não foi compilado** aqui, porque o Bicep chega na lição 4, e nunca foi
implantado:

```bicep
// slot.bicep
resource app 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'app-shop-api'
}

resource staging 'Microsoft.Web/sites/slots@2024-04-01' = {
  parent: app
  name: 'staging'
  location: 'brazilsouth'
  properties: {
    siteConfig: {
      healthCheckPath: '/healthz'
    }
  }
}

resource sticky 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: app
  name: 'slotConfigNames'
  properties: {
    appSettingNames: [ 'DB_CONNECTION' ]
  }
}
```

## Trocando

A troca em si é um comando, **não executado** aqui porque precisa do Resource Manager:

```sh
az webapp deployment slot swap -g rg-shop -n app-shop-api --slot staging --target-slot production
```

Vale conhecer duas variantes. **Troca com prévia** para depois de aplicar as configurações de produção aos
processos de staging, para você testar a versão nova com a configuração que ela terá, e então concluir ou
cancelar. **Troca automática** troca sozinha depois de cada deploy no slot, o que tira o momento em que uma
pessoa ou um gate olha; a loja não a usa em produção por isso.

Slots não são livres de custo nem de limites. Rodam no mesmo plano, então um slot staging ocupado tira
capacidade da produção; e o número de slots depende do nível do plano. Um plano sem slots não consegue usar
este padrão, o que vale conferir antes de uma equipe se organizar em torno dele.
