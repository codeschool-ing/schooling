---
title: Upgrades, uma versão menor por vez, contra o relógio
version: 1
---

Duas crenças sobre upgrades custam dinheiro aos times no EKS. Uma é que um serviço gerenciado se
mantém atualizado sozinho, e a outra que um cluster duas versões atrás pula direto para a atual.
**Nenhuma é verdade. Você inicia todo upgrade, o control plane anda uma versão menor por upgrade, e
cada versão tem uma data depois da qual custa seis vezes mais.**

## O relógio

O Kubernetes lança uma versão menor cerca de três vezes por ano, e o EKS dá suporte a cada uma por um
tempo fixo a partir do dia em que o EKS a lança:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo de uma versão do Kubernetes no EKS. Suporte padrão por 14 meses a 0,10 USD por hora, depois suporte estendido por mais 12 a 0,60 USD por hora no total, e então a AWS atualiza o control plane sozinha. Um cluster com upgrade policy STANDARD é atualizado automaticamente no mês 14.\"><defs><marker id=\"eks-sup-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M40 40 L684 40\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40 34 L40 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"34\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lançamento no EKS</text><path d=\"M376 34 L376 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"376\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mês 14</text><path d=\"M664 34 L664 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"664\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mês 26</text><text x=\"40\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">upgradePolicy EXTENDED, o padrão</text><rect x=\"40\" y=\"82\" width=\"336\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"208\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">suporte padrão</text><text x=\"208\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,10 USD por hora</text><rect x=\"376\" y=\"82\" width=\"288\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"520\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">suporte estendido</text><text x=\"520\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,60 USD por hora no total</text><text x=\"660\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a AWS atualiza</text><text x=\"40\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">upgradePolicy STANDARD</text><rect x=\"40\" y=\"184\" width=\"336\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"208\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">suporte padrão</text><text x=\"208\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0,10 USD por hora</text><text x=\"384\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">atualizado aqui, automaticamente</text></svg>", "caption": "A vida de uma versão menor no EKS. O relógio começa quando o EKS lança a versão, não quando você cria o cluster, então um cluster criado no fim da janela tem pouco tempo sobrando.", "same": ["upgradePolicy STANDARD"]}
```

**O suporte padrão dura 14 meses, e o estendido mais 12.** A tabela de preços imprime os dois
medidores, como publicados em 16 de outubro de 2026: 0,10 USD por hora por cluster, e 0,50 por hora
de suporte estendido. A página de preços da AWS dá um cluster em suporte estendido como 0,60 por hora
no total, que são as duas linhas cobradas juntas. Num mês de 730 horas isso dá 73 USD em suporte
padrão e 438 no estendido, e um ano passado no suporte estendido custa a um cluster
0,50 × 730 × 12 = 4.380 USD a mais do que o upgrade teria custado.

O que acontece no mês 14 é a **upgrade policy** do cluster. A referência da API da AWS dá o padrão
como `EXTENDED`: o cluster escorrega para o suporte estendido e a conta sobe sem nada anunciar.
`STANDARD` faz a AWS atualizar o control plane no fim do suporte padrão. No fim do suporte estendido,
a AWS o atualiza de qualquer jeito.

O moto aceita a configuração e não guarda nada dela, e aceita versões que a AWS deixou de oferecer
há muito tempo:

```
ana@laptop:~/aws$ aws eks create-cluster --name shop-standard --kubernetes-version 1.35 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=$SUBNETS --upgrade-policy supportType=STANDARD --query 'cluster.[version,upgradePolicy]'
[
    "1.35",
    null
]
ana@laptop:~/aws$ aws eks create-cluster --name shop-old --kubernetes-version 1.10 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=$SUBNETS --query 'cluster.[version,status]'
[
    "1.10",
    "ACTIVE"
]
```

Na AWS a segunda chamada é recusada, porque a 1.10 não é uma versão que o EKS oferece; as versões
oferecidas num dado dia, com as datas de suporte, são o que `aws eks describe-cluster-versions`
responde. **A 1.35 e a 1.36 desta lição são exemplos**, escolhidos para deixar os passos legíveis.

## A ordem

O upgrade em si não é algo que o moto mostre. A chamada responde 404, como os add-ons:

```
ana@laptop:~/aws$ aws eks update-cluster-version --name shop --kubernetes-version 1.36

aws: [ERROR]: An error occurred (404) when calling the UpdateClusterVersion operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

Então a sequência abaixo é a documentada pela AWS, e **nada dela foi rodado**. Ela começa lendo e
termina nos nodes:

1. **Leia os upgrade insights.** `aws eks list-insights --cluster-name shop` informa o que o EKS
   encontrou que quebraria na próxima versão, acima de tudo APIs do Kubernetes que as suas cargas
   ainda usam e que a próxima versão remove.
2. **Atualize o control plane em uma versão menor.**
   `aws eks update-cluster-version --name shop --kubernetes-version 1.36` devolve um id de update, e
   a AWS documenta que o cluster continua atendendo enquanto o update roda, em geral por alguns
   minutos.
3. **Atualize os add-ons** para versões publicadas para a 1.36, com `describe-addon-versions` e
   `update-addon` da seção anterior.
4. **Atualize todos os node groups**:
   `aws eks update-nodegroup-version --cluster-name shop --nodegroup-name general`. O EKS lança nodes
   com a imagem nova, drena os antigos, o que move os pods deles, e os termina, `maxUnavailable` por
   vez.

Depois a próxima versão, se houver uma a alcançar, a partir do passo 1 de novo. Um cluster na 1.33
que precisa chegar à 1.36 faz isso três vezes.

Duas regras deixam a ordem rígida. **Um node group precisa estar na versão do cluster antes que o
cluster possa andar de novo**: a referência da API da AWS recusa o próximo upgrade do control plane
enquanto um managed node group ficar para trás. E **nada volta**: nem um control plane nem um node
group retornam a uma versão anterior. É por isso que os insights vêm primeiro, e por isso que um
time que pode pagar atualiza uma cópia do cluster antes do de verdade.

## A drenagem é onde dá errado

O passo 4 move todo pod do cluster pelo menos uma vez, e é aí que um upgrade encontra as cargas. Um
pod é despejado de um node que está sendo substituído e iniciado de novo em outro lugar, então
**tudo o que não sobrevive a um reinício vai perceber**: uma réplica única, um pod que guarda estado
no disco do node, um serviço sem readiness check que recebe tráfego antes de estar pronto.

Um **PodDisruptionBudget** é como uma carga diz quanto dela pode ficar fora ao mesmo tempo, como
"pelo menos duas das minhas três réplicas". A drenagem o respeita, e a AWS documenta que o update de
um managed node group falha em vez de quebrar um, a menos que seja forçado. Um budget que nunca pode
ser cumprido, "pelo menos três das minhas três", bloqueia todo upgrade até alguém perceber, e o
relógio da figura continua correndo enquanto isso.
