---
title: Comportamentos, a chave de cache, e esquecer um arquivo
version: 1
---

**Um comportamento de cache (*cache behavior*) é um padrão de caminho e as regras para o que casa com
ele**: qual origem responde, se a resposta é guardada, por quanto tempo, e o que uma requisição precisa
ter em comum com uma anterior para ser respondida pela mesma cópia. A distribuição da seção anterior
tem dois. A imagem errada é que o CloudFront guarda "o arquivo" em cache. Ele guarda **uma cópia por
chave de cache**, e a chave de cache é algo que você decide.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l23-behaviours\" aria-label=\"Uma distribuição, dois comportamentos. A requisição de quem vê chega à distribuição, que tenta os padrões de caminho em ordem. Requisições para /static/* usam a política CachingOptimized, com chave no caminho e guardadas por um dia por padrão, e vão para a origem assets, o bucket shop-assets, que só a distribuição consegue ler pelo Origin Access Control e pela política do bucket. Todo o resto casa com o comportamento padrão, usa CachingDisabled com a política de requisição de origem AllViewer, e vai para a origem web, o balanceador shop-web, com os cookies de quem vê.\"><defs><marker id=\"l23-behaviours-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-behaviours-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"125.0\" width=\"110.0\" height=\"50.0\" rx=\"25\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quem vê</text><path d=\"M132.0 150.0 L176.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l23-behaviours-af-ah-paper-dim)\"></path><rect x=\"180.0\" y=\"30.0\" width=\"300.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a distribuição</text><rect x=\"196.0\" y=\"70.0\" width=\"268.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/static/*</text><text x=\"212.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CachingOptimized</text><text x=\"212.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">chave: o caminho; guarda um dia</text><text x=\"212.0\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">comprimido</text><rect x=\"196.0\" y=\"172.0\" width=\"268.0\" height=\"92.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">padrão (todo o resto)</text><text x=\"212.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CachingDisabled</text><text x=\"212.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AllViewer</text><text x=\"212.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nada guardado; cookies repassados</text><rect x=\"560.0\" y=\"80.0\" width=\"140.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-assets</text><text x=\"630.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">bucket, privado</text><text x=\"630.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">lido só via OAC</text><rect x=\"560.0\" y=\"182.0\" width=\"140.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-web</text><text x=\"630.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">balanceador</text><path d=\"M466.0 115.0 L556.0 115.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-behaviours-af-ah-amber)\"></path><text x=\"511.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">assets</text><path d=\"M466.0 217.0 L556.0 217.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-behaviours-af-ah-paper-dim)\"></path><text x=\"511.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">web</text><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o caminho escolhe o comportamento; o comportamento escolhe a origem e o cache</text></svg>", "caption": "As imagens ficam em cache uma vez para todo mundo; as páginas passam sem ser tocadas."}
```

## A chave de cache

**A chave de cache é a lista de coisas que precisam bater para uma cópia guardada responder a uma
requisição nova.** Por padrão ela é a distribuição e o caminho, então todo mundo que pede
`/static/logo.png` recebe a mesma cópia. Ponha o cabeçalho `Accept-Language` na chave e passa a haver
tantas cópias do logo quantos idiomas os navegadores mandam; ponha um cookie que carrega um id de
sessão e passa a haver uma cópia por cliente, que é cache nenhum. **Tudo o que entra na chave divide a
taxa de acerto**, então só pertence a ela o que muda a resposta de verdade.

O que é mandado à origem é outra pergunta. Uma **política de requisição de origem** (*origin request
policy*) repassa cabeçalhos, cookies e query strings à origem **sem** pô-los na chave, e é assim que a
API ainda recebe os cookies do cliente enquanto as imagens são compartilhadas por todo mundo.

As duas são citadas em cada comportamento, pelo id da política, e os três ids em `distribution.json`
são **políticas gerenciadas** da AWS, publicadas com ids fixos para qualquer um usar:

| id | política gerenciada | o que ela faz |
|---|---|---|
| `658327ea-f89d-4fab-a63d-7e88639e58f6` | `CachingOptimized` (cache) | chave só no caminho; guarda um dia por padrão, até um ano se a origem disser; comprime |
| `4135ea2d-6df8-44a3-9df3-4b5a84be39ad` | `CachingDisabled` (cache) | não guarda nada: toda requisição vai à origem |
| `216adef6-5c7f-47e4-b989-5492eafa07d3` | `AllViewer` (requisição de origem) | repassa todo cabeçalho, cookie e query string que quem vê mandou |

Então `/static/*` fica em cache para todo mundo, e as páginas e a API passam direto ao balanceador com
os cookies de quem vê, que é o que uma cesta de quem está logado precisa. Peça ao moto as políticas
gerenciadas e ele não tem nenhuma para dar:

```
ana@laptop:~/aws$ aws cloudfront list-cache-policies --type managed

aws: [ERROR]: An error occurred (404) when calling the ListCachePolicies operation: Not Found
```

**O moto 5.2.3 não implementa políticas de cache**, então tomou os ids da configuração como texto e
não verificou nada sobre eles; a tabela vem da documentação da AWS sobre as políticas gerenciadas. O
que ele guardou é isto:

```
ana@laptop:~/aws$ aws cloudfront get-distribution-config --id $id --query "DistributionConfig.CacheBehaviors.Items[].[PathPattern,TargetOriginId,CachePolicyId,Compress]" --output text
/static/*	assets	658327ea-f89d-4fab-a63d-7e88639e58f6	True
```

## TTLs, e quem os decide

**Um TTL aqui é quanto tempo um ponto de presença pode guardar uma cópia antes de perguntar de novo à
origem**, e ele é decidido por duas partes. A origem manda `Cache-Control: max-age=…` com cada
arquivo; a política de cache define um mínimo, um padrão para arquivos que não dizem nada, e um
máximo. Para a `CachingOptimized` esses são um segundo, um dia e um ano, então um arquivo que a origem
marca `max-age=31536000` fica guardado um ano, um arquivo sem cabeçalho fica um dia, e uma origem não
consegue fazer o CloudFront guardar nada por menos de um segundo sob essa política.

Quando uma cópia expira, o ponto de presença nem sempre baixa o arquivo de novo: ele pergunta à
origem se o arquivo mudou, e um arquivo inalterado custa uma resposta pequena em vez do arquivo
inteiro. É também por isso que uma origem que não manda cabeçalho `ETag` nem `Last-Modified` sai
mais cara de ter atrás do CloudFront do que uma que manda.

## Invalidação: mandar os pontos de presença esquecerem

A loja muda o `shop.css` e os pontos de presença ainda guardam o antigo por até um dia. **Uma
invalidação tira caminhos de todo cache de ponto de presença**, para que a próxima requisição por
eles vá à origem:

```
ana@laptop:~/aws$ aws cloudfront create-invalidation --distribution-id $id --paths "/static/css/shop.css" "/static/js/*"
{
    "Location": "https://cloudfront.amazonaws.com/2020-05-31/distribution/DOF70T4DOCRTU/invalidation/OM16QPJ5DNZ5H",
    "Invalidation": {
        "Id": "OM16QPJ5DNZ5H",
        "Status": "COMPLETED",
        "CreateTime": "2026-10-16T16:35:14.883852+00:00",
        "InvalidationBatch": {
            "Paths": {
                "Quantity": 2,
                "Items": [
                    "/static/css/shop.css",
                    "/static/js/*"
                ]
            },
            "CallerReference": "cli-1792168514-28452"
        }
    }
}
```

```
ana@laptop:~/aws$ aws cloudfront list-invalidations --distribution-id $id --query "InvalidationList.Items[].[Id,Status]" --output text
OM16QPJ5DNZ5H	COMPLETED
```

**O moto respondeu `COMPLETED` na hora**, como respondeu `INSYNC` na lição 21: não há pontos de
presença para limpar. Na AWS uma invalidação começa `InProgress` e termina quando todo ponto de
presença descartou os caminhos. O `CallerReference` da resposta é um que a linha de comando inventou a
partir do relógio, já que o comando não recebeu nenhum; um script que pode repetir deve passar o seu
próprio, pelo mesmo motivo da zona da lição 21.

O `*` no fim de `/static/js/*` é um curinga e cobre todo arquivo sob aquele caminho. **A AWS conta um
caminho com curinga como um caminho só**, o que importa para o preço, e é também como um `/*`
descuidado esvazia o cache da distribuição inteira e manda a próxima requisição de todo mundo à
origem de uma vez.

## Por que um nome novo vence uma invalidação

**Uma invalidação limpa os caches do CloudFront, e só eles.** O navegador que carregou o `shop.css`
antigo ontem fica com a própria cópia pelo tempo que o cabeçalho mandou, e qualquer proxy no caminho
também; o CloudFront não tem como alcançar nenhum dos dois. E durante os minutos que a invalidação
leva, alguns pontos de presença servem o arquivo novo e outros o antigo, para páginas que podem
esperar o outro.

O hábito que evita tudo isso é **pôr a versão no nome do arquivo**: o build escreve
`shop.3f9a2c.css`, a página aponta para esse nome, e a próxima mudança produz `shop.81d0e7.css`.

- **Nada precisa ser esquecido**, porque um nome novo nunca esteve em cache em lugar nenhum.
- **O nome antigo continua funcionando** para toda página que ainda aponta para ele, então quem está
  no meio de uma implantação nunca recebe uma folha de estilos que não bate com a página.
- **O arquivo pode ficar guardado para sempre**, `Cache-Control: max-age=31536000, immutable`, pelo
  CloudFront e por todo navegador, que é a melhor taxa de acerto que existe.
- **Não custa nada**, enquanto caminhos de invalidação além da cota mensal são cobrados.

Então as páginas, que mantêm os nomes, são as que não ficam muito tempo em cache, e tudo sob
`/static/` ganha um nome com versão e um ano. A invalidação fica para a emergência: um arquivo que
nunca deveria ter sido publicado.
