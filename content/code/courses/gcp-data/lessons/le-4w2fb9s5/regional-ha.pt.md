---
title: Alta disponibilidade, um standby que você não lê
version: 1
---

**Uma instância regional do Cloud SQL são duas máquinas em duas zonas, e você só vê uma delas.** O
primário recebe toda leitura e toda escrita. O standby, em outra zona da mesma região, tem um disco
próprio que recebe toda escrita de forma síncrona: uma escrita só é confirmada quando está nos dois
discos. Se o primário ou a zona dele falha, o Cloud SQL inicia o motor no standby, sobre a cópia dos
dados que ele já tem, e move o endereço da instância para ele. A aplicação reconecta ao mesmo endereço
e encontra os mesmos dados.

**A ideia errada é que alta disponibilidade serve para escala.** Não serve: o standby não aceita
conexões, então um banco lento numa instância zonal é exatamente tão lento numa regional, e um pouco
mais lento para confirmar, porque toda escrita agora espera uma segunda zona responder. Ela serve para
o dia em que uma zona fica sem energia, uma máquina falha, ou o primário para de responder às
verificações de saúde. O Google documenta que o failover é automático nesses casos e que costuma levar
cerca de um minuto, durante o qual conexões são recusadas. Esse tempo é do Google, não deste
laboratório; nada no notebook faz failover.

## O que é um failover, em ordem

Como a documentação do Google sobre alta disponibilidade o descreve:

1. **O Cloud SQL percebe que o primário sumiu.** Cada instância manda um sinal de vida, e um primário
   que deixa de mandá-lo por tempo suficiente é declarado em falha.
2. **O standby vira o primário.** O disco dele já tem toda escrita confirmada, então nada confirmado se
   perde; transações que estavam abertas quando o primário morreu são desfeitas pelo motor quando ele
   inicia, como depois de qualquer queda.
3. **O endereço muda de lugar.** A instância mantém o endereço privado e o nome de conexão; o que
   responde neles agora é a máquina na outra zona.
4. **Um standby novo é construído** numa zona da região, e a instância volta a ter alta
   disponibilidade quando ele fica pronto.

**O endereço não muda. O que está atrás dele muda.** Então o trabalho do lado da aplicação é
reconectar: toda conexão aberta cai, e um cliente precisa abrir conexões novas. Um driver que tenta de
novo está bem. Um pool de conexões que distribui conexões mortas até ser reiniciado é o jeito comum de
um failover de um minuto virar uma queda de uma hora, e vale testar isso antes do dia em que importar.

**O teste é um comando.** `gcloud sql instances failover quitanda-orders` faz uma instância regional
fazer failover de propósito, o que a referência da linha de comando descreve numa linha, "Causes a
high-availability Cloud SQL instance to failover." Rodado numa tarde calma com a aplicação sendo
observada, ele responde à pergunta que importa: o que a aplicação faz quando o banco some por um
minuto. Ele não foi executado aqui.

## Ligando

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --availability-type=/,/This is the default/p'
     --availability-type=AVAILABILITY_TYPE
        Specifies level of availability. AVAILABILITY_TYPE must be one of:

         regional
            Provides high availability and is recommended for production
            instances; instance automatically fails over to another zone within
            your selected region.
         zonal
            Provides no failover capability. This is the default.
```

**`zonal` é o padrão**, então uma instância só tem alta disponibilidade quando alguém pediu. O comando
da aula 6 com `--availability-type=regional` cria uma, e `--secondary-zone` escolhe a zona do standby
quando a escolha padrão não serve. Uma instância zonal existente pode virar regional com
`gcloud sql instances patch quitanda-orders --availability-type=regional`, e a documentação diz que
essa mudança reinicia a instância. Nenhum desses foi executado aqui.

## O que custa, e o que não cobre

**É a instância da aula 6 duas vezes**, a máquina e o disco, porque há dois de cada:

```
ana@laptop:~/gcp$ python3 -c 'h = 730; print(round((2 * 0.062 + 8 * 0.0105) * h + 100 * 0.255, 2), round((2 * 0.1239 + 8 * 0.021) * h + 100 * 0.51, 2), round(20 * 30 * 0.14, 2), round(130 * 0.12, 2))'
177.34 354.53 84.0 15.6
```

**177,34 pela instância zonal, 354,53 pela regional**, com os preços da última seção da aula 6. Os
outros dois números da linha são para as seções depois desta.

**Alta disponibilidade protege contra uma máquina ou uma zona.** Não protege contra um engano: um
`DELETE` sem `WHERE` é escrito nos dois discos, de forma síncrona, antes de o commit voltar, e o
standby o guarda tão fielmente quanto o primário. Também não protege contra a perda de uma região
inteira, já que as duas zonas estão nela. O primeiro caso é para os backups e a recuperação a um ponto
no tempo, duas seções adiante; o segundo é uma réplica em outra região, que a próxima seção alcança.
