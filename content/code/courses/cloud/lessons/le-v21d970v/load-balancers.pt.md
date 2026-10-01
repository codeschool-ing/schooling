---
title: "Balanceadores de carga: um endereço na frente de muitas máquinas"
version: 1
---

Uma aplicação que roda numa máquina cai junto com ela. Rode em quatro, e um cliente ainda precisa de um
endereço só para se conectar, um que não mude quando uma máquina é trocada. **Um balanceador de carga é
esse endereço.** Os clientes se conectam a ele; ele passa cada conexão ou pedido para uma das máquinas
atrás dele, que o provedor chama de **alvos** (targets), e para de mandar para qualquer alvo que não
esteja saudável.

Na AWS um balanceador de carga é alcançado por um nome DNS que o provedor lhe dá, e o provedor muda
os endereços por trás desse nome quando quiser; você aponta o seu próprio nome para ele e
nunca anota o endereço.

## Camada 4 ou camada 7

As camadas do OSI de `networks` são o jeito mais limpo de separar os dois tipos.

**Um network load balancer trabalha na camada 4.** Na forma simples, ele encaminha conexões TCP ou
UDP: vê endereços e portas, escolhe um alvo e passa os bytes adiante sem lê-los. Não sabe se são HTTP,
um protocolo de banco ou um jogo. Isso faz dele a escolha para tudo o que não é HTTP, e para números
muito altos de conexões.

**Um application load balancer trabalha na camada 7.** Ele fala HTTP: encerra ele mesmo a conexão TLS
do cliente, guardando o certificado, lê o pedido e pode rotear pelo que leu. Pedidos para
`api.example.com` vão para um grupo de alvos e `www.example.com` para outro; `/images/` para um
serviço e todo o resto para a aplicação. O preço de ler o pedido é que a conexão que o alvo vê vem do
balanceador, não do cliente. O endereço do cliente chega no cabeçalho `X-Forwarded-For`, e uma
aplicação que registra o endereço de origem da conexão registra o do balanceador.

## Health checks

**Um balanceador de carga confere cada alvo no próprio ritmo**, abrindo uma conexão ou pedindo um
caminho como `/health` a cada poucos segundos. O balanceador marca como não saudável um alvo que falha
em várias verificações seguidas e para de mandar tráfego a ele, e o traz de volta quando ele volta a passar. É assim
que uma máquina que caiu às três da manhã para de receber clientes antes de alguém acordar. Um grupo
de autoscaling da aula 4 pode ser configurado para usar a mesma verificação, de modo que ele substitua
a instância além de desviar dela.

A verificação só é tão boa quanto o caminho que ela pede. Um `/health` que devolve 200 com o banco
inalcançável mantém um alvo quebrado em serviço; um que falha sempre que o banco fica lento pode tirar
todos os alvos de uma vez.

## Entre zonas

Um balanceador de carga recebe uma sub-rede em cada zona que deve atender, e roda nós em cada uma. Ele
fica nas sub-redes **públicas**, porque é ali que os clientes o alcançam, e os alvos ficam em privadas.
Com alvos em duas zonas, perder uma zona custa metade da capacidade, e não a aplicação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Clientes se conectam a um application load balancer, que abrange a zona a e a zona b. Ele manda tráfego para três alvos saudáveis, 10.0.32.10 e 10.0.32.11 na zona a e 10.0.48.12 na zona b. O quarto alvo, 10.0.48.13 na zona b, falha no health check em /health e não recebe nada.\"><defs><marker id=\"lb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"10\" width=\"180\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">clientes</text><path d=\"M360 42 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"60\" y=\"70\" width=\"600\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">application load balancer, um só endereço</text><rect x=\"40\" y=\"130\" width=\"310\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"52\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zona a</text><text x=\"52\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sub-rede privada</text><text x=\"144\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10.0.32.0/20</text><rect x=\"370\" y=\"130\" width=\"310\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"382\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zona b</text><text x=\"382\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sub-rede privada</text><text x=\"474\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10.0.48.0/20</text><rect x=\"60\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.32.10</text><text x=\"125\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">saudável</text><path d=\"M125 106 L125 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"205\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.32.11</text><text x=\"270\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">saudável</text><path d=\"M270 106 L270 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"390\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.48.12</text><text x=\"455\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">saudável</text><path d=\"M455 106 L455 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lb-ah)\"></path><rect x=\"535\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.48.13</text><text x=\"600\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">falha em /health</text><text x=\"600\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">não recebe nada</text></svg>", "caption": "Um endereço na frente de quatro alvos em duas zonas. O alvo que falha no health check sai do rodízio; perder uma zona inteira ainda deixaria dois."}
```

## Quanto custa

Um application load balancer é cobrado por hora, mais uma cobrança pela capacidade que usa, que a AWS
mede em unidades próprias e que a tabela não lista. A parte por hora:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|ALB'
                                        sa-east-1    us-east-1
  load balancer (ALB), per hour            0.0340       0.0225
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0340, 2), round(730 * 0.0225, 2))"
24.82 16.43
```

São 24,82 dólares por mês de 730 horas em `sa-east-1` e 16,43 em `us-east-1`, antes de um único
pedido. A aula 10 é onde esses valores mensais fixos são somados, e é por isso que um projeto pessoal
com uma máquina pequena muitas vezes nem tem balanceador de carga.
