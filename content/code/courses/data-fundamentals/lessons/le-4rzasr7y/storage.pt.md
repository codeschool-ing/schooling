---
title: Armazenamento: três zonas, e a que ninguém edita
version: 1
---

**Um pipeline guarda o mesmo dado mais de uma vez, de propósito: como chegou, como foi limpo, e como
alguém vai lê-lo.** É tentador imaginar o armazenamento como o fim da linha, um banco onde o
dado finalmente descansa. Na prática cada etapa grava o seu resultado em algum lugar e a etapa seguinte o
lê dali, e as cópias têm trabalhos diferentes.

## As três zonas

| zona | o que ela guarda | quem lê | também chamada de |
|---|---|---|---|
| **bruta** | o dado exatamente como a ingestão copiou, um diretório por dia | a transformação, e mais ninguém | landing, bronze |
| **limpa** | as mesmas linhas com as regras aplicadas: linhas ruins fora, tipos corrigidos, nomes juntados | o time de dados, e a transformação seguinte | staging, prata |
| **curada** | tabelas no formato de um uso: viagens por estação por dia, uma tabela de atributos para um modelo | analistas, relatórios, painéis, modelos | marts, ouro |

**Bronze, prata e ouro** são os nomes que a Databricks popularizou para as mesmas três, e você vai
ouvi-los em times que nunca usaram Databricks. Os nomes mudam de empresa para empresa; os três
trabalhos não. No programa que você vai construir, elas são três diretórios: `raw/`, `clean/` e
`curated/`.

## O bruto é guardado, e ninguém o edita

**A zona bruta é a única cópia do que a origem de fato disse, e é a única zona que não pode ser
reconstruída.** Todas as outras podem: a limpa e a curada são a saída de programas, e um programa
pode rodar de novo. A bruta é a saída de um momento que já passou. A seção anterior mostrou por quê:
a origem guarda o presente, os sensores guardam dois dias, e o aplicativo atualiza no lugar uma
viagem estornada.

Essa propriedade se paga na primeira vez que uma regra muda. Suponha que Marta decida que uma
partida falsa é uma viagem de menos de um minuto, não de dois. Com o bruto guardado, a correção é
mudar um número na transformação e rodá-la de novo sobre todos os dias desde o começo; as zonas
limpa e curada saem como se a regra sempre tivesse sido um minuto. Sem o bruto, as viagens entre um
e dois minutos foram descartadas meses atrás e nada as traz de volta.

Então as regras do bruto são curtas:

- **nada grava nele além da ingestão**;
- **uma linha dele nunca é editada**. Um dia é acrescentado, ou um dia inteiro é substituído
  copiando-o de novo da origem; uma linha avulsa nunca é remendada à mão;
- **ele é guardado enquanto alguém puder precisar reconstruir a partir dele**, e não mais. O bruto é
  também onde o dado pessoal chega intacto, então por quanto tempo ele fica é uma decisão de
  privacidade além de custo. A aula 7 volta a isso.

## Um diretório por dia

O caminho `raw/date=2025-09-15/` tem um trabalho próprio. Dividir uma tabela em diretórios pelo
valor de uma coluna se chama **particionar**, e a grafia `nome=valor` do diretório é uma convenção
que muitas ferramentas leem: diante de uma pergunta sobre a segunda-feira, elas abrem o diretório da
segunda e pulam o resto. Isso também deixa óbvia a unidade de trabalho. Substituir a segunda é
substituir um diretório, que é como a seção 09 conserta um pipeline que contou a
segunda duas vezes.

A aula 9 usa a mesma palavra para algo maior, dividir o dado entre máquinas; a ideia é a mesma, uma
chave decidindo para onde vai cada linha.

## Onde as zonas moram

Na sua máquina, as zonas são diretórios. Numa empresa, em geral são **armazenamento de objetos** numa
nuvem — arquivos endereçados por um caminho, baratos de guardar e lentos de mudar, assunto do curso
`cloud` — ou tabelas num **warehouse**, que `warehouse-modeling` constrói. O formato dos arquivos
importa tanto quanto o lugar, e a aula 6 compara cinco deles. Nada disso muda os três trabalhos, nem
a regra de que o bruto fica como chegou.
