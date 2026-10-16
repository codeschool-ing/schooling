---
title: Dizer o que se sabe, num horário marcado
version: 1
---

As pessoas afetadas por um incidente (clientes, suporte, o resto da empresa) precisam de três coisas,
e precisam delas **cedo e repetidamente**, não completas:

- **O que se sabe**, nas palavras que elas usam: "não foi possível fazer pedidos", não "a chave de
  líder expirou".
- **O que está sendo feito**, e o que isso significa para elas.
- **Quando vão ter notícias de novo**, como um horário, e então elas têm notícias nesse horário mesmo
  que a notícia seja "nada mudou".

Uma primeira mensagem, em minutos, com os fatos acima, fica assim:

```localised
14:05  No momento não é possível fazer pedidos no shop. Estamos investigando.
       Pedidos já feitos não foram afetados. Próxima atualização até 14:20.
```

e uma atualização, quando a causa é conhecida:

```localised
14:18  O servidor de banco de dados principal falhou às 13:58 e um standby assumiu
       às 13:59. Pedidos feitos entre 13:58 e 13:59 podem ter falhado; clientes que
       viram um erro devem fazer o pedido de novo. O shop está funcionando
       normalmente. Próxima atualização até 15:00, ou antes, se algo mudar.
```

Três regras tornam essas mensagens confiáveis. **Nunca chute uma causa em público**: "investigando" é
honesto, e uma causa errada precisa ser desmentida. **Nunca prometa um tempo de recuperação** que
ninguém mediu; o RTO da lição 8 é o medido, se houver um. E **diga quando vem a próxima atualização, e
cumpra o horário**, porque silêncio durante um incidente é lido como incompetência ou como algo pior.

A nota corrente interna é a outra metade: uma linha por ação ou observação, com a hora, mantida pelo
líder do incidente enquanto tudo acontece. Custa segundos por linha, e é a única fonte para a próxima
seção que não depende da memória de ninguém às quatro da manhã.
