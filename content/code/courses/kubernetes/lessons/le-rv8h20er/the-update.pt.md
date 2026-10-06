---
title: Uma atualização que derruba requisições
version: 1
---

A versão 1.1 da loja está pronta. **Numa máquina só, trocar um container que está rodando significa
pará-lo primeiro**, porque o novo precisa do mesmo nome e da mesma porta, e o intervalo entre os dois
é algo em que um cliente pode esbarrar. Esta seção mede esse intervalo em vez de afirmá-lo.

A medição é um pequeno script que pergunta à loja 300 vezes, com vinte milissegundos entre uma e
outra, e anota só o código de status de cada resposta:

```sh
#!/bin/sh
# Ask the shop 300 times, 20 ms apart, and print each answer's status code.
# 000 means curl got no answer at all.
for i in $(seq 300); do
  curl -s -o /dev/null -m 1 -w '%{http_code}\n' localhost:8080
  sleep 0.02
done
```

A Ana troca a imagem no `compose.yaml`, inicia a sonda em segundo plano e roda
`docker compose up -d` enquanto ela ainda está perguntando:

```
ana@laptop:~/shop$ sed -i "s/shop:1.0/shop:1.1/" compose.yaml
ana@laptop:~/shop$ ./probe.sh > codes.txt & docker compose up -d; wait
 Container shop-web-1 Recreate 
 Container shop-web-1 Recreated 
 Container shop-web-1 Starting 
 Container shop-web-1 Started 
ana@laptop:~/shop$ sort codes.txt | uniq -c
     12 000
    288 200
```

**Doze das 300 requisições não tiveram resposta nenhuma**, quatro em cada cem. O `000` é o jeito do
curl dizer que a conexão foi recusada: naquele momento nada escutava na porta 8080, porque o Compose
tinha parado o container 1.0 (`Recreate`) e o 1.1 ainda não atendia.

```
ana@laptop:~/shop$ curl -s localhost:8080
shop 1.1 on cdb0f6d432ff
```

A resposta nova traz um hostname novo, `cdb0f6d432ff` em vez de `7f1b64994482`: é outro container,
não o antigo atualizado no lugar. Um container nunca é alterado, só substituído, e a substituição é
de onde vem o intervalo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas do tempo de uma atualização. Em cima, o que o Compose fez: o container 1.0 atende, é parado, há um intervalo em que nada escuta e 12 de 300 requisições ficaram sem resposta, depois o 1.1 atende. Embaixo, a ordem que um orquestrador usa: o 1.1 sobe e fica pronto enquanto o 1.0 ainda atende, o tráfego muda, e só então o 1.0 para, sem intervalo.\"><defs><marker id=\"gap-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"gap-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">docker compose up -d</text><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para, depois sobe</text><rect x=\"180\" y=\"22\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.0</text><rect x=\"400\" y=\"22\" width=\"70\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"435.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">nada escuta</text><rect x=\"470\" y=\"22\" width=\"230\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.1</text><text x=\"435\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">12 de 300 recusadas</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma atualização gradual</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sobe, espera, depois para</text><rect x=\"180\" y=\"112\" width=\"290\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.0</text><rect x=\"380\" y=\"152\" width=\"320\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop 1.1</text><path d=\"M430 185 L430 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"430\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">pronto</text><text x=\"500\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">parado</text><path d=\"M180 222 L700 222\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gap-ah-wire)\"></path></svg>", "caption": "O intervalo vem da ordem: o Compose para o container antigo antes de o novo atender. Inverter a ordem exige duas cópias ao mesmo tempo e algo que mude o tráfego entre elas."}
```

## Por que o Compose não consegue fechar o intervalo aqui

Para atualizar sem intervalo, a ordem tem de ser a inversa: **subir a cópia nova, esperar até ela
responder, mandar o tráfego para ela e só então parar a antiga.** Isso exige três coisas que esta
montagem não tem:

- duas cópias ao mesmo tempo, o que a seção anterior mostrou ser impossível numa porta publicada;
- algo na frente das cópias que decida qual delas recebe cada requisição;
- um sinal de que a cópia nova está pronta, e não apenas iniciada, para o tráfego não ir para um
  processo que ainda está carregando.

Cada uma pode ser montada à mão numa máquina, e o modo Swarm do próprio Docker oferece as três em
várias; a lição 3 vê onde ele se encaixa. O Kubernetes faz as três como comportamento normal, e a
lição 35 roda esta mesma sonda contra uma atualização gradual para ver no que o número se torna.

Doze requisições perdidas parece pouco, e numa tarde tranquila é. São doze por atualização, a cada
atualização, e é um número que ninguém vê a menos que alguém meça.
