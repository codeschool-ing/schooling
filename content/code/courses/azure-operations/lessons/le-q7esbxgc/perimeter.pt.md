---
title: O perímetro, camada por camada
version: 1
---

**Um perímetro não é um muro; são camadas, cada uma parando o que a de fora deixou passar.** O da loja tem quatro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O perímetro da loja em camadas, da internet para dentro. Primeiro, o Front Door na borda da Microsoft, absorvendo inundações volumétricas, com o WAF dele cuidando de ataques de camada 7. Segundo, o App Service, que só aceita tráfego vindo do Front Door. Terceiro, a rede virtual, onde grupos de segurança de rede só permitem os fluxos esperados. Quarto, private endpoints para o banco SQL e o Key Vault, que não têm endereço público nenhum.\"><defs><marker id=\"ah-layers\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"700\" height=\"225\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">internet</text><rect x=\"40\" y=\"50\" width=\"640\" height=\"185\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"60\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Front Door + WAF: inundações e camada 7</text><rect x=\"70\" y=\"80\" width=\"580\" height=\"145\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">App Service: só aceita o Front Door</text><rect x=\"100\" y=\"110\" width=\"520\" height=\"105\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rede virtual: NSGs permitem os fluxos esperados</text><rect x=\"130\" y=\"140\" width=\"460\" height=\"65\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">private endpoints: SQL, Key Vault</text><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem endereço público</text></svg>", "caption": "Cada camada para o que a anterior deixou passar, e a mais de dentro não tem endereço público para atacar.", "same": ["internet", "private endpoints: SQL, Key Vault"]}
```

1. **O Front Door com o WAF**, na borda. Inundações são absorvidas na rede da Microsoft; ataques de camada 7 encontram as regras
   gerenciadas e o limite de taxa da lição 18.
2. **O App Service só aceita tráfego do Front Door.** Uma restrição de acesso permite a service tag `AzureFrontDoor.Backend` e
   confere o cabeçalho `X-Azure-FDID` contra o id do Front Door da própria loja, então um atacante que ache o endereço
   `azurewebsites.net` do app não consegue contornar a borda. Sem isso, toda proteção na borda é opcional para quem procurar.
3. **Dentro da rede virtual, grupos de segurança de rede só permitem os fluxos esperados**: a sub-rede de integração de saída do
   app até o private endpoint do banco na porta 1433, e nada mais. A lição 17 de `azure-foundations` trata de NSGs.
4. **O banco e o cofre não têm endereço público nenhum**, alcançados por private endpoints, que a lição 20 monta. Não há nada no
   centro para uma inundação atingir.

A segunda camada é a que as equipes esquecem, e ela importa mais que qualquer plano pago: **uma proteção que pode ser contornada
não protege nada**. O mesmo raciocínio move a lição 20: fechar o caminho público vale mais do que vigiá-lo.
