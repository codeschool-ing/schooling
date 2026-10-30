---
title: Nomes que duram
version: 1
---

**Três coisas recebem nome no Blob Storage, e nenhuma delas pode ser renomeada**: a conta, o
contêiner e o blob. O nome de uma conta é fixado na criação. Um contêiner não tem operação de
renomear. Um blob só pode ser copiado para um nome novo e o antigo apagado, o que para um milhão de
blobs são dois milhões de operações e, no Azure, uma fatura. Então um nome é escolhido uma vez, e
precisa continuar fazendo sentido quando a empresa tiver mais três equipes e mais cinco anos de dados.

## A conta: curta, global e pública

**O nome de uma conta de armazenamento tem de 3 a 24 caracteres, só letras minúsculas e dígitos, e é
único em todo o Azure**, porque vira um nome de host sob `core.windows.net` que qualquer pessoa na
internet pode consultar. As duas primeiras regras o provider confere, então o Terraform recusa um nome
antes de mandar qualquer coisa:

```
ana@laptop:~/azure/tf/account$ sed -i 's/stquitandadataprd/st-quitanda-data-prd/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: invalid value for name (can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long)
ana@laptop:~/azure/tf/account$ sed -i 's/st-quitanda-data-prd/stquitandadataanalyticsprd/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: invalid value for name (can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long)
```

No primeiro, os hífens são recusados, e no segundo, o tamanho: `stquitandadataanalyticsprd` tem 26
caracteres. **A terceira regra, a unicidade, ninguém consegue conferir offline.** Só o Azure sabe
quais nomes estão ocupados, e um nome que passa no `validate` ainda pode falhar na criação porque
alguém em algum lugar já o tem. É por isso que os nomes carregam a empresa e não só a finalidade:
`stdata` foi ocupado há anos, `stquitandadataprd` muito provavelmente não.

Vinte e quatro caracteres sem separadores é apertado, então a convenção que o Cloud Adoption Framework
da Microsoft sugere, e que a Quitanda segue, encaixa as partes numa ordem fixa:

| parte | exemplo | por quê |
|---|---|---|
| tipo de recurso | `st` | para que um nome num log diga o que é |
| organização | `quitanda` | unicidade, e de quem é a fatura |
| carga de trabalho | `data`, `lake`, `logs` | o que mora ali |
| ambiente | `prd`, `dev` | para que produção nunca seja tocada por engano |

**Deixe a região de fora, a menos que você vá mesmo ter duas.** Um nome que diz `brs`, de Brazil
South, vira mentira no dia em que os dados forem replicados para uma segunda região, e não pode ser
mudado.

## O contêiner: um pouco mais de espaço

O nome de um contêiner tem de 3 a 63 caracteres: letras minúsculas, dígitos e hífens isolados,
começando com letra ou dígito. O Azurite aplica as mesmas regras que o Azure, então esta é uma recusa
de verdade:

```
ana@laptop:~/azure$ az storage container create -n Orders 2>&1 | head -2
ERROR: The specified resource name contains invalid characters.
RequestId:ae4b4168-5b97-47c7-b5c2-f6db4a9cc820
ana@laptop:~/azure$ az storage container create -n or 2>&1 | head -2
ERROR: The specified resource name length is not within the permissible limits.
RequestId:61467083-44bb-4f56-9c04-f8146d89b4f6
ana@laptop:~/azure$ az storage container create -n orders-raw
{
  "created": true
}
```

A Quitanda nomeia os contêineres pela **etapa em que os dados estão**, não por quem os escreveu:
`orders-raw` para as exportações noturnas como a loja as produziu, e mais tarde `orders-curated` para
a versão limpa que os analistas leem. O contêiner também é onde o acesso costuma ser concedido, então
um contêiner que mistura dois públicos é uma permissão que não se consegue dar direito a nenhum dos
dois.

## O blob: a barra é só um caractere

O nome de um blob pode ter até 1.024 caracteres e pode conter `/`, e é dessa barra que as pastas
parecem vir:

```
ana@laptop:~/azure$ echo x > x.csv && az storage blob upload -c orders-raw -n "exports/2026/10/29/orders.csv" -f x.csv -o none 2>/dev/null && az storage blob list -c orders-raw --query "[].name" -o tsv
exports/2026/10/29/orders.csv
```

**Há um blob aqui, e nenhuma pasta chamada `exports`.** O nome é a string inteira, com as barras, e
as ferramentas de listagem desenham pastas cortando os nomes na barra. A lição 2 mostra esse corte, e
a lição 3 mostra o único tipo de conta em que as pastas são reais. O que importa para os nomes é a
ordem: **ponha primeiro a parte pela qual você vai filtrar, e as datas como ano, mês e dia, com zeros
à esquerda.** Uma lista ordenada por nome fica então ordenada por data, e "tudo de outubro" é um
prefixo só, `exports/2026/10/`, em vez de uma varredura de todos os blobs do contêiner.
