---
title: O que uma classe de armazenamento troca
version: 1
---

**Uma classe de armazenamento é um preço para guardar um gigabyte casado com um preço para lê-lo de
volta**, e toda classe abaixo do Standard compra um primeiro preço menor com um segundo maior. É comum
ler a lista como "rápido, mais lento, mais lento ainda", como se as classes baratas fossem discos mais
lentos. Elas não são mais lentas desse jeito. Standard-IA e Glacier Instant Retrieval respondem a uma
leitura em milissegundos, exatamente como o Standard; o que elas mudam é a conta dessa leitura e a
conta de sair cedo. Só as duas classes de arquivo são lentas, e nelas o objeto nem pode ser lido até
que você o peça de volta.

A classe é escolhida por objeto, não por bucket. Um bucket pode guardar os pedidos de hoje em
Standard, os do ano passado em Glacier Instant Retrieval e as exportações de auditoria de 2019 em Deep
Archive, lado a lado, sob os mesmos prefixos.

## Os preços

A tabela de preços da lição 1 imprime o bloco do S3. Esta lição, como toda lição do curso, supõe o
moto rodando no terminal dele e as quatro linhas de "Seu laboratório, em resumo", da lição 1,
digitadas neste; a tabela em si não precisa de nenhum dos dois, só do cache que ela encheu na primeira
vez:

```
ana@laptop:~/aws$ python3 prices.py s3
AWS public price list, sa-east-1, USD, excluding tax

S3 storage, USD per GB-month
  Standard, first 50 TB                                 0.04050  GB-month
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Standard-IA                                           0.02210  GB-month
  One Zone-IA                                           0.01770  GB-month
  Glacier Instant Retrieval                             0.00830  GB-month
  Glacier Flexible Retrieval                            0.00765  GB-month
  Glacier Deep Archive                                  0.00320  GB-month

S3 requests, USD per 1,000
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
  Standard-IA: GET                                      0.00100  per 1,000
  Glacier Instant Retrieval: GET                        0.01000  per 1,000
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month

S3 retrieval, USD per GB
  Standard-IA                                           0.01000  GB
  Glacier Instant Retrieval                             0.03000  GB
  Glacier Flexible, expedited                           0.04200  GB
  Glacier Flexible, standard                            0.01400  GB
  Deep Archive, standard                                0.02800  GB
  Deep Archive, bulk                                    0.00800  GB
```

**O Standard custa 0,04050 por GB-mês e o Deep Archive 0,00320**, então o arquivo guarda um gigabyte
por menos de um doze avos do preço. O bloco de recuperação é a outra metade. Ler um gigabyte de volta
não custa nada a mais no Standard, custa 0,01000 no Standard-IA, 0,03000 no Glacier Instant Retrieval
e 0,02800 no Deep Archive na velocidade padrão.

## O que mais cada classe troca

A tabela de preços mostra duas das trocas. A documentação da AWS sobre as classes de armazenamento do
S3 diz o resto, e nada disso o moto consegue mostrar, porque ele guarda todo objeto no mesmo
dicionário, diga a classe o que disser:

| classe | zonas | mínimo de dias cobrados | menor objeto cobrado | primeiro byte |
|---|---|---|---|---|
| Standard | pelo menos 3 | nenhum | nenhum | milissegundos |
| Intelligent-Tiering | pelo menos 3 | nenhum | sem monitoramento abaixo de 128 KB | milissegundos, nas camadas padrão |
| Standard-IA | pelo menos 3 | 30 | 128 KB | milissegundos |
| One Zone-IA | 1 | 30 | 128 KB | milissegundos |
| Glacier Instant Retrieval | pelo menos 3 | 90 | 128 KB | milissegundos |
| Glacier Flexible Retrieval | pelo menos 3 | 90 | 40 KB a mais por objeto | minutos a horas, depois de uma restauração |
| Glacier Deep Archive | pelo menos 3 | 180 | 40 KB a mais por objeto | horas, depois de uma restauração |

**A duração mínima é uma conta por sair cedo.** Um objeto apagado, sobrescrito ou passado para outra
classe antes do mínimo é cobrado pelos dias que faltam, então um arquivo guardado no Deep Archive por
dez dias é cobrado por 180. Um terabyte, 1.024 GB nos gigabytes que a lista de preços conta, por dez
dias a 0,00320 daria cerca de 1.024 × 0,00320 × 10 / 30 = 1,09 USD; cobrado por 180 dias, dá
1.024 × 0,00320 × 6 = 19,66.

