---
title: O servidor de metadados
version: 1
---

Toda máquina do Compute Engine alcança um endereço que não pertence a nenhuma rede que você criou:
`169.254.169.254`, também conhecido pelo nome `metadata.google.internal`. **Quem responde é o host
em que a máquina roda, e é por ele que a máquina descobre tudo sobre si mesma**: o nome, a zona,
os atributos que você definiu e o token de acesso da conta de serviço. O script de inicialização da
seção anterior fez duas perguntas a ele; esta seção é sobre o que mais ele responde e o que recusa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Dentro do host, o servidor de metadados em 169.254.169.254 guarda três tipos de valor: atributos do projeto, atributos da instância e o token da conta de serviço. Um processo na instância manda um GET com o cabeçalho Metadata-Flavor: Google e recebe o valor. Uma requisição sem o cabeçalho é recusada com 403. Nada fora do host alcança o endereço.\"><defs><marker id=\"md7-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"688\" height=\"298\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">o host</text><rect x=\"40\" y=\"56\" width=\"250\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">servidor de metadados</text><text x=\"165.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">169.254.169.254</text><rect x=\"40\" y=\"128\" width=\"250\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">atributos do projeto</text><rect x=\"40\" y=\"172\" width=\"250\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">atributos da instância</text><rect x=\"40\" y=\"216\" width=\"250\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"165.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o token da conta de serviço</text><rect x=\"440\" y=\"56\" width=\"240\" height=\"194\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a instância</text><rect x=\"470\" y=\"100\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">um processo</text><text x=\"560.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">curl, um SDK, o agente</text><path d=\"M470 116 L292 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#md7-ah)\"></path><text x=\"381\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Metadata-Flavor: Google</text><path d=\"M292 98 L470 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#md7-ah)\"></path><text x=\"381\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o valor</text><rect x=\"470\" y=\"190\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">uma requisição sem cabeçalho</text><path d=\"M470 210 L380 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#md7-ah)\"></path><text x=\"330\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">403</text><text x=\"360\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada fora do host alcança o endereço</text></svg>", "caption": "Um endereço por máquina, respondido pelo host em que ela roda. O cabeçalho é o preço de toda resposta; o token é a coisa mais valiosa atrás dele."}
```

## Perguntando a ele

Cada valor tem um caminho sob `/computeMetadata/v1/`, em duas árvores. `project/` guarda o que vale
para toda máquina do projeto, como `project/project-id` e os atributos do projeto em
`project/attributes/`. `instance/` guarda o que é desta máquina: `instance/name`, `instance/zone`,
`instance/network-interfaces/0/ip`, os atributos que você definiu em `instance/attributes/`, e
`instance/service-accounts/`, que a próxima seção abre.

**Toda requisição precisa levar o cabeçalho `Metadata-Flavor: Google`**, e toda resposta o traz de
volta. A documentação do Google diz que uma requisição sem o cabeçalho é recusada com
`403 Forbidden`, assim como qualquer requisição com `X-Forwarded-For`, o cabeçalho que um proxy
acrescenta quando repassa uma requisição. Dois parâmetros de consulta valem conhecer.
`?recursive=true` devolve uma árvore inteira como JSON em vez de um valor. `?wait_for_change=true`
faz a requisição esperar até o valor mudar, para um script reagir a um atributo novo sem perguntar a
cada poucos segundos; é assim que o próprio ambiente convidado percebe uma chave SSH nova.

Do seu laptop o endereço não leva a lugar nenhum, o que é fácil de confirmar:

```
ana@laptop:~/gcp/meta$ curl -sS -m 5 -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/project/project-id; echo "exit status $?"
curl: (7) Failed to connect to 169.254.169.254 port 80 after 0 ms: Couldn't connect to server
exit status 7
```

Este laboratório não tem rota nenhuma para `169.254.169.254`, então o `curl` falhou na hora com
status 7. Num laptop numa rede comum, a mesma requisição em geral espera até o tempo limite de cinco
segundos, porque ninguém responde; de um jeito ou de outro a resposta é a mesma. Todo o resto desta
seção é comportamento documentado pelo Google e não foi executado.

## Por que o cabeçalho existe

O cabeçalho é a resposta do Google a uma classe de bug, a **falsificação de requisição do lado do
servidor**, SSRF. Muito software num servidor busca um endereço que outra pessoa escolheu: uma
aplicação que baixa uma imagem de uma URL que o usuário digitou, um disparador de webhooks, um
gerador de PDF que segue links. Aponte um deles para `http://169.254.169.254/...` e ele faz a
requisição de dentro da máquina, onde o servidor de metadados vai responder.

O que esse software raramente consegue é acrescentar um cabeçalho escolhido pelo atacante. Então o
servidor recusa qualquer requisição sem `Metadata-Flavor: Google`, e a busca forjada recebe um
`403` em vez do token da conta de serviço. A regra do `X-Forwarded-For` fecha o outro caminho comum:
um proxy reverso na máquina, enganado para repassar uma requisição ao endereço de metadados,
acrescenta esse cabeçalho no caminho e é recusado por isso.

**O cabeçalho é um filtro, não uma tranca.** Um software que o atacante controla por completo, um
shell na máquina ou uma dependência que virou maliciosa, manda o cabeçalho como qualquer outra coisa
e recebe o token. Nada na máquina fica protegido da própria máquina, e é por isso que as duas
próximas seções tratam de fazer o token valer o mínimo possível.

## Valores que não devem ir ali

Metadados são legíveis por todo processo da máquina e por todo mundo com permissão de ver a
instância, e aparecem num plan do Terraform palavra por palavra, como a seção anterior mostrou.
Então é o lugar certo para o nome do ambiente da loja e o lugar errado para a senha de um banco de
dados. Um segredo pertence ao Secret Manager, buscado na inicialização com a identidade da própria
máquina; o `gcp-operations` trata disso.
