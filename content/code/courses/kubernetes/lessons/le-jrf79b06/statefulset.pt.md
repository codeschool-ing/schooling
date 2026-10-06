---
title: Um StatefulSet guarda um nome e um disco
version: 1
---

Os pods de um Deployment são intercambiáveis: nomes aleatórios, qualquer nó, e todos compartilhando o
volume que montam. **Um StatefulSet dá a cada pod uma identidade que sobrevive à substituição**: um nome
fixo (`pg-0`, `pg-1`), um nome de DNS próprio, e um claim próprio que segue esse nome de um pod para o
seguinte.

A senha vem primeiro, num Secret como a lição 14 fez; esta foi inventada para o laboratório.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: pg
spec:
  clusterIP: None
  selector:
    app: pg
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pg
spec:
  serviceName: pg
  replicas: 1
  selector:
    matchLabels:
      app: pg
  template:
    metadata:
      labels:
        app: pg
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: postgres
        image: postgres:18
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pg
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "postgres"]
          periodSeconds: 5
        resources:
          requests:
            cpu: 250m
            memory: 256Mi
          limits:
            memory: 512Mi
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

Três partes fazem o trabalho:

- **`clusterIP: None`** torna `pg` um Service headless. Ele não tem endereço virtual; em vez disso, o
  nome de DNS `pg-0.pg` resolve direto para o pod, que é como um cliente, ou uma réplica, alcança uma
  cópia em particular.
- **`volumeClaimTemplates`** é um claim para ser carimbado uma vez por pod. `pg-0` recebe `data-pg-0`,
  e se houvesse um `pg-1` ele receberia `data-pg-1`. Os claims nunca são compartilhados.
- **`terminationGracePeriodSeconds: 60`** dá ao PostgreSQL um minuto para desligar direito, contra o
  padrão de trinta segundos.

`PGDATA` aponta um nível abaixo do ponto de montagem, porque o script de início da imagem recusa um
diretório de dados que já tenha alguma coisa, e alguns volumes chegam com um `lost+found` dentro.

```
ana@laptop:~/shop$ kubectl create secret generic pg --from-literal=password=lab-only-pg-91
secret/pg created
ana@laptop:~/shop$ kubectl apply -f postgres.yaml
service/pg created
statefulset.apps/pg created
ana@laptop:~/shop$ kubectl get pods,pvc -l app=pg
NAME       READY   STATUS    RESTARTS   AGE
pod/pg-0   1/1     Running   0          11s

NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-pg-0   Bound    pvc-08a1b18e-750d-42ca-a49e-08658371eddc   1Gi        RWO            standard       <unset>                 11s
```

Um pod, `pg-0`, e um claim, `data-pg-0`, ligado pela classe padrão do kind, da lição 26.

## O pod vai; os dados ficam

```
ana@laptop:~/shop$ kubectl exec pg-0 -- psql -U postgres -c "CREATE TABLE orders (id int PRIMARY KEY, total_cents int NOT NULL);"
CREATE TABLE
ana@laptop:~/shop$ kubectl exec pg-0 -- psql -U postgres -c "INSERT INTO orders VALUES (1, 4990), (2, 12900);"
INSERT 0 2
ana@laptop:~/shop$ kubectl delete pod pg-0
pod "pg-0" deleted from default namespace
ana@laptop:~/shop$ kubectl exec pg-0 -- psql -U postgres -c "SELECT * FROM orders;"
 id | total_cents 
----+-------------
  1 |        4990
  2 |       12900
(2 rows)
```

**A tabela e as duas linhas voltaram.** O StatefulSet criou um `pg-0` novo, e o `pg-0` novo montou
`data-pg-0` de novo, porque o claim pertence ao nome e não ao pod. O PostgreSQL subiu sobre os
arquivos que o antigo deixou. Apagar o próprio StatefulSet também não apagaria o claim; claims criados
a partir de um template ficam até alguém removê-los, a não ser que a
`persistentVolumeClaimRetentionPolicy` do StatefulSet diga o contrário, porque perder um banco por um `kubectl delete`
digitado errado é pior do que arrumar à mão.
