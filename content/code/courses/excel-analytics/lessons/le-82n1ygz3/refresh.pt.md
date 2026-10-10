---
title: Atualizar, e a cópia que a tabela dinâmica lê
version: 1
---

**Uma tabela dinâmica não lê a tabela `Sales`. Ela lê uma cópia dela, chamada cache da tabela
dinâmica, feita quando a tabela dinâmica foi montada ou atualizada pela última vez.** Uma fórmula
recalcula no instante em que uma célula de que depende muda; uma tabela dinâmica só muda quando alguém
a atualiza. Tudo o que dá errado com tabelas dinâmicas na prática vem de esquecer isso.

```schooling-figure
{"svg": "<svg data-fig=\"l10-cache\"></svg>", "caption": ""}
```

## Vendo a cópia

Deixe na tela a tabela dinâmica `By channel` da seção 02, com a fórmula de conferência da mesma seção
ao lado, ou numa célula da mesma planilha:

```localised
=SUMIFS(Sales[Revenue], Sales[Channel], "Wholesale")
```

As duas dizem **38.731**. Agora vá à tabela `Sales` e mude os sacos da venda `S1001`, em E2, de `14`
para `15`. A receita dela vira 1.560. De volta a `By channel`:

- a fórmula diz **38.835**, o total novo, na hora;
- a tabela dinâmica continua dizendo **38.731**.

Clique com o botão direito na tabela dinâmica e escolha **Atualizar** (**Refresh**). Agora ela também
diz **38.835**, e o total geral é **51.598**. **Quando uma tabela dinâmica e uma fórmula discordam,
atualize a tabela dinâmica antes de desconfiar de qualquer outra coisa**; é de longe a causa mais
comum.

Ponha `14` de volta em E2 e atualize de novo, para os totais voltarem a **38.731** e **51.494**. As
aulas depois desta contam com os dados originais.

## Atualizando tudo

**Dados › Atualizar Tudo** (**Data › Refresh All**) atualiza todas as tabelas dinâmicas da pasta de
trabalho, e todas as consultas, que as aulas 13 e 14 acrescentam. Em **Analisar Tabela Dinâmica ›
Opções**, na guia **Dados**, a caixa **Atualizar dados ao abrir o arquivo** faz o Excel atualizar a
tabela dinâmica toda vez que a pasta abre. Isso cobre uma pasta que outra pessoa atualiza e você só
lê; não ajuda enquanto você edita, porque o arquivo já está aberto.

## Linhas novas

Uma venda incluída no fim da tabela `Sales` entra na tabela, como a aula 7 mostrou, e a próxima
atualização a traz para a tabela dinâmica, porque a fonte dela é a tabela e não um endereço fixo. Para
ver a fonte, use **Analisar Tabela Dinâmica › Alterar Fonte de Dados** (**Change Data Source**): ela
deve dizer `Sales`.

Uma tabela dinâmica montada sobre um endereço como `Sales!$A$1:$H$109` continua lendo aquelas células.
Uma venda digitada na linha 110 fica fora delas, e nenhuma atualização a traz; a fonte tem de ser
ampliada à mão em **Alterar Fonte de Dados**, toda vez. É a mesma armadilha da lista fixa da aula 8, e
a mesma cura: montar sobre a tabela.

## Quando uma atualização muda o layout

Uma atualização relê os dados, então pode acrescentar linhas que a tabela dinâmica não tinha: um
produto novo, um trimestre novo ou um canal com erro de digitação. Ela também pode ficar mais larga ou
mais comprida, e **uma tabela dinâmica que cresce não empurra as células do caminho**. Se houver algo
nas células de que ela precisa, o Excel pergunta antes de sobrescrever, ou recusa. Deixe espaço vazio
em volta de uma tabela dinâmica, ou dê a cada uma a própria planilha, como esta aula fez.

Mantenha as planilhas de tabela dinâmica desta aula. A aula 17 monta um painel com peças desse tipo, e
a aula 11 acrescenta campos calculados, segmentações e linhas do tempo a tabelas dinâmicas como estas.
