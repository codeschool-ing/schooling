---
title: Agindo numa recomendação sem quebrar nada
version: 1
---

**Reduzir ou apagar só é reversível se você planejou para ser.** Uma máquina reduzida à metade do tipo e pequena
demais volta com um comando; uma máquina apagada com o disco não volta. O procedimento da loja é montado para que todo
passo antes do último possa ser desfeito. Nada aqui foi executado: as máquinas são do Compute Engine.

## Reduzindo

O tipo de uma máquina só pode mudar com ela parada:

```sh
gcloud compute instances stop reports --zone=southamerica-east1-a
gcloud compute instances set-machine-type reports --zone=southamerica-east1-a --machine-type=e2-standard-4
gcloud compute instances start reports --zone=southamerica-east1-a
```

Não executado. São alguns minutos fora do ar, então isso é feito nas horas calmas da máquina e anunciado ao dono.
Depois observe-a pelo próximo ciclo completo (uma semana, ou um mês para os relatórios): se o 95º percentil dela agora
passa de 80%, a redução foi um passo longe demais, e os mesmos três comandos voltam atrás.

**O compromisso da lição 21 precisa ser considerado antes.** Um compromisso por recursos de 32 GB de memória não
encolhe quando o `reports` encolhe; a economia da máquina menor só é real para o uso que era pago sob demanda.

## Apagando a máquina ociosa

A `old-migration` passa por quatro passos, com uma semana entre eles, porque cada um dá ao dono a chance de dizer "era
minha":

1. **Achar o dono** pelos rótulos (`team`, dos `default_labels` da lição 5) ou pela entrada do log de auditoria que a
   criou. Uma máquina sem nenhum dos dois é o problema da lição 23, e o motivo de aquela lição existir.
2. **Rotulá-la** com `delete-after=2026-11-20` e avisar o dono, ou o canal do time se não houver dono.
3. **Tirar snapshot do disco, depois pará-la.** Uma máquina parada não custa nada de CPU e memória; o disco continua
   cobrado, e o snapshot custa menos que o disco. Se algo quebrar, iniciar a máquina traz tudo de volta.
4. **Apagá-la** na data, mantendo o snapshot por mais um mês.

O mesmo formato vale para os outros recursos ociosos: um **disco desanexado** ganha snapshot e é apagado; um **endereço
IP reservado** que nada usa é liberado (um endereço reservado e sem uso é cobrado por hora, e liberá-lo é grátis,
embora o mesmo endereço não possa ser garantido de novo).

## Tornando isso um hábito

A loja revisa as recomendações abertas do Recommender na primeira segunda-feira de cada mês, com os donos das
máquinas, em quinze minutos. **Uma recomendação descartada é descartada com um motivo**, escrito no estado dela, para
que a revisão do mês seguinte não discuta a mesma máquina de novo. E a exclusão em quatro passos de máquinas ociosas é
o único lugar em que a loja aceita ser lenta de propósito: o custo de uma semana de atraso são alguns dólares, e o
custo de apagar a única cópia de algo de alguém não se mede em dólares.
