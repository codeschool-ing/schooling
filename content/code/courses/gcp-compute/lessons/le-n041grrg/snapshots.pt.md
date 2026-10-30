---
title: Snapshots, e o agendamento que os tira
version: 1
---

Um snapshot é uma cópia de um disco num momento, guardada longe do disco. **O primeiro snapshot de
um disco copia o que está em uso; cada um depois copia só os blocos que mudaram desde o anterior.** É
isso que torna acessível um snapshot por noite, e é o motivo de apagar um snapshot antigo nunca
quebrar um mais novo: o Compute Engine move o que o mais novo ainda precisa.

## Quanto custam

Snapshots são cobrados pelo que guardam, comprimido, e a tabela dá o preço dos dois tipos:

```
ana@laptop:~/gcp$ python3 prices.py disks | grep snapshot
  standard snapshot                                     0.05  per GiB-month
  archive snapshot                                     0.019  per GiB-month
```

Pegue o disco `orders-data` da seção 02: 100 GiB com 40 GiB em uso, e cerca de 1 GiB mudando por
dia. Catorze snapshots noturnos guardam no máximo 40 GiB mais 13 dias de mudanças, 53 GiB, e isso dá
**menos de 2,70 dólares por mês** a 0,05, antes de a compressão diminuir ainda mais. O disco em si
custa 10. Uma equipe que dispensa snapshots para economizar está economizando muito pouco.

Snapshots de **arquivamento** custam menos para guardar e são feitos para cópias mantidas por meses:
são cobrados por pelo menos 90 dias e cobram para serem lidos de volta, o que serve para uma cópia
anual guardada para auditoria e não serve para o snapshot que você restaura numa terça-feira ruim.

## Um agendamento, não um hábito

Um snapshot que ninguém lembra de tirar não existe. Um **agendamento de snapshots** é uma política de
recurso ligada ao disco, e o Compute Engine tira e apaga snapshots por ela. Na mesma pasta da seção
02, acrescente este arquivo ao lado do `main.tf`:

```hcl
# disks/schedule.tf
resource "google_compute_resource_policy" "nightly" {
  name   = "nightly"
  region = "southamerica-east1"

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }

    retention_policy {
      max_retention_days    = 14
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }

    snapshot_properties {
      storage_locations = ["southamerica-east1"]
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "orders_nightly" {
  name = google_compute_resource_policy.nightly.name
  disk = google_compute_disk.orders_data.name
  zone = "southamerica-east1-a"
}
```

```
ana@laptop:~/gcp/disks$ terraform plan -no-color | grep -E '^  #|start_time|max_retention_days|on_source_disk_delete|^Plan'
  # google_compute_disk.orders_data will be created
  # google_compute_disk_resource_policy_attachment.orders_nightly will be created
  # google_compute_instance.orders will be created
  # google_compute_region_disk.orders_ha will be created
  # google_compute_resource_policy.nightly will be created
              + max_retention_days    = 14
              + on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
                  + start_time    = "04:00"
Plan: 5 to add, 0 to change, 0 to destroy.
```

Três escolhas nesse arquivo merecem uma frase cada. **`start_time` é em UTC**, então 04:00 é uma da
manhã em São Paulo. **`max_retention_days`** é o que mantém a conta no número acima, em vez de crescer
toda noite. E **`KEEP_AUTO_SNAPSHOTS`** quer dizer que apagar o disco mantém os snapshots dele, que é
justamente o motivo de tê-los: o dia em que alguém apaga o disco errado é o dia em que eles fazem
falta.

O provider verifica aqui uma coisa que não verificava nos tipos de máquina: o valor de
`on_source_disk_delete` precisa ser uma de duas palavras. Erre a grafia e o plan para:

```
ana@laptop:~/gcp/disks$ sed -i 's/KEEP_AUTO_SNAPSHOTS/KEEP_SNAPSHOTS/' schedule.tf
ana@laptop:~/gcp/disks$ terraform plan -no-color

Error: expected snapshot_schedule_policy.0.retention_policy.0.on_source_disk_delete to be one of ["KEEP_AUTO_SNAPSHOTS" "APPLY_RETENTION_POLICY" ""], got KEEP_SNAPSHOTS

  with google_compute_resource_policy.nightly,
  on schedule.tf line 16, in resource "google_compute_resource_policy" "nightly":
  16:       on_source_disk_delete = "KEEP_SNAPSHOTS"
```

## Consistência

Um snapshot de um disco em uso é tirado enquanto a máquina continua escrevendo, então ele é
**consistente com uma queda**: o que você encontraria depois de puxar o cabo de energia. Um sistema
de arquivos se recupera disso; um banco de dados quase sempre também, e às vezes precisa da própria
recuperação na restauração. Para dados que importam, o hábito mais seguro é deixar a aplicação
esvaziar os buffers antes do snapshot, que é para isso que existe a ferramenta de backup do próprio
banco, e tratar o snapshot do disco como a segunda linha de defesa, não a única.

Restaurar é criar um disco novo a partir do snapshot, nunca escrever por cima do antigo, então uma
restauração pode ser testada antes de qualquer coisa ser substituída.
