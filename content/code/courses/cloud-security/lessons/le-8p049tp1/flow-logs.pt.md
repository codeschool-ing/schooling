---
title: Flow logs: o que de fato passou pelo fio
version: 1
---

**A configuração diz que tráfego é permitido; um flow log diz que tráfego aconteceu.** O verificador
da seção anterior prova que o SSH ficou aberto a todos por um mês. Ele não diz se alguém se
conectou, e depois de uma exposição essa é a primeira pergunta que todo mundo faz. Na nuvem não há
cabo para grampear, como disse a aula 1. O flow log é o mais perto disso que o provedor oferece:
**uma linha por conversa, registrada só se você o ligou antes de a conversa acontecer.**

## Ligando

Um flow log é anexado a uma VPC, a uma sub-rede ou a uma única interface de rede, e entregue num
bucket ou no CloudWatch Logs. O da clínica vai para um bucket só dele, para a VPC inteira, registrando
tanto o tráfego aceito quanto o rejeitado:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-flow-logs --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-flow-logs
ana@laptop:~/aws$ aws ec2 create-flow-logs --resource-type VPC --resource-ids "$vpc" --traffic-type ALL --log-destination-type s3 --log-destination arn:aws:s3:::clinic-flow-logs --query FlowLogIds --output text
fl-669057bdd6cb69ad6
ana@laptop:~/aws$ aws ec2 describe-flow-logs --query "FlowLogs[].[FlowLogId,ResourceId,TrafficType,LogDestination,LogFormat]" --output text
fl-669057bdd6cb69ad6	vpc-e1a208744d0ad63a7	ALL	arn:aws:s3:::clinic-flow-logs	${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}
ana@laptop:~/aws$ aws s3 ls s3://clinic-flow-logs --recursive
```

A última coluna do `describe-flow-logs` é o formato em que cada registro será gravado, e como nada
mais foi pedido é o padrão. **Isso, e um bucket vazio, é tudo o que o laboratório consegue
mostrar.** O moto guarda a configuração do flow log e não registra nada, já que não carrega tráfego.
O que vem a seguir é documentação da AWS, não uma execução.

## O que um registro diz

No formato padrão, cada registro é uma linha de campos separados por espaço, nesta ordem:

| campo | o que guarda |
|---|---|
| `version` | a versão do formato, `2` no padrão |
| `account-id` | a conta dona da interface |
| `interface-id` | a interface de rede que o tráfego atravessou |
| `srcaddr`, `dstaddr` | os dois endereços |
| `srcport`, `dstport` | as duas portas |
| `protocol` | o número de protocolo da IANA: `6` é TCP, `17` é UDP |
| `packets`, `bytes` | quanto, durante a janela de agregação |
| `start`, `end` | a janela, em segundos desde 1970 |
| `action` | `ACCEPT` ou `REJECT` |
| `log-status` | `OK`, ou `NODATA` e `SKIPDATA` quando não houve nada ou algo se perdeu |

A linha abaixo foi **escrita por este curso nesse formato documentado**, com um endereço da faixa
reservada para documentação, para mostrar a forma. Não é uma gravação:

```
2 123456789012 eni-0123456789abcdef0 203.0.113.50 10.20.1.10 51544 22 6 14 2448 1792756800 1792756860 ACCEPT OK
```

Leia da esquerda para a direita: de `203.0.113.50`, o endereço de um estranho, para a porta 22 de um
servidor web, por TCP, aceita. **É uma conexão à porta SSH que a seção anterior fechou**, e é a linha
que uma investigação procura. Um `REJECT` vindo do mesmo endereço depois seria a correção se
sustentando.

## O que um flow log não diz

- **Ele registra conversas, não conteúdo.** Não há payload, nenhum comando digitado, nenhum nome de
  arquivo. Se aquela sessão SSH leu o banco de prontuários é pergunta para os logs do próprio
  servidor.
- **Ele é agregado**, em janelas de até dez minutos por padrão, então dá contagens e não uma linha do
  tempo ao segundo.
- **Parte do tráfego nem aparece**, pela documentação da AWS: requisições ao endereço de metadados da
  instância, ao resolvedor de DNS da Amazon e o DHCP, entre outras.
- **Ele não vem ligado, e é cobrado** como entrega e armazenamento de log. Uma conta que o ligou na
  manhã seguinte a um incidente não tem nada sobre o incidente.

Os VPC Flow Logs do Google Cloud e os flow logs de rede virtual do Azure respondem à mesma pergunta
com outros campos; nenhum é executado aqui. A aula 15 põe os flow logs ao lado do registro de
chamadas de API, que responde à outra pergunta: não *quem se conectou*, mas *quem abriu a porta*.
