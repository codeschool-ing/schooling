---
title: A chave da conta abre tudo
version: 1
---

**Uma conta de armazenamento tem duas chaves, e qualquer uma delas faz qualquer coisa com qualquer
coisa da conta.** Ler todo blob, apagar todo contêiner, mudar as configurações do serviço de blob e
assinar acesso para outra pessoa. As pessoas imaginam a chave como a senha de um usuário. Ela está mais
perto da chave-mestra de um prédio: nada registra em que mão ela estava, e o único jeito de tomá-la de
volta de todo mundo que tem uma cópia é trocar a fechadura, o que tranca do lado de fora todo portador
honesto no mesmo momento.

Toda requisição das lições 1 a 5 foi assinada com ela. `UseDevelopmentStorage=true` é uma abreviação
que as bibliotecas expandem para o nome da conta do Azurite e a chave dela, e a chave é publicada pela
Microsoft porque não protege nada além de um laptop. Esta lição a escreve por extenso, junto com os
endereços que vai usar, para que cada pedaço de uma requisição fique visível. Primeiro o arquivo que ela
lê:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n29-1,c-17,4590\n29-2,c-03,12800\n' > export/orders-2026-10-29.csv
```

Depois quatro variáveis, digitadas no terminal que você usa nesta lição:

```sh
export KEY='Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=='
export ACCOUNT=http://127.0.0.1:10000/devstoreaccount1
export CONTAINER=$ACCOUNT/orders-raw
export BLOB=$CONTAINER/exports/2026/10/orders-2026-10-29.csv
```

## Assinado com a chave

```
ana@laptop:~/azure$ az storage container create -n orders-raw -o none && az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-29.csv -f export/orders-2026-10-29.csv --no-progress -o none
ana@laptop:~/azure$ env -u AZURE_STORAGE_CONNECTION_STRING az storage container list --account-name devstoreaccount1 --account-key "$KEY" --blob-endpoint "$ACCOUNT" --query "[].name" -o tsv
orders-raw
ana@laptop:~/azure$ env -u AZURE_STORAGE_CONNECTION_STRING az storage container list --account-name devstoreaccount1 --account-key "${KEY/E/F}" --blob-endpoint "$ACCOUNT" --query "[].name" -o tsv 2>&1
ERROR: 
The request may be blocked by network rules of storage account. Please check network rule set using 'az storage account show -n accountname --query networkRuleSet'.
If you want to change the default action to apply when no rule matches, please use 'az storage account update'.
                    
ana@laptop:~/azure$ az storage account keys list -n stquitandadataprd 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

**O segundo comando deixou a cadeia de conexão de fora e passou o nome da conta e a chave**, que é o
que a cadeia de conexão vinha fazendo o tempo todo: a linha de comando assina cada requisição com um
HMAC do conteúdo dela, calculado com a chave, e o Azurite recalcula e compara. O terceiro trocou um
caractere da chave, e o Azurite recusou a requisição porque a assinatura não bateu. A mensagem da linha
de comando não diz isso: a linha de erro vem vazia, e ela sugere conferir as regras de rede da conta,
que não têm nada a ver com o caso. **A causa é a assinatura.** A chave em si nunca viaja; só a
assinatura viaja.

O último comando pede as chaves de uma conta no Azure. É uma requisição do plano de controle, então
para no login, como todo comando desse tipo neste curso. No Azure, **quem consegue listar as chaves tem
as chaves**: a permissão para isso vem com papéis como Contributor na conta, e é assim que uma chave
acaba num script, num arquivo de configuração ou numa variável de pipeline, que é onde chaves vazadas
são encontradas.

## Duas chaves, para a rotação

Uma conta tem `key1` e `key2` para que uma possa ser trocada enquanto a outra continua funcionando. O
procedimento documentado pela Microsoft é mover todo cliente para a segunda chave, regenerar a
primeira, voltar os clientes e regenerar a segunda. Uma chave regenerada invalida toda assinatura feita
com a antiga, inclusive toda assinatura de acesso compartilhado da próxima seção que ela assinou: é a
única coisa que a rotação faz na hora, e é por isso que a rotação é a resposta de emergência a uma
chave vazada e a resposta bruta a uma assinatura vazada.

**Uma chave que nunca sai da conta não vaza.** O Azure tem dois jeitos de chegar lá, e os dois estão
na última seção desta lição: entrar com o Microsoft Entra ID em vez de uma chave, e desligar de vez o
acesso por chave compartilhada na conta.
