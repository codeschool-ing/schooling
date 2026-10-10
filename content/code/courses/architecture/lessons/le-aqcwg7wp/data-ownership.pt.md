---
title: Um banco por serviço
version: 1
---

O atalho que desfaz uma divisão é o banco compartilhado. Dois serviços, um banco, cada um lendo as
tabelas do outro diretamente porque é mais rápido do que chamar uma API. Funciona no primeiro dia, e
daí em diante **cada coluna de cada tabela compartilhada faz parte do contrato entre os serviços**, um
contrato que ninguém escreveu e ninguém consegue versionar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Dois desenhos. À esquerda, a loja e o serviço de estoque leem e escrevem num banco compartilhado, com setas se cruzando nas mesmas tabelas. À direita, cada serviço tem o seu banco, e a loja só obtém dados de estoque chamando a API do serviço de estoque.\"><defs><marker id=\"l2-ownership-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l2-ownership-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"340\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"370\" y=\"10\" width=\"340\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">banco compartilhado</text><text x=\"540\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">um banco por serviço</text><rect x=\"40\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop</text><rect x=\"210\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><rect x=\"60\" y=\"170\" width=\"240\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um banco</text><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stock, orders, products</text><path d=\"M95 92 L230 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-amber)\"></path><path d=\"M265 92 L130 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-amber)\"></path><rect x=\"400\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop</text><rect x=\"570\" y=\"50\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><rect x=\"400\" y=\"170\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.db</text><rect x=\"570\" y=\"170\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock.db</text><path d=\"M455 92 L455 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-phosphor)\"></path><path d=\"M625 92 L625 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-phosphor)\"></path><path d=\"M512 70 L568 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-ownership-ah-phosphor)\"></path><text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">API</text></svg>", "caption": "Um banco compartilhado acopla os dois serviços por cada coluna de cada tabela que ambos tocam. Ser dono do dado põe o acoplamento num lugar só, a API, onde dá para versioná-lo.", "same": ["API"]}
```

Com uma tabela compartilhada, a equipe de estoque não consegue renomear uma coluna, dividir uma tabela
ou mudar o que `units` significa sem achar cada consulta de cada outro serviço que a lê e lançar todos
juntos. É exatamente a release coordenada que a divisão devia acabar. **Ser dono do dado é o que torna
a implantação independente possível**; sem isso, os serviços são independentes só no diagrama.

No laboratório a regra é física: `stock.db` está no volume `stock-data`, montado só no contêiner de
estoque, então a loja não tem como abri-lo. Em produção a mesma regra costuma ser mantida dando a
cada serviço um usuário de banco próprio, sem permissão no esquema do outro, ou um servidor de banco
próprio.

## Quando outro serviço precisa do seu dado

A loja precisa das contagens de estoque para mostrar o catálogo. Há três jeitos de dar isso a ela, e
eles trocam atualidade por independência:

| jeito | quão atual | do que a loja depende |
| --- | --- | --- |
| **perguntar**: chamar a API do serviço de estoque quando o dado é necessário | o mais atual possível | o serviço de estoque estar de pé e rápido, em toda requisição |
| **escutar**: o serviço de estoque publica um evento a cada mudança de contagem, e a loja guarda a sua própria cópia | um pouco atrás, pelo tempo que um evento leva | os eventos chegarem, em ordem, uma vez; aulas 5 a 7 |
| **copiar em lote**: uma réplica só de leitura ou uma exportação noturna | atrás até o intervalo da cópia | a rotina de cópia, e um esquema que ela precisa acompanhar |

A loja da Quitanda pergunta, que é o mais simples e serve neste tamanho. A aula 9 mostra o que um
cliente vê quando a loja escuta em vez disso e a cópia dela está um instante atrasada.

## O que custa

Dois bancos são duas coisas para fazer backup, atualizar e vigiar. Um relatório que precisa de dados
dos dois, digamos "unidades vendidas por produto, com o preço", não é mais um `JOIN`: precisa chamar
duas APIs ou ler de algum lugar que tenha os dois, que muitas vezes é um armazenamento separado
construído para relatórios. E há a transação que não existe mais, da seção anterior. **O custo é real
e é o preço da independência**; uma equipe que não está usando a independência não devia estar
pagando por ela.
