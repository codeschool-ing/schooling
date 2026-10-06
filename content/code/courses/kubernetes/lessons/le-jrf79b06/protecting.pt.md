---
title: Um desligamento limpo e uma cópia em outro lugar
version: 1
---

O volume sobreviveu a um pod apagado. **Ele não sobrevive a um claim apagado, a um nó perdido, a uma
migração errada ou ao `DROP TABLE` de alguém**, e nada disso é raro. Um banco precisa de uma cópia dos
dados que viva em outro lugar e que tenha sido testada restaurando-a.

## Um backup como Job

A ferramenta do próprio PostgreSQL para uma cópia lógica é o `pg_dump`, e um Job, da lição 12, é o
jeito natural de rodá-la no cluster: ele se conecta a `pg-0` pelo nome de DNS próprio e termina.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pg-dump
spec:
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: dump
        image: postgres:18
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: pg
              key: password
        command: ["sh", "-c", "pg_dump -h pg-0.pg -U postgres -t orders postgres | grep -E 'CREATE TABLE|^COPY|^[0-9]'"]
```

O `grep` está ali para a captura caber numa tela; um Job de backup de verdade escreve o dump inteiro
num lugar fora do cluster, como um bucket de armazenamento de objetos, e um CronJob o roda num
horário.

```
ana@laptop:~/shop$ kubectl apply -f backup.yaml
job.batch/pg-dump created
ana@laptop:~/shop$ kubectl logs job/pg-dump
CREATE TABLE public.orders (
COPY public.orders (id, total_cents) FROM stdin;
1	4990
2	12900
```

A definição da tabela e as duas linhas, como texto que o `psql` consegue reproduzir num banco vazio. Um
dump assim é consistente, pequeno e portável entre versões. Para bancos grandes, backups físicos com
arquivamento contínuo do write-ahead log restauram mais rápido e para qualquer momento, e esse é o
trabalho de uma ferramenta dedicada ou de um operator, mais abaixo.

## Desligando direito

Quando `pg-0` foi apagado, o kubelet mandou um SIGTERM ao PostgreSQL e esperou. O log dele, seguido de
um segundo terminal enquanto o pod ia embora, mostra o que o PostgreSQL fez com esse tempo:

```
ana@laptop:~/shop$ grep -E "fast shutdown|checkpoint starting: shutdown|database system is shut down" pg-0.log | tail -n 3
2026-10-06 20:43:45.967 UTC [1] LOG:  received fast shutdown request
2026-10-06 20:43:45.977 UTC [72] LOG:  checkpoint starting: shutdown immediate
2026-10-06 20:43:46.007 UTC [1] LOG:  database system is shut down
```

**Um fast shutdown com checkpoint**: o PostgreSQL escreveu no disco tudo o que tinha na memória e
parou, em quarenta milissegundos aqui. Um banco grande e movimentado pode levar muito mais, e é por
isso que o manifesto aumentou o prazo. Se o prazo acabar, o kubelet manda SIGKILL, e a próxima subida
precisa se recuperar pelo write-ahead log: nenhum dado confirmado se perde, mas a subida é mais lenta,
e uma falha durante essa recuperação é mais uma coisa que pode dar errado.
