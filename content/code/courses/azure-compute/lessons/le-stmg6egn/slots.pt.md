---
title: "Slots: o mesmo app num segundo endereço"
version: 1
---

Um slot de implantação soa como um segundo ambiente: uma cópia de staging da loja em máquinas
próprias, separada da produção. **Um slot é um app vivo no mesmo plano, com nome de host próprio e
configurações próprias.** Ele roda nas instâncias do plano, como desenhou a figura da seção 02, e a
Microsoft não cobra nada a mais por ele, porque as instâncias já estão pagas. O que ele dá à loja é
um lugar para pôr `shop:1.1`, com as máquinas e a rede da produção, onde os desenvolvedores podem
chamá-lo antes de qualquer cliente. O app de produção também é um slot, o chamado `production`, e é
por isso que a próxima seção pode trocar os dois. Esta seção é o slot no arquivo da loja, compilado
com dois erros que o compilador pega e um que não pega; o slot em si é lido da documentação da
Microsoft, e nenhum foi criado.

## Quantos, e onde

Slots existem do tier Standard para cima, cinco por app no Standard e 20 no Premium e no Isolated,
pela página de limites lida em 2026-10-30. Free e Basic não têm nenhum. O número também prende um
plano no lugar: um app com mais de cinco slots não desce para o Standard até alguns serem apagados.

Cada slot tem nome de host próprio, o nome do app e o do slot unidos por um hífen,
`shop-sp-staging.azurewebsites.net` ao lado de `shop-sp.azurewebsites.net`. A documentação limita o
nome do app a 40 caracteres e o do slot a 19 para que os dois caibam juntos num rótulo de DNS. Um
slot é alcançável pela internet como o app. Fechá-lo para todos menos os desenvolvedores é uma
restrição de acesso no slot, uma regra de IP, que é o que a documentação indica para isso.

**Um slot novo não tem conteúdo**, mesmo quando clona a configuração de outro. O
`--configuration-source` da CLI copia configurações e nada mais:

```
ana@laptop:~/azure$ az webapp deployment slot create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --configuration-source '
 --configuration-source : Source slot to clone configurations from. Use web app's name to refer to the production slot. 
ana@laptop:~/azure$ az webapp config appsettings set --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --slot-settings ' | sed 's/ Global Policy Arguments//'
 --slot-settings : Space-separated appsettings in KEY=VALUE format. Use @{file} to load from a file. Given setting are added to the configuration and marked as Deployment slot setting by default. 
```

O segundo comando é o jeito da CLI de fazer uma configuração ser *fixa*, que é a ideia de que trata o
resto desta seção.

## Cada slot tem suas configurações

No arquivo, `staging` é um recurso próprio, `Microsoft.Web/sites/slots`, com `site` como pai e um
`siteConfig` próprio. Ele roda `shop:1.1` onde a produção roda `shop:1.0`, e repete toda
configuração de app, porque nada que um slot tem é herdado em tempo de execução. O `SHOP_ENV` dele
é `staging`, onde o da produção é `production`.

Essa última configuração é a interessante. Suponha que `SHOP_ENV` decida que gateway de pagamento a
loja chama, o real ou o sandbox do gateway. Quando a próxima seção fizer o swap dos slots, o
conteúdo que estava no staging vai para a produção. Se as configurações fossem junto, a produção
nova chegaria ainda dizendo `staging` e mandaria o cartão de todo cliente para o sandbox. **Uma
configuração fixa fica com o slot, não com o conteúdo**, e o arquivo declara uma num recurso de
nome fixo, `slotConfigNames`, no app e não no slot:

```
ana@laptop:~/azure$ jq '.resources[3].properties' shop-web.json
{
  "appSettingNames": [
    "SHOP_ENV"
  ]
}
```

Os nomes listados ali ficam onde estão durante um swap, e a descrição do recurso na API REST diz
que a lista vale para todos os slots de implantação de um app. Strings de conexão têm uma lista
própria ao lado, `connectionStringNames`. O compilador conhece o recurso o bastante para pegar dois
deslizes. Um nome errado para a configuração, e a lista escrita como uma string só:

