---
title: Fencing: garantir que o primário antigo parou
version: 1
---

Todo split-brain acima vem de uma mesma brecha: o novo primário começou enquanto o antigo ainda
conseguia aceitar escritas. O **fencing** fecha essa brecha tornando o primário antigo incapaz de
escrever **antes** que o novo seja promovido. As formas de fazer isso diferem no que custam e no que
confiam:

| fencing | como ele para o primário antigo | o que custa |
|---|---|---|
| **watchdog** | um timer no kernel, que o Patroni precisa zerar a cada volta do loop; se o Patroni parar de zerá-lo, o kernel reinicia a máquina, antes que a chave de líder possa expirar | o reboot de uma máquina que talvez só estivesse lenta |
| **STONITH** ("shoot the other node in the head", atire na cabeça do outro nó) | o novo primário, ou o gerenciador, desliga a máquina antiga pela interface de gerenciamento dela ou pela API do provedor de nuvem | credenciais capazes de desligar um servidor de banco de dados, e a dependência de essa interface responder |
| **fencing de rede** | a porta de rede do primário antigo, ou o endereço dele num load balancer, é cortada | uma rede que você controla, e o corte precisa alcançar cada caminho até ele |
| **replicação síncrona** | o primário antigo não consegue confirmar um commit sem um standby, e o standby dele passou para o novo primário | a latência de commit da lição 12 |

## O watchdog

O watchdog é o que o Patroni traz embutido, e ele cobre exatamente o congelamento desta lição: o
Patroni arma o timer para disparar alguns segundos antes de a chave dele expirar, então um Patroni
congelado significa uma máquina reiniciada, e uma máquina reiniciada não aceita nada. Numa máquina
virtual, o watchdog de software do kernel fornece o dispositivo:

```sh
sudo modprobe softdog
sudo chown ana /dev/watchdog
```

e três linhas no arquivo de cada nó, ao lado de `postgresql:`:

```yaml
watchdog:
  mode: required
  device: /dev/watchdog
```

O `required` faz o Patroni se recusar a virar líder num nó onde o watchdog não pode ser armado, então
um dispositivo ausente é descoberto na inicialização e não durante um failover. A máquina de onde vêm
estas transcrições não tem dispositivo de watchdog e não consegue carregar um, então este curso não tem
transcrição disso; na sua máquina virtual, congelar o Patroni do líder como acima deve terminar com a
máquina virtual reiniciando, e o pedido gravado nela nunca confirmado.

O `softdog` é um timer dentro do mesmo kernel que ele deveria reiniciar, então um kernel que trava o
derruba junto. Servidores têm um watchdog de hardware para isso, e os provedores de nuvem oferecem um
equivalente; para aprender, o de software mostra o mecanismo.