**O menor tamanho cobrado castiga arquivos pequenos.** Um objeto de 10 KB no Standard-IA é cobrado
como 128 KB, quase treze vezes o tamanho dele. E um objeto em qualquer das duas classes de arquivo do
Glacier carrega 40 KB além dos próprios bytes: 32 KB de índice cobrados ao preço do arquivo e 8 KB de
nome e metadados cobrados ao preço do Standard. Um milhão de linhas de log de 10 KB, arquivadas uma por
objeto, são pagas como cinco vezes o tamanho delas, parte disso ao preço do Standard.

**O One Zone-IA guarda uma cópia dos dados em uma zona.** Todas as outras classes espalham o objeto por
pelo menos três zonas da região. O One Zone-IA é o preço de abrir mão disso: se a zona for destruída,
os dados vão junto. Serve para algo que pode ser produzido de novo, como uma miniatura feita a partir
de um original guardado em outro lugar, e nunca para a única cópia de coisa alguma.

A figura põe numa página as duas trocas que a tabela de preços imprime: quanto custa guardar um
gigabyte, contra quanto demora o primeiro byte e quanto custa ler um gigabyte.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 326\" role=\"img\" aria-label=\"Cinco classes do S3 num gráfico de duas dimensões. Na horizontal, o preço de guardar um GB por mês; na vertical, quanto demora o primeiro byte. Em milissegundos: Standard a 0,0405, sem nada a mais para ler; Standard-IA a 0,0221, 0,010 por GB lido; Glacier Instant Retrieval a 0,0083, 0,030 por GB lido. Em minutos a horas: Glacier Flexible Retrieval a 0,00765, 0,014 por GB. Em horas a dois dias: Deep Archive a 0,0032, de 0,008 a 0,028 por GB. Quanto mais barato guardar, mais caro ou mais demorado ler.\" data-fig=\"l02-classes\"><path d=\"M150.0 112.0 L700.0 112.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">milissegundos</text><path d=\"M150.0 197.0 L700.0 197.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">minutos a horas</text><path d=\"M150.0 282.0 L700.0 282.0\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20.0\" y=\"240.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">horas a dois dias</text><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">primeiro byte</text><path d=\"M150.0 282.0 L700.0 282.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M160.0 282.0 L160.0 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"160.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,00</text><path d=\"M277.8 282.0 L277.8 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"277.8\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,01</text><path d=\"M395.6 282.0 L395.6 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"395.6\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,02</text><path d=\"M513.3 282.0 L513.3 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"513.3\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,03</text><path d=\"M631.1 282.0 L631.1 287.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"631.1\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0,04</text><text x=\"700.0\" y=\"316.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">guardar, USD por GB-mês</text><circle cx=\"637.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"637.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard</text><text x=\"637.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ler: nada a mais</text><circle cx=\"420.3\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"420.3\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Standard-IA</text><text x=\"420.3\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ler: 0,010 por GB</text><circle cx=\"257.8\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"251.8\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Glacier Instant Retrieval</text><text x=\"251.8\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ler: 0,030 por GB</text><circle cx=\"250.1\" cy=\"155.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"244.1\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Glacier Flexible Retrieval</text><text x=\"244.1\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ler: 0,014 por GB</text><circle cx=\"197.7\" cy=\"240.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"191.7\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Deep Archive</text><text x=\"191.7\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">ler: 0,008 a 0,028 por GB</text></svg>", "caption": "O que um GB custa para ficar, contra o tempo e o preço para voltar. One Zone-IA fica de fora: a tabela não imprime o preço de leitura dela.", "same": ["Standard", "Standard-IA", "Glacier Instant Retrieval", "Glacier Flexible Retrieval", "Deep Archive"]}
```

Duas classes ficam fora da tabela de propósito. **Reduced Redundancy** é uma classe antiga que a AWS
não recomenda mais, e a tabela de preços não a imprime. O S3 Express One Zone pertence a outro tipo de
bucket, um bucket de diretório numa única zona, feito para latência muito baixa, que este curso não
usa.
