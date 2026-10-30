---
title: O OneLake, e o atalho que não copia nada
version: 1
---

**O OneLake é um lago de dados para o tenant inteiro, criado junto com ele, e ninguém o provisiona.**
Não há conta de armazenamento para nomear, replicação para escolher nem contêiner para criar: um
workspace é um contêiner, um item é uma pasta dentro dele, e uma tabela é uma pasta dentro dessa.
Esta seção é ensinada a partir da documentação da Microsoft e não foi executada; o formato que ela
descreve é o que a sexta seção grava no Azurite.

## Um endereço, e duas interfaces

**O OneLake é construído sobre o ADLS Gen2 e responde à interface dele**, o endpoint `dfs` da lição
3, e à interface de blob também. É por isso que ferramentas que já leem ADLS Gen2, como o Spark, o
Azure Storage Explorer, o `azcopy` e os SDKs do Azure, leem o OneLake com outro endereço e nenhuma
outra mudança. O endereço põe o workspace onde uma conta ADLS poria o sistema de arquivos:

| | ADLS Gen2, lição 3 | OneLake |
|---|---|---|
| host | `stquitandalakeprd.dfs.core.windows.net` | `onelake.dfs.fabric.microsoft.com` |
| sistema de arquivos, ou contêiner | `curated` | o workspace: `quitanda-analytics` |
| caminho | `orders/` | o item, depois a área dele: `sales.Lakehouse/Tables/orders/` |
| quem entra | quem os papéis da conta permitirem | uma identidade do Entra ID com papel no workspace |

**Há um host só para todos os tenants do mundo.** O OneLake sabe para que tenant é um pedido pela
identidade que o assinou, não pelo endereço, então duas empresas podem ter cada uma um workspace
chamado `sales` sem conflito. O acesso é concedido no workspace, pelos papéis dele, e nos itens
compartilhados a partir dele. Não há chave de conta, porque não há conta: a chave que a lição 6
chamou de raiz de tudo não existe aqui.

## Um lakehouse tem duas metades

**Toda pasta de lakehouse tem `Tables` e `Files`**, e a diferença importa:

- **`Tables`** guarda tabelas Delta, uma pasta cada. O Fabric as encontra sozinho e as lista como
  tabelas, legíveis por SQL, Spark e Power BI.
- **`Files`** guarda qualquer coisa, em qualquer formato: os exports CSV crus, imagens, JSON de uma
  API. Nada ali é tabela até um notebook ou um pipeline carregá-lo em `Tables`.

É a mesma divisão entre cru e curado que a Quitanda usa no Blob Storage, com a fronteira traçada pelo
produto: o export da noite cai em `Files`, e os pedidos limpos moram em `Tables`.

## Atalhos

**Um atalho (shortcut) é uma pasta no OneLake que aponta para outro lugar**, e lê-lo é ler o lugar
para onde ele aponta. Nada é copiado, nada é agendado, e nada fica desatualizado. Um atalho pode
apontar para outro lugar do OneLake, para o ADLS Gen2, para o Amazon S3, para o Google Cloud Storage
e para algumas outras origens que a Microsoft lista; em `Tables`, um atalho para uma pasta que guarda
uma tabela Delta aparece como tabela.

Os exports noturnos da Quitanda já caem numa conta de armazenamento fora do Fabric, gravados pelo
sistema da loja como as primeiras lições deste curso descrevem. Um atalho os põe no lakehouse sem
movê-los:

- a loja continua gravando onde sempre gravou, com as mesmas credenciais, e nada no código dela muda;
- o lakehouse vê `Files/exports` como uma pasta, e um notebook a lê como qualquer outra;
- a conta continua sendo o sistema de registro, com os próprios tiers, ciclo de vida e regras de
  imutabilidade das lições 4 e 5.

**O que um atalho não elimina é a conta do outro lado.** Uma leitura por um atalho para o S3 é uma
leitura do S3, cobrada pela Amazon pela requisição e, ao sair da nuvem dela, pela saída de dados, que
é a aritmética da lição 7 em outra moeda. Um atalho para uma conta do Azure em outra região paga a
transferência entre regiões. E um atalho usa uma credencial para chegar à origem, guardada numa
conexão do Fabric: quem pode usar o atalho lê com os direitos dessa credencial, então a credencial
deve poder ler a pasta para onde aponta e mais nada.

## Espelhamento, num parágrafo

**O espelhamento (mirroring) é a outra entrada no OneLake sem pipeline**: o Fabric mantém uma cópia
de um banco operacional, como o Azure SQL Database ou o Cosmos DB, como tabelas Delta no OneLake,
atualizada continuamente pelo fluxo de mudanças do próprio banco. É uma cópia, ao contrário de um
atalho, e existe porque um banco operacional não é uma pasta de arquivos para onde um atalho possa
apontar. A Quitanda poderia espelhar seu banco de pedidos da lição 8 em vez de exportá-lo toda
noite, e o lakehouse estaria minutos atrás da loja em vez de um dia.
