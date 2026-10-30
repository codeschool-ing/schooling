---
title: Autoclass, e a taxa por ser gerenciado
version: 1
---

**O Autoclass é uma configuração do bucket que move cada objeto entre classes sozinho**, de acordo com
a última vez que foi lido, e cobra uma taxa mensal por objeto para fazer isso. É a resposta para "não
sabemos como esses dados vão ser lidos", e é a resposta errada para objetos pequenos, porque a taxa é
por objeto e a economia é por gibibyte.

A documentação do Google para o Autoclass, cloud.google.com/storage/docs/autoclass, o descreve assim.
Todo objeto começa em Standard. Depois de 30 dias sem ser lido ele vai para Nearline e, se a classe
terminal do bucket for Archive, segue para Coldline depois de 90 dias e para Archive depois de 365. A
classe terminal é Nearline, a não ser que o bucket peça Archive. Uma leitura move o objeto de volta
para o Standard. Uma regra de ciclo de vida que muda classes não pode ficar ao lado do Autoclass no
mesmo bucket, porque as duas estariam decidindo a mesma coisa.

A página de preços acrescenta o custo, e é uma conta diferente do resto desta aula:

- **sem taxas de recuperação e sem cobranças de exclusão antecipada** para objetos num bucket com
  Autoclass, o que torna as mudanças seguras de fazer automaticamente;
- **uma taxa de gerenciamento de 0,0025 USD a cada 1.000 objetos** guardados por 30 dias;
- **objetos menores que 128 KiB não são gerenciados nem contados**. Ficam no Standard enquanto
  existirem, ao preço do Standard;
- **as operações são cobradas ao preço do Standard** num bucket assim, e uma mudança de Coldline ou
  Archive de volta para Standard ou Nearline é cobrada como uma operação Class A;
- **ligar o Autoclass num bucket que já tem objetos tem uma cobrança única**: as exclusões antecipadas
  e recuperações de levar cada objeto para o Standard, e uma operação Class A por objeto.

## No emulador

O bucket de logs da Quitanda é o candidato: logs da aplicação, lidos com frequência por uma semana e
depois quase nunca, sem que ninguém saiba dizer quais. Crie-o com Autoclass e Archive como classe
terminal:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-logs-prod --location=southamerica-east1 --enable-autoclass --autoclass-terminal-storage-class=ARCHIVE
Creating gs://quitanda-logs-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-logs-prod --format=json
{
  "creation_time": "2026-10-30T15:30:35-0300",
  "default_storage_class": "STANDARD",
  "location": "southamerica-east1",
  "location_type": "region",
  "metageneration": 1,
  "name": "quitanda-logs-prod",
  "storage_url": "gs://quitanda-logs-prod/",
  "update_time": "2026-10-30T15:30:35-0300",
  "versioning_enabled": false
}
ana@laptop:~/gcp$ curl -s http://localhost:4443/storage/v1/b/quitanda-logs-prod | grep -c -i autoclass
0
```

**O bucket foi criado e a configuração não foi guardada.** A linha de comando a enviou, o emulador
respondeu com sucesso, e nem o `describe` nem a resposta do próprio emulador sobre o bucket mencionam o
Autoclass: o último comando contou a palavra na resposta e a encontrou zero vezes. O fake-gcs-server
1.54.0 não implementa o Autoclass, e não avisa. Nada nesta seção depende de executá-lo; o que vem a
seguir é aritmética sobre os preços documentados.

## A taxa contra o objeto

O menor objeto que paga a taxa tem 128 KiB. O armazenamento dele em Standard, em São Paulo, é
128 / 1.048.576 GiB × 0,035, e a taxa é 0,0025 / 1.000 por mês:

```
ana@laptop:~/gcp$ python3 -c 'keep = 128 / 1024**2 * 0.035; fee = 0.0025 / 1000; print(f"{keep:.8f} {fee:.8f} {fee / keep:.0%}")'
0.00000427 0.00000250 59%
ana@laptop:~/gcp$ python3 -c 'keep = 1 / 1024 * 0.035; fee = 0.0025 / 1000; print(f"{keep:.8f} {fee:.8f} {fee / keep:.1%}")'
0.00003418 0.00000250 7.3%
```

**Para um objeto de 128 KiB a taxa é 59% do preço de guardá-lo em Standard.** Mesmo que o Autoclass o
movesse para o Archive no primeiro dia, onde custaria 0,003 em vez de 0,035, a taxa sozinha manteria
o objeto acima da metade do que o Standard cobra. Com 1 MiB a taxa é 7,3% do preço do Standard, e com
100 MiB bem menos de um décimo de ponto percentual. O Autoclass se paga em objetos grandes de futuro
desconhecido: os arquivos Parquet de um data lake, que a aula 17 consulta no lugar. Não se paga nos
logs da Quitanda se eles forem escritos como um objeto pequeno por requisição, e o primeiro passo
honesto ali é escrever menos objetos, e maiores. Uma regra de ciclo de vida, que a aula 3 escreve, faz
as mesmas mudanças para um padrão conhecido sem taxa, e um objeto que ela move não volta sozinho.

## Autoclass ou uma regra de ciclo de vida

Os dois fazem trabalhos que se sobrepõem, e a escolha entre eles é uma pergunta sobre o que você sabe:

| | Autoclass | regra de ciclo de vida |
|---|---|---|
| decide a partir de | quando cada objeto foi lido pela última vez | a idade de cada objeto, e outras condições |
| move um objeto de volta para o Standard | sim, numa leitura | nunca |
| taxas de recuperação e de exclusão antecipada | nenhuma | as da classe, em leituras e exclusões antecipadas |
| custo de funcionar | 0,0025 USD por 1.000 objetos de 128 KiB ou mais, a cada 30 dias | nada, além da operação Class A de cada mudança |

**Use uma regra quando o padrão é conhecido, e o Autoclass quando não é.** As exportações de pedidos da
Quitanda são lidas por um mês e depois quase nunca, num calendário que todo mundo conhece, e uma regra
as move de graça. Os arquivos do data lake são lidos sempre que um analista tem uma pergunta, e ninguém
sabe dizer qual arquivo será o próximo. Ali o Autoclass vale a taxa, porque um arquivo que volta a ser
popular de repente volta para o Standard em vez de pagar os 0,05 por GiB do Archive em toda leitura.
