---
title: Uma pasta de arquivos como uma tabela só
version: 1
---

**De Pasta lê cada arquivo de uma pasta como linhas de uma mesma consulta, então a exportação do mês
seguinte entra salvando-a na pasta e clicando em Atualizar Tudo.** Nenhuma consulta muda, nenhuma
linha é copiada, e um arquivo que chega atrasado entra na próxima atualização como qualquer outro.

## Mais dois meses

Salve estas duas exportações na pasta `web`, ao lado de `web-2026-07.csv`, como a seção 03 fez.
Agosto é `web-2026-08.csv`:

```
.
```

E setembro é `web-2026-09.csv`:

```
.
```

Três coisas nelas não estão arrumadas, e ficaram assim de propósito: dois pedidos foram cancelados,
dois códigos de produto foram digitados em minúsculas e, em setembro, o Mogiana Reserve estava em
promoção a R$ 49,50 o saco. Uma exportação de verdade traz coisas assim, e a aula 14 as limpa. Esta
seção só traz as linhas para dentro.

## Combinando a pasta

Vá em **Dados › Obter Dados › De Arquivo › De Pasta** e escolha a pasta `web`. O Excel lista o que
encontrou, uma linha por arquivo, com colunas como `Name`, `Extension` e `Date modified`. Nada foi
lido de dentro dos arquivos ainda: isto é uma lista de arquivos, e a primeira coluna, `Content`,
guarda cada arquivo fechado.

Embaixo, abra **Combinar** e escolha **Combinar e Transformar Dados**. Uma caixa **Combinar
Arquivos** mostra o primeiro arquivo como amostra, com as mesmas três caixas que a seção 03 usou.
Confira se o delimitador é **Vírgula**, escolha **Não detectar tipos de dados** e clique em **OK**.

```schooling-figure
{"svg": "<svg data-fig=\"l13-folder\"></svg>", "caption": ""}
```

O editor agora mostra uma consulta com o nome da pasta, `web`, com **24 linhas**: 7 de julho, 9 de
agosto e 8 de setembro. A linha de cabeçalho de cada arquivo foi usada uma vez, para os nomes das
colunas, e descartada nos outros. Uma primeira coluna nova, `Source.Name`, diz de que arquivo veio
cada linha, e é assim que você vai distinguir os meses se um dia faltar uma data.

Defina os tipos como na seção 03, com **Usando a Localidade…** e Inglês (Estados Unidos): `Date`
como Data, `Qty` como Número Inteiro e `Unit price` como Número Decimal. Os três meses então somam
**60 sacos** num valor de **R$ 3.284,50**, contando os pedidos cancelados, que a aula 14 tira.

Renomeie a consulta para `WebOrders` e use **Página Inicial › Fechar e Carregar**. De volta à pasta de
trabalho, apague a consulta de julho da seção 03: clique nela com o botão direito em **Consultas e
Conexões**, escolha **Excluir** e apague a planilha em que ela foi carregada. `WebOrders` já tem
todas as linhas de julho.

## O que o Excel montou para você

O painel **Consultas e Conexões** agora mostra mais de uma consulta. Ao lado de `WebOrders` há um
grupo, em geral chamado **Transformar Arquivo de web** (Transform File from web), com algumas
consultas auxiliares: um arquivo de amostra, um parâmetro e uma função chamada **Transformar Arquivo**.

Elas existem porque a combinação é feita em duas metades. **Transformar Arquivo de Amostra** guarda as
etapas aplicadas a cada arquivo sozinho: ler o texto, dividir nas vírgulas, promover o cabeçalho. A
função é uma cópia dessas etapas que pode ser apontada para qualquer arquivo. A consulta principal
lista a pasta e chama a função uma vez por arquivo, depois empilha o que volta.

Então há dois lugares para mudar uma etapa, e eles significam coisas diferentes. Uma etapa em
**Transformar Arquivo de Amostra** acontece com cada arquivo antes de empilhar. Uma etapa em
`WebOrders` acontece com todas as linhas juntas, depois. Uma mudança de que cada arquivo precisa
sozinho, como pular uma linha que a plataforma escreve acima do cabeçalho, vai na amostra; o resto vai
na consulta principal.

## O que a quebra

**Um arquivo de outro formato na pasta.** As etapas da amostra são aplicadas a todo arquivo, então a
fatura da transportadora salva em `web` seria dividida nas vírgulas e empilhada sob os pedidos como
lixo. Por isso a seção 03 a salvou uma pasta acima. Como proteção, abra `WebOrders`, clique na
primeira etapa, `Source`, e filtre a coluna `Name` com **Filtros de Texto › Começa Com** e `web-`. O
Excel pergunta antes de inserir uma etapa no meio da lista; responda que sim. Um arquivo perdido salvo
na pasta depois passa a ser ignorado.

**Um cabeçalho que muda.** Se um dia a plataforma chamar a coluna de `Quantity` em vez de `Qty`, as
linhas daquele mês chegam com a quantidade numa coluna de que a consulta nunca ouviu falar. A seção 07
da aula 14 mostra como isso aparece como erro, e o que fazer.

## No mês que vem

Quando a exportação de outubro chegar, salve-a em `web` como `web-2026-10.csv` e escolha **Dados ›
Atualizar Tudo**. É o trabalho inteiro. A consulta lista a pasta de novo, encontra quatro arquivos e
combina todos, e tudo o que a aula 14 construir sobre `WebOrders` acompanha.
