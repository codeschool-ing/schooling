---
title: Uma escolha resolvida, do perfil à decisão
version: 1
---

As peças desta lição só se pagam quando decidem alguma coisa, então aqui vai uma decisão tomada do
começo ao fim. **O caso é inventado, as tarifas são ilustrativas e os totais são um exemplo**; o
método é a parte para guardar.

## O caso

A loja em São Paulo roda a API de pedidos numa máquina virtual em `brazilsouth`, como faz há três
anos. Três desenvolvedores cuidam dela, e as lições 7, 8, 11 e 18 já rodaram a imagem dela de quatro
jeitos. Mais duas coisas vivem na mesma máquina. Um cron gera o **relatório de vendas** toda noite
às 23:30, o que leva uns seis minutos. E o time financeiro pede a **exportação financeira** numa
página interna algumas vezes por dia: os pedidos de um dia voltam em uns 20 segundos, e os de um mês
inteiro, quando o financeiro fecha o mês, levam até cinco minutos enquanto a página espera.

As contagens de requisições no log do servidor web, na semana mais cheia, dão um perfil: um fio de 2
por segundo durante a noite, uma subida a partir das 07:00, um ombro no almoço e um pico à noite de
80 por segundo das 18:00 às 20:00.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"O perfil de requisições da loja em 24 barras: 2 requisições por segundo da meia-noite às 07:00, subindo a 40 no almoço, caindo a 20 à tarde e chegando ao pico de 80 das 18:00 às 20:00, antes de voltar a 2 às 23:00. Duas linhas tracejadas o cruzam: em 50 por segundo, o que uma réplica do Container Apps aguenta, que só as quatro horas da noite entre 17:00 e 21:00 ultrapassam; e a média da loja, 26,5 por segundo.\"><rect x=\"81.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"106.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"131.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"156.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"181.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"206.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"231.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><rect x=\"256.0\" y=\"205.0\" width=\"23.0\" height=\"25.0\" fill=\"var(--phosphor)\"></rect><rect x=\"281.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"306.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"331.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"356.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"381.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"406.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"431.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"456.0\" y=\"155.0\" width=\"23.0\" height=\"75.0\" fill=\"var(--phosphor)\"></rect><rect x=\"481.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"506.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"531.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"556.0\" y=\"30.0\" width=\"23.0\" height=\"200.0\" fill=\"var(--phosphor)\"></rect><rect x=\"581.0\" y=\"80.0\" width=\"23.0\" height=\"150.0\" fill=\"var(--phosphor)\"></rect><rect x=\"606.0\" y=\"130.0\" width=\"23.0\" height=\"100.0\" fill=\"var(--phosphor)\"></rect><rect x=\"631.0\" y=\"180.0\" width=\"23.0\" height=\"50.0\" fill=\"var(--phosphor)\"></rect><rect x=\"656.0\" y=\"225.0\" width=\"23.0\" height=\"5.0\" fill=\"var(--phosphor)\"></rect><path d=\"M80 230 L680 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80 30 L80 230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">80</text><path d=\"M80 105.0 L680 105.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"97.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o que uma réplica aguenta, 50 por segundo</text><path d=\"M80 163.8 L680 163.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"88\" y=\"175.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a média da loja, 26,5 por segundo</text><text x=\"80.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"230.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"380.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"530.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"380.0\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requisições por segundo, hora a hora</text><text x=\"555.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pico de 80, das 18:00 às 20:00</text><text x=\"167.5\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um fio de 2</text></svg>", "caption": "Só quatro horas do dia precisam de uma segunda réplica, e o mínimo de duas já as cobre. O fio de tráfego mantém as duas réplicas fora da tarifa ociosa a noite toda."}
```

## A conta

O perfil entra no `compare.py` como argumento, as 24 taxas a partir da meia-noite:

```
ana@laptop:~/azure$ python3 compare.py shop=2,2,2,2,2,2,2,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,2
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
shop         69.64M         146.00          85.81         219.00        3649.24         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

O Container Apps é o mais barato, 85,81 USD por mês, contra 146,00 das duas máquinas virtuais, e
**o pico cabe dentro do mínimo**: 80 por segundo pedem duas réplicas de 50, e duas é o mínimo que o
programa mantém de qualquer jeito. A figura mostra: só quatro horas do dia passam do que uma réplica
aguenta. O Functions custa 3.649,24, porque 69,64 milhões de requisições por mês são 25 vezes o ponto
de equilíbrio da última linha, e a média da loja, 26,5 por segundo, é 25 vezes os 1,06 dele.

O fio de tráfego custa alguma coisa, e o mesmo perfil com noites em silêncio mostra quanto:

