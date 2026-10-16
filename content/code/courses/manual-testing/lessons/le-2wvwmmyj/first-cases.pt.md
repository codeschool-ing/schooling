---
title: Escrevendo os primeiros casos
version: 1
---

Esta seção escreve os casos que a seção 03 citou para cadastro, confirmação e reserva. Cada um foi
escrito do jeito que a seção 02 manda: **o resultado esperado primeiro, a partir do requisito, com a
aplicação parada.** Leia-os pela forma antes do conteúdo. Toda pré-condição diz só aquilo de que o
resultado depende, todo passo é uma ação, e todo resultado esperado pode ser conferido olhando a
tela.

O TC-BOOK-01 é o caso que a seção 02 usou de exemplo, então não se repete aqui.

## Cadastro

| campo | TC-SIGNUP-01 |
|---|---|
| título | Uma conta é criada com nome, e-mail e senha válidos |
| requisito | R2, R3 |
| pré-condição | O boxoffice 1.0 está rodando. Nenhuma conta usa `ana@example.org`; uma inicialização limpa tem só `member@example.org`. |
| dados de teste | nome `Ana Lima`; e-mail `ana@example.org`; senha `boxoffice-2026` |
| passos | 1. Abra `http://127.0.0.1:8000/signup`. 2. Digite o nome em Name. 3. Digite o e-mail em E-mail. 4. Digite a senha em Password. 5. Clique em Create account. |
| resultado esperado | Uma página com o título Account created diz que um link foi enviado para `ana@example.org`. A caixa de saída mostra um e-mail novo, Confirm your account, endereçado a `ana@example.org`. |

| campo | TC-SIGNUP-02 |
|---|---|
| título | Um endereço de e-mail que já tem conta é recusado |
| requisito | R2, R7 |
| pré-condição | O boxoffice 1.0 está rodando. A conta `member@example.org` existe; uma inicialização limpa a tem. |
| dados de teste | nome `Ana Lima`; e-mail `member@example.org`; senha `boxoffice-2026` |
| passos | 1. Abra `http://127.0.0.1:8000/signup`. 2. Digite o nome em Name. 3. Digite o e-mail em E-mail. 4. Digite a senha em Password. 5. Clique em Create account. |
| resultado esperado | O formulário de cadastro volta com uma frase dizendo que o e-mail já tem conta. Nenhum e-mail é enviado: a caixa de saída não tem nada novo. |

O TC-SIGNUP-01 também aponta para o R3, além do R2, porque o R3 é a linha que promete o e-mail. A
conta ser criada é só metade do que o teatro pediu, e **a metade que o cliente percebe é o e-mail
que nunca chegou**.

O resultado esperado do segundo caso confere que algo não aconteceu. Uma recusa na tela é fácil de
ver; uma recusa na tela enquanto um e-mail saiu mesmo assim é o defeito que importa, e o único jeito
de pegá-lo é o caso dizer onde olhar.

Todos os endereços terminam em `example.org`. Esse domínio é reservado para documentação e
exemplos, então nenhuma pessoa real recebe uma mensagem enviada para ele, e um e-mail de teste que
escapa de um ambiente de teste por engano não vai a lugar nenhum.

## Confirmação

| campo | TC-CONFIRM-01 |
|---|---|
| título | O link do e-mail de confirmação confirma a conta |
| requisito | R3 |
| pré-condição | O TC-SIGNUP-01 passou, e `ana@example.org` não foi confirmada desde então. |
| dados de teste | o link do e-mail Confirm your account, endereçado a `ana@example.org` |
| passos | 1. Abra `http://127.0.0.1:8000/outbox`. 2. No e-mail mais novo endereçado a `ana@example.org`, abra o link. |
| resultado esperado | Uma página com o título Confirm diz que a conta está confirmada. |

| campo | TC-CONFIRM-02 |
|---|---|
| título | Um link de confirmação que nunca foi enviado é recusado |
| requisito | R3, R7 |
| pré-condição | O boxoffice 1.0 está rodando. |
| dados de teste | o endereço `http://127.0.0.1:8000/confirm?token=nottherealone` |
| passos | 1. Abra o endereço. |
| resultado esperado | Uma página com o título Confirm diz que o link não é válido. |

O TC-CONFIRM-01 tem outro caso como pré-condição. É uma escolha com custo. É realista, porque
ninguém confirma uma conta que nunca foi criada, e poupa escrever o cadastro de novo. Em troca,
**se o TC-SIGNUP-01 falhar, o TC-CONFIRM-01 nem chega a rodar**, e a seção 05 desta aula diz qual é
o status dele nesse caso.

O resultado esperado dele é mais fraco do que parece. *A conta está confirmada* é uma frase numa
página, e a página poderia dizê-la sem que nada tivesse mudado. A prova é o desconto de membro, que
só uma conta confirmada recebe, e esse é o trabalho do último caso abaixo.

## Reserva

| campo | TC-BOOK-02 |
|---|---|
| título | Quem não tem conta não consegue reservar |
| requisito | R4, R7 |
| pré-condição | O boxoffice 1.0 está rodando. Nenhuma conta usa `nobody@example.org`. |
| dados de teste | e-mail `nobody@example.org`; espetáculo Hamlet; 2 ingressos; Student desmarcado |
| passos | 1. Abra `http://127.0.0.1:8000/book`. 2. Digite o e-mail no campo E-mail. 3. Escolha Hamlet em Show. 4. Digite `2` no campo de ingressos. 5. Clique em Book. |
| resultado esperado | O formulário de reserva volta com uma frase pedindo para se cadastrar antes. Nenhum pedido é feito: os lugares livres de Hamlet continuam os mesmos de antes. |

| campo | TC-BOOK-03 |
|---|---|
| título | Uma conta confirmada hoje reserva com preço de membro |
| requisito | R3, R4, R5 |
| pré-condição | O TC-CONFIRM-01 passou. The Little Prince tem 200 lugares livres. |
| dados de teste | e-mail `ana@example.org`; espetáculo The Little Prince; 2 ingressos; Student desmarcado |
| passos | 1. Abra `http://127.0.0.1:8000/book`. 2. Digite o e-mail no campo E-mail. 3. Escolha The Little Prince em Show. 4. Digite `2` no campo de ingressos. 5. Clique em Book. |
| resultado esperado | Um pedido fica reservado, com 2 ingressos para The Little Prince e 10% de desconto, R$ 54,00 no total, no estado reserved. A página Shows mostra 198 lugares livres para The Little Prince. |

O cálculo do TC-BOOK-03 é o do R5, feito antes da execução: dois ingressos a R$ 30,00 são R$ 60,00,
e 10% a menos dá R$ 54,00. Se a confirmação do TC-CONFIRM-01 só tivesse exibido uma frase sem mudar
nada, este caso mostraria 0% de desconto e R$ 60,00, e falharia.

**Dois ingressos em toda reserva é de propósito.** Dois está dentro da faixa de 1 a 6 do R4 e
abaixo dos cinco ingressos a partir dos quais começa o desconto de grupo do R5, então estes casos
conferem a reserva e o desconto de membro e mais nada. As quantidades perto das bordas da faixa, e o
pedido de cinco ou mais, são onde as aulas 4 e 5 gastam o seu tempo.

## O que eles têm em comum

Seis casos, mais o TC-BOOK-01, e cada um cabe numa tela. Nenhum diz *confira se funciona* ou
*verifique se a página está correta*, porque nenhuma das duas frases diz para onde olhar. A aula 3
é uma aula inteira sobre as palavras que fazem isso, e sobre o que escrever no lugar delas.
