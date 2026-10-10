---
title: Installing RabbitMQ, and an emulator for SQS and SNS
version: 1
---

DRAFT

```sh
sudo apt-get install -y rabbitmq-server
pip install pika==1.4.4 'moto[server]==5.2.3' boto3==1.43.111
```
