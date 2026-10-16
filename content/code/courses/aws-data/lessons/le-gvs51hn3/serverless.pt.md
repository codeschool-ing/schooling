---
title: Serverless, e capacidade medida em RPUs
version: 1
---

**O Redshift Serverless é o mesmo motor sem cluster para dimensionar.** Em vez de escolher um tipo e
um número de nós, você define uma capacidade em Redshift Processing Units, RPUs, e o Redshift sobe
essa quantidade de computação quando chega uma consulta e a solta quando as consultas param. As
tabelas, o SQL, as chaves de distribuição e de ordenação das duas últimas seções são os mesmos. O que
muda é quem decide quanta máquina há, e como ela é cobrada.

## Um namespace e um workgroup

**Um data warehouse Serverless são duas coisas com dois nomes.** O **namespace** guarda o que o
warehouse *é*: os bancos, schemas, tabelas, usuários e permissões, e o armazenamento por baixo deles.
O **workgroup** guarda aquilo *em que ele roda*: a capacidade, a rede em que fica, os security groups,
os limites. Eles são separados para que um mude sem o outro; um workgroup pode ser apagado e um novo
ligado ao mesmo namespace, e os dados não saem do lugar.

**A capacidade base é aquilo com que uma consulta começa**: 128 RPUs se você não definir, no mínimo 8,
e em passos de 8. A AWS documenta uma RPU como 16 GB de memória com o processamento que acompanha.
O Redshift pode escalar acima da base enquanto uma consulta pesada roda, e uma configuração de
**capacidade máxima** põe um teto nisso, que é a configuração que impede um erro caro de virar um mês
caro.

**Ele é cobrado por RPU-hora, por segundo, só enquanto há consultas rodando**, com um mínimo de 60
segundos a cada vez que a computação sobe. Uma hora sem consultas não custa nada de computação. O
armazenamento é cobrado à parte, pela tarifa do armazenamento gerenciado, rode algo ou não. Essa é
toda a diferença em relação a um cluster provisionado, que cobra por toda hora em que existe a menos
que alguém o pause, e a próxima seção transforma isso em números.

## O que o moto faz com ele

O moto não tem implementação da API do Redshift Serverless:

```
ana@laptop:~/aws$ aws redshift-serverless create-namespace --namespace-name quitanda

aws: [ERROR]: An error occurred (500) when calling the CreateNamespace operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws redshift-serverless create-workgroup --workgroup-name quitanda-adhoc --namespace-name quitanda --base-capacity 8

aws: [ERROR]: An error occurred (500) when calling the CreateWorkgroup operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**As duas chamadas falharam com um 500 do próprio moto**, um erro interno e não uma resposta que a AWS
daria, e a linha de comando tentou de novo duas vezes antes de desistir. Nada do Serverless pode ser
praticado neste laboratório, nem como registro. Tudo nesta seção vem da documentação da AWS e não foi
rodado.

## Qual escolher

**O Serverless serve a trabalho que vai e vem**: analistas que consultam no horário comercial, um
dashboard atualizado algumas vezes por dia, um time que ainda não sabe qual será a carga. **Um cluster
provisionado serve a trabalho que nunca para**: cargas chegando o dia todo, relatórios rodando a noite
toda, um warehouse ocupado na maior parte das horas. A linha entre os dois é um número de horas
ocupadas por dia, e a tabela de preços diz onde ela cai.
