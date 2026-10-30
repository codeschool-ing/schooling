---
title: Quanto custa uma ressincronização, e quando ela sai mais barata
version: 1
---

**Uma ressincronização custa um download do tamanho de todo o dado da pessoa, uma vez; um delta
custa o tamanho das mudanças, toda vez. Então uma ressincronização sai mais barata exatamente quando
as mudanças desde o cursor seriam maiores que o dado, ou nem podem ser conhecidas.** O 410 é o
segundo caso. O primeiro merece medição, porque é onde um servidor pode decidir mandar um snapshot
mesmo ainda tendo o histórico.

## Medido

Reinicie o servidor, dê a ele mais duas mil sessões e deixe o aparelho alcançá-lo por delta. Depois
apague uma sessão em outro celular, faça o servidor esquecer e busque:

```
ana@dev:~/planner/resync$ rm planner.db
ana@dev:~/planner/resync$ curl -s -X POST 'http://127.0.0.1:8012/fill?n=2000'; echo
{"seq":2006}
ana@dev:~/planner/resync$ node device.ts pull
delta: 2006 changes, cursor 2006
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -o /dev/null -X POST http://127.0.0.1:8012/forget
ana@dev:~/planner/resync$ node device.ts pull
410: cursor 2006 is older than 2007; resync
snapshot: 2005 sessions, 155594 bytes; 0 pending carried over
ana@dev:~/planner/resync$ stat -c '%s bytes' planner.db
131072 bytes
```

O primeiro delta, a partir de um aparelho vazio, trouxe 2006 mudanças, porque um aparelho vazio tem
tudo a aprender. Depois do esquecimento, a ressincronização baixou 2005 sessões em 155.594 bytes e
gravou um arquivo de banco de 131.072 bytes. O delta que ela substituiu teria sido uma lápide, pouco
mais de cem bytes, se o servidor ainda a tivesse.

Essa proporção, mil para um, é por que uma ressincronização é a exceção. É também por que um
servidor define a janela de lápides pelos celulares que atende e não pelo próprio disco: trinta dias
de lápides custam ao servidor algumas linhas por delete, e todo celular que cai fora da janela custa
um download completo.

## Quando o servidor deve escolhê-la

Um servidor que ainda tem o histórico pode mesmo assim responder com um snapshot quando:

- **o histórico desde o cursor é mais longo que o dado**: um celular um ano atrasado num planner que
  reescreveu metade das sessões no mês passado;
- **o histórico é caro de calcular**: milhares de mudanças pequenas em linhas que hoje guardam um
  valor cada, em que o snapshot é a compactação que a aula 8 fez no aparelho;
- **o formato do servidor mudou**, e repetir mudanças antigas no formato antigo exigiria código que
  ninguém quer manter.

Para o aparelho o conselho é mais curto: **esteja pronto para uma ressincronização em qualquer
busca**, guarde a caixa de saída através dela e faça do rename o único momento em que o dado da tela
muda de origem. A aula 16 faz a última pergunta que esta deixa: quando, num celular, um download de
cento e cinquenta kilobytes pode rodar.