```
ana@laptop:~/azure$ python3 compare.py shop=0,0,0,0,0,0,0,10,20,30,40,40,30,20,20,30,40,60,80,80,60,40,20,0
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
shop         67.89M         146.00          69.34         219.00        3557.44         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

16,47 USD por mês separam os dois números do Container Apps, tudo isso réplicas cobradas na tarifa
ativa durante oito horas em que poderiam estar ociosas. Aqui não muda nada. Ainda assim é o reflexo
certo: antes de contar com a tarifa ociosa ou com o zero, descubra se as horas quietas são quietas
mesmo. As da loja não são, e o fio acaba sendo um monitor de disponibilidade e o app do celular
consultando o status dos pedidos.

## As restrições

O preço diz Container Apps, com uma margem de que nenhuma outra coluna chega perto. A lista da seção
04 confirma isso ou derruba:

- **a exportação do mês leva cinco minutos**, e o ingress do Container Apps dá 240 segundos a uma
  requisição. Ela não pode continuar sendo uma página que espera. Vira um job: a página põe uma
  mensagem numa fila do Service Bus (lição 20), um job do Container Apps disparado por eventos
  (lição 8) gera o arquivo, e o financeiro o busca quando ficar pronto. A mesma mudança seria
  imposta no Functions ou no App Service, onde o limite é de 230 segundos; só uma máquina virtual a
  deixaria como está;
- **o relatório leva seis minutos**, o que cabe em tudo, inclusive no timeout padrão de 30 minutos
  do Flex Consumption. Como job agendado do Container Apps, com 1 vCPU e 1 GiB como o grupo da lição
  7, ele roda 360 segundos × 30,42 noites: 10.950 vCPU-segundos e outros tantos GiB-segundos por mês.
  A API já gastou as cotas gratuitas, então isso dá uns 0,24 USD nas tarifas ativas do arquivo. A lição 8 mostrou
  que o agendamento é lido em UTC, então 23:30 é `30 2 * * *`;
- **os pedidos vivem na memória**, e a seção 04 mostrou o que duas cópias fazem com eles. Vão para um
  banco de dados qualquer que seja a coluna vencedora, já que toda opção da tabela roda dois de
  alguma coisa;
- **os arquivos do relatório vivem no disco da máquina**, e vão para um compartilhamento do Azure
  Files como a lição 7 o montou. Uma semana de trabalho, qualquer que seja a coluna vencedora;
- a equipe conhece contêineres e nunca rodou uma função em produção, o que as lições 15 a 17 mostram
  ser uma habilidade à parte.

## A decisão

**A API vai para o Container Apps com mínimo de duas réplicas; o relatório roda lá como job
agendado, e a exportação como job disparado por eventos, no ambiente interno que a lição 8 deu a
ela.** É a opção mais barata e a mudança mais barata: a imagem existe, a mudança de código é a que
toda opção pede, e não há um jeito novo de empacotar para aprender. As máquinas virtuais custariam
60,19 USD por mês a mais e devolveriam o sistema operacional. O Functions custaria milhares a mais e
uma reescrita em handlers. O mínimo de duas compra disponibilidade e também quer dizer nenhuma
partida a frio para o cliente que pede às 03:00.

**Uma decisão assim só está terminada quando nomeia o que a reabriria.** O primeiro gatilho é o
crescimento, e o programa sabe dizer onde ele aperta. Aqui está o perfil da loja com três vezes o
tráfego de hoje:

```
ana@laptop:~/azure$ python3 compare.py shop3=6,6,6,6,6,6,6,30,60,90,120,120,90,60,60,90,120,180,240,240,180,120,60,6
profile    requests        two VMs Container Apps    App Service Functions Flex            AKS
shop3       208.93M         146.00         159.92         219.00       10947.72         511.00

Functions costs what two VMs cost at 2.79M requests a month, 1.06 a second on average.
USD a month, at the rates in rates.json: illustrative, not Azure's prices.
```

159,92 contra 146,00: nesse tamanho as máquinas virtuais e o Container Apps trocam de lugar, e duas
máquinas, ou um scale set (lição 4) com reservas, merecem um preço feito direito. Então três coisas a
reabririam:

- **tráfego perto de três vezes o de hoje**, que as contagens de requisições por hora mostram muito
  antes de ele chegar;
- **tarifas reais.** Esta decisão foi tomada com tarifas ilustrativas. Ponha as reais no
  `rates.json` e rode os mesmos comandos. Hoje o Container Apps custa 41% menos que a próxima coluna;
  se a diferença cair abaixo de 20%, o preço é empate, e o esforço da seção 04 decide, e ele continua
  ganhando;
- **um segundo app na assinatura**, que gasta as cotas gratuitas com que esta tabela contou.

Nenhuma delas está perto hoje, e as três são baratas de acompanhar. A lição 22 é sobre escrever isto
de um jeito que alguém encontre daqui a dois anos, com o lock-in que a decisão aceita ao lado.
