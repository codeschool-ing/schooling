---
title: Nós, armazenamento e a conta
version: 1
---

**O Bigtable é cobrado por capacidade, não por requisição.** O Firestore da aula 10 cobra por
documento lido e escrito; o Bigtable cobra pelos nós que existem a cada hora, leia alguém deles ou
não. Por cima vêm o armazenamento que as tabelas ocupam e a rede que usam. Uma tabela que ninguém consulta o
fim de semana inteiro custa exatamente o que custou na sexta à noite. Isso muda a pergunta que a conta
faz: não "quantas leituras", mas "de quantos nós a hora mais movimentada precisa, e por quantos as
outras horas pagam".

## Instância, cluster, nó

**Uma instância é um contêiner de clusters, um cluster mora numa zona, e um cluster é um número de
nós.** As tabelas pertencem à instância, e cada cluster da instância guarda uma cópia completa delas.
Um nó é a unidade de capacidade de atendimento. Ele não guarda dado e serve tablets a partir do
Colossus, então acrescentar um muda a velocidade do cluster, não quanto ele consegue guardar; a
documentação fixa um limite de armazenamento por nó para cada tipo de armazenamento. Um segundo
cluster em outra zona de `southamerica-east1` é como uma instância sobrevive à queda de uma zona, e o
Bigtable replica as tabelas entre os clusters por conta própria. A replicação entre clusters é
eventualmente consistente; um **perfil de app** (app profile) diz se as requisições de uma aplicação
vão para um cluster só, para leituras que enxergam as próprias escritas, ou para o mais próximo
disponível.

Nada disso existe no emulador, que tem uma instância cujo nome ele não conhece:

```
ana@laptop:~/gcp$ cbt listinstances
2026/10/30 15:12:02 Getting list of instances: rpc error: code = Unimplemented desc = unimplemented feature
ana@laptop:~/gcp$ cbt createinstance quitanda-prod 'Quitanda prod' quitanda-c1 southamerica-east1-a 3 SSD
2026/10/30 15:12:02 Creating instance: rpc error: code = Unimplemented desc = unimplemented feature
```

**`Unimplemented` é o emulador dizendo que não tem plano de controle.** Ele atende a API de dados e a
metade de tabelas da API de administração, que é tudo o que as seções anteriores usaram, e nada sobre
instâncias, clusters, nós, perfis de app, backups ou autoscaling. Criar a instância no Google Cloud é
um comando, mostrado aqui e não executado, já que nada neste curso chega ao Google:

```sh
gcloud bigtable instances create quitanda --display-name="Quitanda" \
  --cluster-config=id=quitanda-c1,zone=southamerica-east1-a,nodes=3 \
  --cluster-storage-type=SSD
```

**O tipo de armazenamento é escolhido junto com o cluster e não pode ser trocado.** SSD é o padrão e o
que o Google recomenda para quase tudo. HDD é mais barato por gibibyte e muito mais lento para ler uma
linha ao acaso, e a documentação o reserva para tabelas de pelo menos dez terabytes lidas sobretudo em
scans longos. Passar de um para o outro significa um cluster novo e uma cópia.

## O preço, lido em 2026-10-30

De cloud.google.com/bigtable/pricing, São Paulo, `southamerica-east1`, em USD:

| item | preço |
|---|---|
| nó, edição Enterprise | US$ 0,98 por nó-hora |
| nó, edição Enterprise Plus | US$ 1,3497 por nó-hora |
| nó, Enterprise, compromisso de 1 ano | US$ 0,784 por nó-hora |
| nó, Enterprise, compromisso de 3 anos | US$ 0,588 por nó-hora |
| armazenamento SSD | US$ 0,26 por GiB-mês |
| armazenamento HDD | US$ 0,039 por GiB-mês |
| armazenamento Infrequent Access | US$ 0,039 por GiB-mês |
| Data Boost | US$ 1,274 por 1.000 SPU-horas |

**A página agora nomeia duas edições, Enterprise e Enterprise Plus**, e diz que a edição decide qual
preço de nó vale; ela associa um multiplicador de capacidade em memória aos nós Enterprise Plus, e
manda o leitor a uma página sobre edições para o resto, que esta aula não conseguiu ler. Então esta
aula põe preço em nós Enterprise e não diz sobre a diferença mais do que a página de preços diz. **Um
nó é cobrado pelo maior número que existiu em cada hora, com mínimo de uma hora por nó
provisionado**, e, nas palavras da página, independentemente do uso do nó. A aritmética para o fluxo
de cliques da Quitanda:

