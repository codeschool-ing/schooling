---
title: Dois minutos de aviso, e o que fazer com eles
version: 1
---

O medo do spot é que uma instância suma sem aviso. Ela não some, não exatamente. **Quando a AWS
precisa da capacidade de volta, ela dá dois minutos de aviso à instância**, e antes disso pode dar um
sinal mais cedo e mais brando. O que uma instância faz com esses minutos decide se uma interrupção é
um evento que ninguém nota ou um job que tem de recomeçar do início.

Nada do comportamento da AWS nesta seção pôde ser executado: o moto nunca interrompe nada. O que vem
a seguir é a documentação da AWS, e o único script daqui foi executado só no caminho em que nada
acontece.

## Os dois sinais

**O aviso de interrupção** é o firme. Dois minutos antes de a AWS parar, hibernar ou terminar a
instância, duas coisas aparecem ao mesmo tempo:

- o caminho de metadata `/latest/meta-data/spot/instance-action` passa a responder, com um pequeno
  documento JSON indicando a ação e o horário em que ela vai acontecer. Até lá o caminho responde
  404;
- o EventBridge recebe um evento do tipo `EC2 Spot Instance Interruption Warning`, com o id da
  instância e a ação.

**A recomendação de rebalanceamento** é o sinal antecipado. Quando a AWS vê que uma instância corre
risco elevado de interrupção, ela pode avisar antes: o caminho de metadata
`/latest/meta-data/events/recommendations/rebalance` passa a responder, e o EventBridge recebe um
`EC2 Instance Rebalance Recommendation`. É uma dica, não uma promessa. Ela pode chegar bem antes do
aviso, no mesmo instante, ou nunca, e uma instância que recebe uma pode rodar por dias.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma linha do tempo de uma instância spot. Ela é lançada. Em algum momento pode chegar uma recomendação de rebalanceamento, no caminho de metadata events/recommendations/rebalance; ela é opcional e pode vir muito antes do fim ou nunca. Depois chega o aviso de interrupção em spot/instance-action, dois minutos antes de a instância ser parada ou terminada. Os dois minutos são a janela de drenagem.\"><defs><marker id=\"tl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 150 L700 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tl-ah)\"></path><path d=\"M80 140 L80 160\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M300 140 L300 160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M520 140 L520 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M660 140 L660 160\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"80\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">lançada</text><text x=\"300\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">recomendação de rebalanceamento</text><text x=\"300\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pode vir cedo, tarde ou nunca</text><text x=\"520\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">aviso de interrupção</text><text x=\"520\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sempre dois minutos antes</text><text x=\"660\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">tomada de volta</text><rect x=\"520\" y=\"170\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"605\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dois minutos</text><text x=\"605\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">parar o novo, devolver o resto</text><rect x=\"300\" y=\"170\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"400\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tempo para substituí-la com calma</text><text x=\"400\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o capacity rebalancing usa</text><text x=\"300\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">events/recommendations/rebalance</text><text x=\"605\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">spot/instance-action</text><text x=\"700\" y=\"16\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">tempos fora de escala</text></svg>", "caption": "Os dois sinais de uma interrupção spot, como a AWS os documenta. O aviso é garantido e curto; a recomendação é mais cedo e não é garantida, e é por isso que um grupo a usa para lançar uma substituta mas nada espera por ela."}
```

## Escutando na instância

O caminho de metadata é lido da própria instância, então o ouvinte mais simples é um programa
pequeno ao lado da aplicação que pergunta a cada poucos segundos. Aqui está um, em shell puro.
**Copie-o com o botão do bloco e salve como `~/aws/spot-watch.sh`.**

```schooling-example
{"language": "sh", "file": "spot-watch.sh", "parts": [{"code": "#!/bin/sh\n# spot-watch.sh: poll for a spot interruption notice, and drain when one comes\nMD=${MD:-http://169.254.169.254}\nPIDFILE=${PIDFILE:-/run/worker.pid}\n\n", "note": "O endereço do serviço de metadata, que a lição 7 explica, e o arquivo onde o worker grava o id do processo. Os dois podem ser trocados pelo ambiente, e é assim que o mesmo script é apontado para o moto abaixo."}, {"code": "while :; do\n  TOKEN=$(curl -s -X PUT \"$MD/latest/api/token\" \\\n    -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')\n", "note": "Um token de sessão do IMDSv2, pedido com um PUT. O template da lição 4 o exigiu, então um GET sem ele seria recusado; a lição 7 diz por quê."}, {"code": "  CODE=$(curl -s -o /tmp/notice -w '%{http_code}' \\\n    -H \"X-aws-ec2-metadata-token: $TOKEN\" \\\n    \"$MD/latest/meta-data/spot/instance-action\")\n", "note": "O único caminho que importa. Na AWS ele responde 404 até uma interrupção ser marcada, e 200 com um pequeno documento JSON, a ação e o horário, a partir do momento em que é. O corpo vai para um arquivo e só o código de status volta."}, {"code": "  if [ \"$CODE\" = 200 ]; then\n    echo \"notice: $(cat /tmp/notice)\"\n    kill -TERM \"$(cat \"$PIDFILE\")\"\n    exit 0\n  fi\n", "note": "Um aviso, então drenar: mandar SIGTERM ao worker, que um worker bem escrito entende como ordem de terminar o trabalho em mãos e não pegar mais nenhum. Dois minutos são todo o orçamento, então este não é o lugar de começar nada."}, {"code": "  echo \"no notice ($CODE)\"\n  [ -n \"$ONCE\" ] && exit 0\n  sleep 5\ndone\n", "note": "Qualquer outra resposta quer dizer que ainda não há aviso: olhar de novo em cinco segundos, o que deixa quase todos os dois minutos para drenar. ONCE faz o script olhar uma vez só, para testar à mão."}]}
```

Numa instância ele roda como um serviço ao lado do worker. No laboratório não há instância nem
serviço de metadata em `169.254.169.254`, mas o moto responde os caminhos de metadata na própria
porta, então o script pode ser apontado para lá e mandado olhar uma vez:

```
ana@laptop:~/aws$ MD=http://localhost:4567 ONCE=1 sh spot-watch.sh
no notice (500)
```

O script seguiu o ramo de "sem aviso", que é a resposta certa por um motivo um pouco errado. **A AWS
responde 404 quando não há aviso; o moto responde 500**, porque não implementa o caminho do spot. O
script trata qualquer coisa diferente de 200 como "ainda não", então as duas levam ao mesmo ramo, e
essa é uma propriedade que vale manter: um ouvinte que caísse numa resposta inesperada pararia de
ouvir justamente no momento em que importava. O ramo que drena não rodou aqui nem em nenhum outro
lugar deste curso.

## Escutando de fora

Os mesmos dois sinais chegam ao EventBridge, que é o lugar de agir sobre eles para uma frota inteira
em vez de uma instância por vez: uma regra que casa com os dois, com uma fila ou uma função como
alvo. As lições 15 e 21 constroem esses alvos. A regra em si o moto aceita:

```
ana@laptop:~/aws$ aws events put-rule --name spot-warning --event-pattern '{"source": ["aws.ec2"], "detail-type": ["EC2 Spot Instance Interruption Warning", "EC2 Instance Rebalance Recommendation"]}'
{
    "RuleArn": "arn:aws:events:sa-east-1:123456789012:rule/spot-warning"
}
```

Na AWS, um alvo nessa regra receberia um evento por aviso, com o id da instância; ele pode tirar a
instância do load balancer, marcar os jobs dela para nova tentativa, ou registrar a interrupção para
alguém poder contá-las. O moto guarda a regra, e nenhum evento vai casar com ela aqui.

## O que drenar significa

Dois minutos bastam para parar e são curtos demais para terminar algo longo. Drenar é, portanto, uma
lista de coisas a parar de fazer, não uma lista de coisas a concluir:

1. parar de pegar trabalho novo: sair do target group do load balancer, parar de ler da fila;
2. deixar o trabalho em mãos terminar se der tempo, ou registrar o progresso dele se não der;
3. devolver o que não vai conseguir terminar, para outra coisa pegar. Uma fila faz isso sozinha: uma
   mensagem que não é apagada volta a ficar visível depois do visibility timeout, que a lição 21
   explica.

**Uma aplicação que pode ser parada a qualquer momento não precisa de nada disso**, e esse é o
argumento mais forte para escrevê-la assim. Para uma que está num grupo de auto scaling há também a
ajuda do próprio grupo, que a próxima seção configura.
