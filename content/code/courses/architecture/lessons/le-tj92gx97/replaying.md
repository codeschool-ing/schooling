---
title: Lag, a second group, and reading it all again
version: 1
---

Two more orders arrive while the e-mail group is not running. Kafka stores them; the group's offsets do
not move, and the lag shows exactly what is waiting:

```
ana@vm:~/lab/brokers$ printf "ana:order 6\ncarla:order 7\n" | kafka console-producer --topic orders --property parse.key=true --property key.separator=:
ana@vm:~/lab/brokers$ kafka consumer-groups --describe --group email

Consumer group 'email' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
email           orders          0          0               0               0               -               -               -
email           orders          1          2               3               1               -               -               -
email           orders          2          3               4               1               -               -               -
```

`LAG` is 1 in partition 1 and 1 in partition 2: one new order for ana, one for carla. When the e-mail
consumers start again they begin from `CURRENT-OFFSET`, read those two and nothing else.

## A second group reads everything

The warehouse decides to read the topic too. A new group has no stored offsets, so it starts from the
oldest message still retained, and **it reads all seven orders, including the five the e-mail group read
long ago**:

```
ana@vm:~/lab/brokers$ kafka console-consumer --topic orders --group warehouse --from-beginning --max-messages 7 --property print.partition=true --property print.key=true
Partition:1	ana	order 1
Partition:1	ana	order 3
Partition:1	ana	order 6
Partition:2	bruno	order 2
Partition:2	carla	order 4
Partition:2	bruno	order 5
Partition:2	carla	order 7
Processed a total of 7 messages
```

Nothing the e-mail group did affected the warehouse group, and nothing the warehouse reads affects the
e-mail group's lag. In RabbitMQ the warehouse would have needed its queue bound before the orders were
published; here it arrived later and lost nothing, for as long as the topic's retention keeps the
messages.

## Rewinding

Suppose the e-mail service had a bug that sent every confirmation with the wrong store address, and it
is now fixed. With a log the messages are still there, so **the fix can be applied to the past**: move the
group's offsets back and let it read again. The tool refuses to move the offsets of a group with active
consumers, which is why the console consumer above was allowed to exit:

```
ana@vm:~/lab/brokers$ kafka consumer-groups --group email --reset-offsets --to-earliest --topic orders --execute

GROUP                          TOPIC                          PARTITION  NEW-OFFSET     
email                          orders                         0          0              
email                          orders                         1          0              
email                          orders                         2          0              
ana@vm:~/lab/brokers$ kafka consumer-groups --describe --group email

Consumer group 'email' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
email           orders          0          0               0               0               -               -               -
email           orders          1          0               3               3               -               -               -
email           orders          2          0               4               4               -               -               -
```

Every partition's offset is back at 0, the lag is the whole topic, and the next run of the e-mail
consumers will send all seven confirmations again. **That is the power and the danger of a replay**:
the consumer will act on old messages as if they were new, so a consumer that can be replayed has to be
safe to run twice on the same message. That property is called idempotency, and it is the first subject
of lesson 7.

Stop the lesson's brokers before going on; the next section needs nothing running:

```sh
docker compose down -v
```
