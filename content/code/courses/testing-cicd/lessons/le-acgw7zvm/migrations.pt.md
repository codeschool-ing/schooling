---
title: Mudando o banco sem parar
version: 1
---

Código se troca num segundo. Dados não. Um release que muda a forma do banco esbarra num fato duro da
entrega contínua: **por um tempo, o código velho e o código novo rodam contra o mesmo banco**, durante
o deploy, durante um canário na aula 10, e depois de um rollback na aula 11. Uma migração que só o
código novo entende quebra o código velho durante esse tempo.

## Uma mudança num passo só, e por que ela quebra

Suponha que o `shipquote` renomeie a coluna `cents` da tabela de cotações para `price_cents`, no mesmo
release do código que usa o nome novo. No momento em que a migração roda, todo processo ainda no
release antigo falha em toda consulta que nomeia `cents`. E se o release precisar ser revertido, o
código velho volta para uma coluna que não existe mais. **O rollback é quebrado pela migração**, que a
aula 11 chama de parte de um release que não se desfaz.

## Expandir, depois contrair

O padrão seguro divide uma mudança incompatível em várias compatíveis, cada uma um release próprio:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Cinco releases, cada um uma coluna, com o estado da coluna antiga cents e da nova price_cents. 1 expandir: cents lida e gravada, price_cents acrescentada. 2 gravar as duas: cents lida e gravada, price_cents gravada. 3 preencher: igual, linhas antigas copiadas. 4 ler a nova: cents gravada, price_cents lida e gravada. 5 contrair: cents apagada, price_cents lida e gravada.\"><text x=\"80\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1. expandir</text><rect x=\"20\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"80\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"80\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lida e gravada</text><rect x=\"20\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"80\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"80\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">criada, sem uso</text><text x=\"220\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">2. gravar as duas</text><rect x=\"160\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"220\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"220\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lida e gravada</text><rect x=\"160\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"220\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"220\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gravada</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3. preencher</text><rect x=\"300\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"360\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"360\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lida e gravada</text><rect x=\"300\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"360\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"360\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gravada</text><text x=\"500\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">4. ler a nova</text><rect x=\"440\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.3\" ></rect><text x=\"500\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"500\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gravada</text><rect x=\"440\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"500\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"500\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lida e gravada</text><text x=\"640\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">5. contrair</text><rect x=\"580\" y=\"50\" width=\"120\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"640\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cents</text><text x=\"640\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">apagada</text><rect x=\"580\" y=\"120\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" ></rect><text x=\"640\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">price_cents</text><text x=\"640\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lida e gravada</text><text x=\"360\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dois releases vizinhos quaisquer rodam lado a lado, então cada passo pode ser revertido</text></svg>", "caption": "Renomear uma coluna em cinco releases compatíveis. O preço é tempo; o que se compra é que nenhum passo depende de todos os servidores mudarem ao mesmo tempo."}
```

1. **Expandir.** Acrescentar a coluna nova, `price_cents`, ao lado da antiga. O código velho a ignora;
   nada quebra.
2. **Gravar as duas.** Publicar código que grava `cents` e `price_cents` e ainda lê `cents`. Releases
   velho e novo agora rodam lado a lado.
3. **Preencher.** Copiar os valores antigos para a coluna nova nas linhas gravadas antes do passo 2.
4. **Ler a nova.** Publicar código que lê `price_cents`. Voltar ao código do passo 2 continua seguro,
   porque as duas colunas são mantidas atualizadas.
5. **Contrair.** Quando nenhum release rodando lê `cents`, parar de gravá-la, e num release posterior
   apagá-la.

São mais releases e mais paciência. Em troca, **cada passo pode ser implantado e revertido sozinho**, a
qualquer hora do dia, que é a propriedade de que tudo mais neste curso depende.

## No pipeline

Uma migração faz parte do release, então passa pelo pipeline como código: roda primeiro na
homologação, contra dados com a forma dos da produção, e o smoke test dela inclui uma consulta à
tabela mudada. O repositório que publica este curso roda as migrações como um job separado **antes**
de mover o serviço para a revisão nova, e espera ele terminar, então uma migração que falha para o
release antes de qualquer código novo atender uma requisição.
