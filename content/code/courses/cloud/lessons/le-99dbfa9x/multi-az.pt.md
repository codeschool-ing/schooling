---
title: Sobrevivendo à perda de uma zona
version: 1
---

A suposição confortável é que o provedor mantém o seu servidor no ar, então uma máquina na nuvem não
cai. **Uma instância vive em exatamente uma zona**, e quando essa zona tem um dia ruim, a instância
também tem, e também tudo o que só existe ali. O projeto que sobrevive a isso é simples: rodar tudo em
dobro, em duas zonas, para que qualquer uma delas aguente a carga sozinha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um desenho multi-AZ em sa-east-1. Um load balancer no alto manda tráfego para duas instâncias, uma na zona sa-east-1a e outra na sa-east-1b. O banco primário está na zona a e um standby está na zona b. Dois fluxos atravessam a fronteira entre as zonas e são cobrados por gigabyte: a instância da zona b lendo do primário na zona a, e a replicação do primário para o standby.\"><defs><marker id=\"maz-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"20\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">load balancer, nas duas zonas</text><rect x=\"40\" y=\"90\" width=\"300\" height=\"220\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"52\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"380\" y=\"90\" width=\"300\" height=\"220\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"392\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"80\" y=\"124\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instância</text><rect x=\"420\" y=\"124\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">instância</text><path d=\"M300 60 L190 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><path d=\"M420 60 L530 124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><rect x=\"80\" y=\"234\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">banco, primário</text><rect x=\"420\" y=\"234\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"530\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">banco, standby</text><path d=\"M190 164 L190 234\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><path d=\"M460 164 L460 200 L250 200 L250 234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><text x=\"470\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cruza zonas</text><path d=\"M300 262 L420 262\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#maz-ah)\"></path><text x=\"360\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">replicação, cruza zonas</text></svg>", "caption": "A mesma aplicação, duas vezes, em duas zonas. Os dois fluxos que cruzam uma fronteira de zona são os que a linha entre zonas da planilha cobra, na saída e de novo na entrada."}
```

Três peças fazem isso funcionar, e as aulas 4 e 6 construíram duas delas:

- Pelo menos duas instâncias, em duas zonas, cada uma capaz de atender qualquer pedido.
- Um load balancer na frente das duas, presente nas duas zonas. Ele verifica a saúde de cada
  instância e para de mandar tráfego para a que não responde, então uma zona morta sai do rodízio sem
  ninguém mexer em nada.
- Um banco de dados com um standby na segunda zona. O primário recebe as escritas e mantém o standby
  atualizado; se a zona do primário cai, o standby é promovido e a aplicação se reconecta a ele.

Bancos gerenciados oferecem a terceira peça como uma configuração só, em geral chamada de multi-AZ. Ela
faz a mesma coisa ativada num clique ou construída à mão: uma segunda cópia, num segundo prédio,
mantida em dia.

## Quanto custa

**O primeiro custo é a segunda cópia de tudo.** Duas instâncias `t3.medium` na `sa-east-1`, a 0,06720
por hora cada, dão 2 × 0,06720 × 720 = 96,77 dólares num mês de 30 dias, onde uma daria 48,38. O
standby é um segundo servidor de banco inteiro, que não atende nenhuma consulta num dia normal. Dobrar
é o preço do projeto, e ele é pago toda hora, caia uma zona ou não.

**O segundo custo é o tráfego entre as zonas**, e é o que as pessoas esquecem. A planilha tem uma
linha para ele:

```
ana@laptop:~/cloud$ python3 prices.py transfer
AWS public price list, USD, excluding tax
  offer AmazonEC2        version 20260925174521
  offer AWSLambda        version 20260919002359
  offer AmazonS3         version 20260926015512
  offer AWSDataTransfer  version 20260916132208
  offer AmazonEFS        version 20260911124425
  offer AmazonVPC        version 20260917190528
                                        sa-east-1    us-east-1

Data transfer, USD per GB
  out to the internet, first 10 TB         0.1500       0.0900
  out to the internet, next 40 TB          0.1380       0.0850
  out to the internet, next 100 TB         0.1260       0.0700
  out to the internet, over 150 TB         0.1140       0.0500
  between zones, each direction            0.0100       0.0100
  to the other region                      0.1380       0.0200
  in from the internet                     0.0000       0.0000
```

"Each direction", em cada sentido, é a parte para ler devagar. **Um gigabyte que passa de uma zona
para outra é cobrado 0,0100 ao sair e 0,0100 ao chegar**, então custa 0,0200 no total. É igual nas duas
regiões da planilha.

Olhe a figura de novo. A instância da `sa-east-1b` lê do banco primário na `sa-east-1a`, então tudo o
que ela lê cruza uma zona. Suponha que essa instância puxe 1.500 GB de resultados de consulta num mês:
1.500 × 0,0200 = 30,00 dólares. Ninguém comprou isso de propósito; é a conta por pôr a aplicação em
duas zonas e o primário do banco numa delas. É também o preço de o projeto funcionar como deveria,
então a resposta habitual é mantê-lo e saber que ele está ali, em vez de voltar tudo para uma zona
só para economizá-lo.

::: track dba
**O standby é onde um administrador de banco de dados paga o multi-AZ duas vezes.** Com replicação
síncrona, um commit no primário só é confirmado quando o standby tem a mudança, então todo commit
espera uma ida e volta entre zonas: curta, porque as zonas ficam a menos de 100 km, e ainda assim mais
longa que um commit que não esperou ninguém. Meça isso na sua própria carga antes de prometer uma
latência. E a própria mudança cruza zonas. Um banco que escreve 10 GB de log por dia manda uns 300 GB
por mês para o standby; replicados entre duas instâncias que você mesmo roda, isso dá
300 × 0,0200 = 6,00 dólares por mês na linha acima. Um banco gerenciado precifica a própria replicação
na sua própria página de preços, que esta planilha não traz, então leia essa página antes de supor
qualquer uma das respostas.
:::

::: track *
**O standby de um banco gerenciado tem preço na página daquele serviço**, que esta planilha não traz.
A linha entre zonas acima vale para o tráfego entre instâncias que você mesmo roda, inclusive uma
réplica montada em duas delas, então leia a página de preços do banco antes de supor qualquer uma das
respostas.
:::

## Uma zona não é uma região

**Duas zonas sobrevivem à perda de uma zona. Elas não fazem nada contra a perda de uma região.** As
duas zonas ficam sob os mesmos sistemas de controle regionais, compartilham os mesmos serviços
regionais e são alcançadas pelos mesmos pontos de entrada da região. Um problema nesse nível alcança
todas as zonas de uma vez, e um projeto multi-AZ cai junto, mesmo configurado corretamente.

Isso não é motivo para pular o multi-AZ. A falha de uma zona é a que você consegue eliminar no projeto
a baixo custo, dentro de uma região, com as ferramentas da aula 6. A falha de uma região é um evento
de outra escala, com um custo de outra escala, e a próxima seção trata de decidir se vale pagá-lo.