```
ana@laptop:~/azure$ sed "s/'slotConfigNames'/'slotSettings'/" shop-web.bicep > name.bicep
ana@laptop:~/azure$ bicep build name.bicep
/home/ana/azure/name.bicep(76,9) : Warning BCP088: The property "name" expected a value of type "'appsettings' | 'authsettings' | 'authsettingsV2' | 'azurestorageaccounts' | 'backup' | 'connectionstrings' | 'logs' | 'metadata' | 'pushsettings' | 'slotConfigNames' | 'web'" but the provided value is of type "'slotSettings'". Did you mean "'appsettings'"? [https://aka.ms/bicep/core-diagnostics#BCP088]
ana@laptop:~/azure$ sed -n '/appSettingNames/,/]/p' shop-web.bicep
    appSettingNames: [
      'SHOP_ENV'
    ]
ana@laptop:~/azure$ sed "/appSettingNames: \[/,/]/c\    appSettingNames: 'SHOP_ENV'" shop-web.bicep > list.bicep
ana@laptop:~/azure$ bicep build list.bicep
/home/ana/azure/list.bicep(78,22) : Warning BCP036: The property "appSettingNames" expected a value of type "null | string[]" but the provided value is of type "'SHOP_ENV'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

O primeiro aviso vale ser lido inteiro: `Microsoft.Web/sites/config` é uma lista fechada de onze
nomes, e o compilador os imprime. O "did you mean" dele chuta `appsettings`, que é a grafia mais
próxima e o recurso errado; o certo está na lista, alguns nomes adiante.

## O que viaja e o que fica

Não só as configurações que você marca. A documentação da Microsoft divide a configuração de um app
entre o que acompanha o conteúdo num swap e o que fica com o slot, e a divisão é fixa:

| acompanha o conteúdo | fica com o slot |
| --- | --- |
| configurações de app e strings de conexão não marcadas como fixas | configurações e strings de conexão marcadas como fixas |
| configurações de linguagem e plataforma, WebSockets | nomes de domínio personalizados, certificados não públicos e configurações de TLS |
| armazenamento montado, mapeamentos de handler e de caminho, conteúdo dos WebJobs | configurações de escala, agendas dos WebJobs |
| conexões híbridas, service endpoints, a CDN | identidades gerenciadas, integração com rede virtual, restrições de IP |
| certificados públicos | endpoints de publicação, Always On, logs de diagnóstico, CORS, só HTTPS |

**A coluna da direita é a identidade do slot**: os endereços dele, os certificados, quem pode
alcançá-lo, em que rede ele está, e a identidade que ele usa para alcançar outras coisas. Uma
identidade gerenciada que pode ler o Key Vault da produção fica na produção, e o código que chega
ali a usa desde o momento da troca. Cinco itens da direita, restrições de IP, Always On, logs de
diagnóstico, CORS e as configurações de protocolo, já foram trocados um dia; a documentação mantém
uma configuração, `WEBSITE_OVERRIDE_PRESERVE_DEFAULT_STICKY_SLOT_SETTINGS`, que devolve o
comportamento antigo para os cinco ou para nenhum.

## Um slot num plano que não tem slots

A regra do tier é do plano, o slot é do site, e os dois são recursos separados. O compilador confere
cada um contra o próprio tipo e nunca o par:

```
ana@laptop:~/azure$ sed "s/name: 'P1v3'/name: 'B1'/" shop-web.bicep > basic.bicep
ana@laptop:~/azure$ bicep build basic.bicep
ana@laptop:~/azure$ jq -c '[.resources[0].sku.name, .resources[2].type]' basic.json
["B1","Microsoft.Web/sites/slots"]
```

**Um plano `B1` com um slot compila sem uma palavra**, e o template tem os dois. O Basic não tem
slots, então o Azure recusa este arquivo na implantação; em que ponto da implantação e com que
palavras cabe ao Azure dizer, isso precisa de uma assinatura, e nenhuma mensagem é citada aqui. Um
sexto slot no Standard é o mesmo tipo de erro. Um arquivo pode estar certo para todo tipo que nomeia
e ainda assim pedir algo que o tier não vende.

## Mandar alguns clientes para um slot

Um slot também pode receber uma parte do tráfego da produção antes de qualquer swap, que é a divisão
de tráfego da lição 8 com outro mecanismo. `az webapp traffic-routing set --distribution staging=10`
manda um décimo dos visitantes do endereço da produção para o staging, escolhidos ao acaso. A
escolha fica guardada num cookie, `x-ms-routing-name`, por uma hora, para que um cliente não
alterne entre versões a cada página. Um link com `?x-ms-routing-name=staging` deixa alguém entrar
de propósito, e `self` nomeia a produção. Não rodado neste curso: precisa de uma assinatura.

A lição 8 dividia o tráfego entre revisões de um app, por peso, com rótulos para endereços diretos.
Aqui a unidade é o slot, a parte é uma porcentagem no endereço da produção, e o slot tem endereço
próprio de qualquer forma. A seção depois desta usa o slot do jeito mais comum: não para dividir
tráfego, mas para fazer o swap.
