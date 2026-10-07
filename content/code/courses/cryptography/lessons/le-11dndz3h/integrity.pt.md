---
title: Um checksum que qualquer um recalcula não prova nada
version: 1
---

**Integridade contra acidentes e integridade contra um adversário são propriedades diferentes.** Um
checksum pega um cabo que inverteu um bit. Ele não pega uma pessoa que alterou a mensagem, porque
essa pessoa também consegue recalcular o checksum. Esta aula trata do segundo tipo, e começa
mostrando por que o primeiro não basta.

## Um aviso de pagamento, e um hash ao lado

O portal da Vereda fica sabendo que um paciente pagou por uma mensagem do seu gateway de pagamento,
um pequeno JSON:

```
ana@lab:~/lab$ cat data/webhooks/evt-1.json; echo
{"event":"payment.confirmed","booking":4471,"amount":12000}
```

Suponha que o gateway mandasse o SHA-256 junto, para o portal conferir que nada foi alterado:

```
ana@lab:~/lab$ sha256sum data/webhooks/evt-1.json
29907c15a04982fb68cfa1836a41d97f53f33fb3b0fdef9c3b67077e560729bd  data/webhooks/evt-1.json
```

Agora alguém entre o gateway e o portal muda o valor de 12000 centavos para 120 e recalcula o
resumo:

```
ana@lab:~/lab$ sed 's/12000/120/' data/webhooks/evt-1.json > forged.json; sha256sum forged.json
4f9653ccf5a9c5a2474a9bb3b437fdda1c8d7ef322d2dfada0a3938f0f4bcebf  forged.json
```

O portal recebe um corpo e um resumo que batem perfeitamente entre si. A aula 4 disse isso em
geral: **um hash não tem chave, então quem consegue alterar a mensagem consegue alterar o hash.** O
resumo prova que o corpo não foi danificado depois que o resumo foi calculado. Não diz nada sobre
quem o calculou.

## Do que o portal precisa de fato

Duas propriedades, que andam juntas na prática:

- **integridade contra um adversário**: se alguém alterou a mensagem, a verificação falha;
- **autenticidade da origem**: a verificação só pode ter sido produzida pelo gateway.

As duas precisam de algo que o atacante não tem, o que significa uma chave. Há dois jeitos de usar
uma:

| | chave secreta compartilhada | par de chaves |
|---|---|---|
| mecanismo | **MAC**, na prática HMAC | **assinatura digital**, aula 3 |
| quem consegue produzir a verificação | qualquer um com a chave compartilhada | só quem tem a chave privada |
| quem consegue verificá-la | qualquer um com a chave compartilhada | qualquer um com a chave pública |
| prova a um terceiro quem enviou | não: qualquer um dos lados poderia tê-la feito | sim: não repúdio |
| custo | microssegundos | bem mais lenta, e exige confiar numa chave pública |

O gateway e a Vereda já compartilham um segredo, emitido quando a Vereda abriu a conta, então o
gateway usa a coluna da esquerda. Uma versão de software, conferida por milhares de pessoas que não
compartilham nada com o autor, usa a da direita. As próximas três seções tratam delas nessa ordem.