```
ana@laptop:~/gcp$ python3 -c 'node = 0.98 * 730; print(round(node, 2), round(3 * node, 2), round(6 * node, 2))'
715.4 2146.2 4292.4
ana@laptop:~/gcp$ python3 -c 'print(round(3 * 0.784 * 730, 2), round(3 * 0.588 * 730, 2))'
1716.96 1287.72
ana@laptop:~/gcp$ python3 -c 'print(2048 * 0.26, round(2048 * 0.039, 2), 8 * 90, round(8 * 90 * 0.26, 2))'
532.48 79.87 720 187.2
```

**Um nó por um mês sai 715,40 dólares**, a 730 horas, que é o valor mensal que a própria página
mostra. Três nós são 2.146,20 dólares, e um segundo cluster de três em outra zona dobra para
4.292,40, sem cobrança pela replicação em si, porque a página não cobra nada pela replicação entre
clusters de uma mesma região. Um compromisso de um ano leva três nós a 1.716,96, e de três anos a
1.287,72. **O armazenamento é a linha pequena, a não ser que o tipo esteja errado**: dois tebibytes em
SSD são 532,48 dólares por mês e em HDD 79,87, e as linhas de nó superam as duas.

**A política de coleta de lixo é um preço.** Com uma estimativa de 8 GiB de cliques por dia, guardar
noventa dias são 720 GiB, 187,20 dólares por mês em SSD. É uma estimativa por cima, já que o
Bigtable comprime o que guarda e a página cobra o tamanho comprimido. O argumento vale qualquer que
seja a taxa: `maxage=90d` na família `ev` é a decisão de retenção e a conta de armazenamento ao mesmo
tempo, e uma família sem política cresce para sempre.

## Autoscaling, e os nós de que a hora movimentada precisa

**O autoscaling do Bigtable é uma configuração do cluster**: um número mínimo e um máximo de nós e uma
meta de utilização de CPU, e opcionalmente uma meta de utilização de armazenamento. O Bigtable
acrescenta nós quando o cluster passa da meta e os remove quando fica bem abaixo, por conta própria.
Não executado aqui:

```sh
gcloud bigtable clusters update quitanda-c1 --instance=quitanda \
  --autoscaling-min-nodes=1 --autoscaling-max-nodes=6 --autoscaling-cpu-target=60
```

**Um nó novo não é capacidade instantânea.** O Bigtable precisa mover tablets para ele antes que ele
ajude, e a documentação avisa que sob carga isso leva minutos, até uns vinte, antes de o cluster
mostrar o benefício. Então o autoscaling acompanha uma carga que muda ao longo de horas, o pico da
noite que cresce a partir das 17:00, e chega atrasado para uma promoção que começa às 18:00 em ponto.
Para isso, o mínimo do cluster é aumentado antes do evento e reduzido depois, por uma tarefa agendada.
E como os nós são cobrados por hora, um cluster que sobe às 18:05 e desce às 18:50 paga a hora inteira
dos dois nós.

**Nenhuma configuração salva uma chave quente.** Mais nós servem mais tablets, e uma chave com o
horário na frente manda toda escrita para um tablet, então o cluster sobe até o máximo e a taxa de
escrita fica onde estava. O autoscaling multiplica uma chave bem espalhada e não faz nada por uma mal
espalhada.

**O Data Boost é o outro jeito de pagar**, para leituras que não são da aplicação. Uma exportação, um
job do Dataflow ou uma consulta do BigQuery sobre a tabela podem rodar em computação serverless
cobrada por SPU-segundo, com mínimo de 60 SPU-segundos por requisição, em vez de nos nós de que o app
depende. Uma SPU é cerca de um milésimo de um nó, então o Data Boost serve a um job noturno e não sai
mais barato para atender tráfego o dia inteiro. A página também lista o **armazenamento Infrequent
Access** pelo preço do HDD, um nível para onde uma tabela SSD pode mover dados antigos, e cobra US$
0,0318 por GiB movido para ele. Os dois são citados aqui para que a linha numa fatura não seja nova;
este curso não usa nenhum deles.
