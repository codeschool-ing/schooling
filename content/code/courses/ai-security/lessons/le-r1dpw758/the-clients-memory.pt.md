---
title: O cliente pode vê-la e apagá-la
version: 1
---

Uma memória é sobre um cliente, então o cliente tem voz nela. Pela LGPD, assunto da aula 12, uma
pessoa pode perguntar que dados são guardados sobre ela e pedir que sejam corrigidos ou apagados. Numa
memória isso significa duas coisas que a aplicação precisa ter desde o primeiro dia: **mostrar ao
cliente o que o assistente lembra, em palavras simples, e apagar qualquer linha a pedido dele.**

O `show` já é a primeira, porque imprime o que o assistente usaria. O `forget` é a segunda:

```
ana@lab:~/guard$ guard memory forget m4 --as ac-7Q2M
forgot m4 for ac-7Q2M
ana@lab:~/guard$ guard memory show --as ac-7Q2M --now 2026-07-01
ac-7Q2M on 2026-07-01, memories in use: 1
  m2  preference until 2027-03-02  dark blue logo color
ana@lab:~/guard$ guard memory forget m4 --as ac-7Q2M; echo "exit status $?"
memory: ac-7Q2M has no memory m4
exit status 1
```

A memória sobre as atualizações semanais sumiu, e pedir para esquecê-la de novo falha com uma mensagem
e status de saída 1, em vez de alegar uma exclusão que não aconteceu. Uma tela que diz "esquecido"
aconteça o que acontecer é uma tela que mente no dia em que importa.

## Esquecer alcança cada cópia

Uma memória é escrita num lugar e copiada para outros. Apagar a linha no depósito não remove:

- **a conversa de onde ela veio**, que fica no log de chamadas da aula 11, sob a retenção do próprio
  log;
- **os prompts já enviados com ela**, que o fornecedor guarda nos termos que a aula 12 examinou;
- **tudo o que foi derivado dela**, como um resumo do cliente escrito para a equipe.

Um botão de "esquecer" honesto diz o que apaga e o que não consegue apagar. Um pedido para apagar tudo
sobre uma pessoa é uma operação diferente e maior, e o depósito de memórias é um dos lugares que ela
precisa alcançar, o que é um motivo para manter o depósito simples o bastante para achar uma pessoa
nele.

## Uma memória é texto que o cliente escreveu

Quando o assistente recupera uma memória, o texto dela volta para um prompt. **Esse texto veio das
mensagens do cliente, passando pelo modelo**, então, nos termos da aula 13, ele carrega texto do
cliente, esteja guardado onde estiver. Ele recebe o tratamento que a aula 14 deu a esse tipo de texto:
curto, num formato fechado, e lido por um modelo que responde, e não por um que age. O limite de 120
caracteres no esquema faz parte disso, e também a ausência de qualquer tipo que guarde uma instrução.
Uma memória diz algo sobre o cliente. Ela nunca diz ao assistente o que fazer.
