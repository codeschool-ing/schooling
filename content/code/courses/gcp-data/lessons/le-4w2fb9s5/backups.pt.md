---
title: Backups, e a restauração que sobrescreve
version: 1
---

**O Cloud SQL guarda dois tipos de backup, e os dois pertencem à instância.** Os **backups
automáticos** são tirados uma vez por dia, na janela que o `--backup-start-time` define, e o mais
antigo é apagado quando um novo empurra a contagem além da retenção. Os **backups sob demanda** são
tirados quando alguém pede, com `gcloud sql backups create --instance=quitanda-orders`, e ficam até
alguém apagá-los. O primeiro backup guarda o disco inteiro; os seguintes guardam o que mudou desde
então, e a documentação do Google diz que os dados de um backup apagado são incorporados ao seguinte,
então apagar um backup antigo nunca quebra um mais novo.

## Quantos, e por quanto tempo

A referência dá os padrões, no bloco citado na seção anterior: **7 backups automáticos no Enterprise,
15 no Enterprise Plus, qualquer valor de 1 a 365** com `--retained-backups-count`. E o log de
transações para a recuperação a um ponto no tempo tem retenção própria, 7 dias no Enterprise e até 35
no Enterprise Plus. As duas não são a mesma promessa:

| | o que responde | até quando para trás |
|---|---|---|
| recuperação a um ponto no tempo | o banco em qualquer segundo | a retenção do log: 7 dias, ou até 35 |
| um backup automático | o banco no momento daquele backup | a contagem de backups: 7 por padrão |
| um backup sob demanda | o banco antes de uma migração, um lançamento, um fim de ano | até alguém apagá-lo |

**Um backup não é um momento que dá para mover.** Ele guarda o disco numa hora e nada depois dela,
então responde "o banco como estava antes da migração de terça" e a recuperação a um ponto no tempo
responde "o banco como estava às 15:46:55". Tire um backup sob demanda antes de toda migração que muda
dados, e dê a ele um nome para que quem ler a lista no ano que vem saiba para que ele servia.

## Uma restauração sobrescreve a instância para onde vai

**Esta é a diferença em relação ao notebook que custa os dados das pessoas.** A recuperação a um ponto
no tempo, no Cloud SQL como no notebook, cria uma instância nova ao lado da antiga. **Restaurar um
backup não cria**: `gcloud sql backups restore BACKUP_ID --restore-instance=quitanda-orders` substitui
tudo na instância de destino pelo conteúdo do backup, e a documentação do Google diz isso num aviso,
como o `gcloud` diz na confirmação que pede. Todo pedido escrito desde aquele backup some da instância,
a menos que o log possa trazê-lo de volta.

**Então restaure numa outra instância primeiro.** Crie uma vazia, restaure o backup nela com o
`--restore-instance` apontando para a nova, veja o que ela guarda, e só então decida o que copiar ou
para onde apontar a aplicação. A referência acrescenta que restaurar pelo nome do backup, e não pelo
ID, pode criar a instância nova no mesmo comando. Nenhum desses foi executado aqui: não há instância
para onde restaurar.

## Backups e uma instância apagada

```
ana@laptop:~/gcp$ gcloud sql instances create --help | sed -n '/^     --\[no-\]retain-backups-on-delete/,/^$/p'
     --[no-]retain-backups-on-delete
        Retain automated/ondemand backups of the instance after the instance is
        deleted. Use --retain-backups-on-delete to enable and
        --no-retain-backups-on-delete to disable.
```

**Por padrão, apagar uma instância apaga os backups dela junto**, que é o contrário do que alguém que
apagou uma instância por engano precisa. O `--retain-backups-on-delete` os mantém depois que a
instância some, e o `--deletion-protection` da aula 6 recusa a exclusão logo de saída. Para uma cópia
que sobreviva à instância e ao projeto também, o `gcloud sql export sql` escreve um dump num bucket do
Cloud Storage, onde a política de retenção da aula 3 pode trancá-lo pelo tempo que a lei pedir.

## O que custa

Os backups são cobrados pelo que guardam, a 0,12 o GiB-mês em São Paulo. Um banco de 100 GiB cuja
semana de backups diários acrescenta 30 GiB de mudanças guarda cerca de 130 GiB, que é o último número
da linha desta seção:

```
ana@laptop:~/gcp$ python3 -c 'h = 730; print(round((2 * 0.062 + 8 * 0.0105) * h + 100 * 0.255, 2), round((2 * 0.1239 + 8 * 0.021) * h + 100 * 0.51, 2), round(20 * 30 * 0.14, 2), round(130 * 0.12, 2))'
177.34 354.53 84.0 15.6
```

**15,6 por mês para poder voltar uma semana.** Contra os 354,53 de uma instância regional e os 177,34
de uma réplica, é a linha mais barata desta aula, e a única que desfaz um engano. As quatro juntas são a
forma da decisão: um standby para a máquina, uma réplica para as leituras ou para a região, e backups
com o log para a pessoa que digitou `DELETE FROM orders`.
