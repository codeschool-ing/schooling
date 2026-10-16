---
title: Limites na porta
version: 1
---

As instâncias de estoque pediram ao gateway, pelas tags, para limitar cada cliente a cinco requisições por
segundo com rajada de cinco: o token bucket da aula 12, configurado em vez de escrito. Mande vinte
requisições o mais rápido que o `curl` conseguir, e conte as respostas:

```
ana@vm:~/lab/gateway$ for i in $(seq 20); do curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/stock/coffee; done | sort | uniq -c
      6 200
     14 429
```

Seis passaram, a rajada de cinco e mais uma ficha que pingou enquanto o `curl` rodava, e catorze foram
recusadas pelo gateway com `429`, sem nenhuma instância de estoque ser consultada. **Esse é o sentido de pôr o limite na porta**: um cliente que se comporta mal custa ao
gateway alguns microssegundos por requisição recusada, e não custa nada aos serviços.

Dois detalhes importam em produção. O gateway identifica "um cliente" por alguma coisa, aqui o endereço de
quem chama, o que está errado atrás de um proxy que faz todo cliente parecer um endereço só; uma
configuração de verdade limita por uma chave de API ou por um id de usuário vindo de um token conferido. E
com várias instâncias de gateway, cada uma guarda os próprios baldes a não ser que os compartilhem, no
Redis por exemplo, então cinco por segundo por instância em quatro instâncias são vinte por segundo, como a
aula 12 avisou.
