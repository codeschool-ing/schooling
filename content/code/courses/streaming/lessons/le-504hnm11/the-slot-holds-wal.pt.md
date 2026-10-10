---
title: O slot que segura o WAL
version: 1
---

**Um conector parado não perde dados; ele faz o banco guardá-los.** Essa é a promessa de um slot de
replicação, e é também o jeito mais comum de a CDC derrubar um banco de produção. O conector para —
um deploy que falhou, um broker fora do ar, credenciais que expiraram num fim de semana — e ninguém
percebe, porque nada está falhando: o site funciona, a tabela está bem, e o tópico simplesmente não
recebe nada. Enquanto isso o PostgreSQL guarda todo arquivo de WAL gravado desde a última posição
confirmada do slot, e o disco sob o banco enche.

Faça acontecer. No segundo shell, pare o Connect com Ctrl+C. De volta ao primeiro, esta consulta
mostra cada slot, se alguém o está lendo, e duas distâncias medidas em bytes de WAL: o quanto o
leitor está atrás do servidor agora, e quanto WAL o servidor está guardando por causa dele:

@@fence@@

O `active` é `f`: ninguém está conectado. Agora a loja continua trabalhando. Alguém monta uma tabela
de anotações que não tem nada a ver com CDC e não está na publicação, e depois uma entrega repõe o
estoque de toda loja com um exemplar de tudo:

@@fence@@

**A tabela de anotações não está publicada, e o WAL dela fica guardado do mesmo jeito.** O WAL é um
fluxo só para o servidor inteiro; um slot segura todo ele a partir da sua posição, sejam de quais
tabelas forem os bytes. Um slot que lê duas tabelas pequenas num banco onde outra coisa escreve
gigabytes por hora segura esses gigabytes.

## Alcançando

Suba o Connect de novo no segundo shell, com o mesmo comando de antes. Ele acha a sua posição no
`connect.offsets`, pede ao slot tudo o que vem depois dela, e não tira um segundo snapshot. Depois,
no primeiro shell:

@@fence@@

Os quarenta updates feitos enquanto ele estava parado estão no tópico, depois das 44 mensagens que
já estavam lá. Nada se perdeu, que é o slot fazendo o trabalho dele. E do lado do banco, o leitor
voltou:

@@fence@@

## O que observar, e o limite a definir

**O tamanho retido de cada slot é o número para alertar**, com a consulta acima ou o equivalente
dela no que monitora o banco, e `active = f` por mais tempo do que dura um deploy é o segundo. Um
slot sem leitor é ou um incidente a corrigir ou uma sobra a apagar com `pg_drop_replication_slot` —
e um conector que está sendo aposentado de vez deve ter o slot apagado no mesmo dia, porque nada
mais vai apagá-lo.

O PostgreSQL também tem um fusível, desligado por padrão:

@@fence@@

`-1` quer dizer sem limite. Com, digamos, `50GB`, o PostgreSQL para de guardar WAL para um slot
além desse tamanho e marca o slot como perdido. **Isso troca o disco do banco pela completude do
conector**: o banco sobrevive, e o conector precisa tirar um novo snapshot, porque as mudanças que
ele perdeu se foram. A maioria das equipes escolhe essa troca, de propósito, com o limite
dimensionado para a pane da qual conseguem se recuperar.

Mais uma configuração fecha uma versão mais quieta do mesmo problema. A posição de um slot só anda
quando o conector confirma uma mudança que leu, então se as tabelas publicadas estão quietas enquanto
outras estão movimentadas — a `stock` mudando uma vez por dia num banco que escreve a noite toda — o
slot fica parado e o WAL cresce mesmo com o Connect rodando. O `heartbeat.interval.ms` do Debezium
faz o conector confirmar a posição num intervalo de tempo, tenham as tabelas dele mudado ou não. Ele
não foi definido neste laboratório.

Antes de sair desta lição, pare o Connect com Ctrl+C no segundo shell. O PostgreSQL pode continuar
rodando; ele não faz nada até alguém escrever nele.
