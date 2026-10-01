---
title: O caso da aula 21, registrado
version: 1
---

Este é o registro inteiro do buraco negro da aula 21, montado só com o que as transcrições daquela aula
imprimiram. Ele é curto de propósito. **Um registro que alguém lê no começo de um incidente precisa caber
numa tela**, e o que for mais longo vai num apêndice com as capturas completas.

## Resumo

Downloads de `files`, na sede, para a filial pelo túnel WireGuard travavam em 0 bytes, enquanto páginas
pequenas do mesmo servidor carregavam. Pacotes acima de 1420 bytes eram descartados na entrada do `wg0`
em `hq`, e a mensagem que teria dito ao emissor para usar pacotes menores era descartada por uma regra de
firewall na saída do próprio `hq`. **Corrigido limitando o MSS do TCP a 1380 em `hq`. A regra continua
lá** e é a primeira ação.

## Sintoma

Nas palavras da filial: a página do servidor de arquivos abre, um download dele nunca termina. Medido a
partir do caixa:

```
ana@till:~$ curl -sS -m 5 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/
200 16 bytes
ana@till:~$ curl -sS -m 8 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
curl: (28) Operation timed out after 8002 milliseconds with 0 bytes received
000 0 bytes
```

## Linha do tempo

Nenhum horário foi registrado, então esta linha do tempo tem ordem e não tem horas, o que já é uma
constatação para o próximo incidente. Em ordem, como as transcrições mostram:

1. `/` a partir do caixa: `200 16 bytes`.
2. `big.bin` a partir do caixa: 0 bytes, o curl desiste depois de 8002 ms.
3. Captura no lado do escritório de `hq`: segmentos de 1448 bytes saem de `files`, e nenhum dos nove
   pacotes capturados confirma dados.
4. De `files`, pings com Don't Fragment: `-s 1392` atravessa, `-s 1400` se perde sem erro.
5. O `wg0` em `hq` tem `mtu 1420`.
6. `nft list ruleset` em `hq` mostra a regra `hardening` descartando destination unreachable na saída.
7. MSS clamping em 1380 acrescentado em `hq`, nos dois sentidos pelo `wg0`.
8. `big.bin` a partir do caixa: `200 20000000 bytes`, e o SYN do caixa chega ao escritório com `mss 1380`.

## Hipóteses e testes

| | hipótese | teste | resultado | veredito |
|---|---|---|---|---|
| 1 | o nome, a rota, o túnel ou o servidor web caiu | `/` a partir do caixa | `200 16 bytes` | refutada: os quatro funcionam |
| 2 | pacotes cheios se perdem a caminho do caixa | `tcpdump` no lado do escritório de `hq` durante o download | segmentos de 1448 bytes enviados, nenhum dado confirmado em nove pacotes | sustentada |
| 3 | o MTU do túnel é menor que esses pacotes | pings com Don't Fragment a partir de `files`; `ip link show wg0` | 1392 atravessa, 1400 se perde; `mtu 1420` | confirmada |
| 4 | o "fragmentation needed" de `hq` nunca chega a `files` | a estatística do ping de 1400; `nft list ruleset` em `hq` | nenhum `+1 errors`; uma regra descarta destination unreachable na saída | confirmada |

## Causa

Duas condições juntas, nenhuma suficiente sozinha. O túnel leva pacotes de no máximo 1420 bytes enquanto
a rede do escritório manda 1500. E a descoberta do MTU do caminho, que normalmente encolheria os pacotes
do emissor, depende de uma mensagem ICMP que `hq` monta e depois descarta na própria saída. **A primeira
condição é normal em qualquer túnel; a segunda a transforma num buraco negro.**

## Correção e conferência

Duas regras do nftables em `hq` reescrevem o MSS de todo SYN que passa pelo `wg0` para 1380, o MTU do
túnel menos 40 bytes de cabeçalho IP e TCP. Conferido com o teste que encontrou a falha:

```
ana@till:~$ curl -sS -m 30 -o /dev/null -w "%{http_code} %{size_download} bytes\n" http://192.168.10.10/big.bin
200 20000000 bytes
```

## O que continua aberto

A correção só cobre o TCP, e a regra `hardening` continua descartando todo destination unreachable que
`hq` envia. As quatro ações da seção anterior são a última parte deste registro: estreitar a regra,
tornar o clamping padrão em todo túnel, monitorar uma transferência grande e verificar os outros
roteadores.

## O que ajudou, e o que escondeu

**A página pequena funcionando fez o máximo com o mínimo**: um comando descartou quatro suspeitos. **O
silêncio foi a parte difícil**, já que nada em tela nenhuma dizia "grande demais", e a pista era a
ausência de `+1 errors` numa linha de estatística. Isso merece uma linha no registro, porque a próxima
pessoa vai estar olhando para o mesmo silêncio.
