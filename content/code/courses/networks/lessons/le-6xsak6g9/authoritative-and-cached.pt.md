---
title: A fonte, e uma cópia dela
version: 1
---

Há dois tipos de servidor de DNS, e eles respondem de jeitos diferentes. A mesma pergunta a cada um:

```
ana@laptop:~$ dig @ns1.example.com www.example.com +norecurse +noall +comments +answer | grep -E "flags|IN"
;; flags: qr aa; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2
; EDNS: version: 0, flags:; udp: 1232
www.example.com.        300     IN      A       192.0.2.80
ana@laptop:~$ dig www.example.com +noall +comments +answer | grep -E "flags|IN"
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
; EDNS: version: 0, flags:; udp: 1232
www.example.com.        299     IN      A       192.0.2.80
```

**O `aa`, *authoritative answer*, resposta autoritativa, aparece só na primeira**: o `ns1.example.com`
tem o arquivo da zona e é a fonte. A resposta do resolver tem `rd ra` e nenhum `aa`: ele está
repetindo algo que lhe disseram. E o TTL dele é **299, não 300**. O resolver está contando para trás.

```
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        299     IN      A       192.0.2.80
ana@laptop:~$ dig +noall +answer www.example.com
www.example.com.        294     IN      A       192.0.2.80
```

Cinco segundos depois, 294. **O TTL é quanto tempo qualquer um pode guardar a resposta antes de
perguntar de novo**, e quem o definiu foi o dono do domínio, no arquivo da zona. Quando chega a zero, o
resolver esquece o registro, e a próxima pergunta vai até o `ns1` de novo.

O cache é o motivo de o DNS ser rápido: o `dig` do laptop respondeu em `0 msec` porque o resolver já
tinha a resposta. É também o motivo de uma mudança no DNS nunca ser instantânea, que é a próxima seção.

Na maioria dos sistemas, o próprio laptop também guarda um cache: o `systemd-resolved` num Linux de
desktop, o serviço Cliente DNS no Windows, o `mDNSResponder` no Mac. O laptop do laboratório não tem
nenhum, então toda pergunta aqui foi ao resolver.
