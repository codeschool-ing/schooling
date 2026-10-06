---
title: Três tipos de evidência
version: 1
---

A aula 8 chamou a autenticação de provar uma alegação. Só existem três tipos de evidência que uma
pessoa pode oferecer, e eles se chamam **fatores**:

| fator | o que é | exemplos | como se perde |
|---|---|---|---|
| **algo que você sabe** | um segredo na cabeça | uma senha, um PIN, a resposta a uma pergunta de segurança | phishing, reuso num site vazado, adivinhação, alguém olhando por cima do ombro |
| **algo que você tem** | um objeto em sua posse | um celular com app autenticador, uma chave de segurança, um cartão inteligente | roubo, perda, troca de chip (*SIM swap*) |
| **algo que você é** | uma característica do corpo | uma digital, um rosto, uma voz | difícil de trocar depois de copiado |

**Autenticação multifator (MFA)** pede evidência de **mais de um tipo**. **Autenticação de dois fatores
(2FA)** é o caso mais comum: exatamente dois. O ponto está na palavra *tipo*. Cada tipo se perde de um
jeito, então um atacante que tem um, a senha da ana de um site vazado, ainda não tem o outro, o celular
no bolso dela. É a independência de camadas da aula 4, aplicada a um login.

### O que não conta

**Duas senhas são um fator só.** Uma senha e uma pergunta de segurança ("nome de solteira da sua mãe")
são as duas algo que você sabe, e as duas se perdem do mesmo jeito: uma página de phishing pede as duas,
e um pesquisador acha a segunda nas redes sociais. O login fica mais longo, e não mais forte em tipo.

**Um código mandado para o seu e-mail é um "algo que você tem" fraco.** Ele prova que você consegue ler
a caixa de e-mail, e se ela usa a mesma senha da conta, as duas caem juntas.

**Localização e comportamento são sinais, não fatores.** "O pedido vem do Brasil" ou "ela digita na
velocidade de sempre" podem subir ou baixar a suspeita, como fazem as decisões Zero Trust da aula 7, mas
ninguém prova quem é por estar em algum lugar.

### Por que importa tanto

A maioria das tomadas de conta começa com uma senha que o atacante já tem: reaproveitada do vazamento
de outro site, adivinhada, ou digitada pela vítima numa página de login falsa. A Microsoft relatou em
2019 que o MFA teria bloqueado mais de 99,9% dos ataques de comprometimento de conta que ela viu. O
número exato depende do que se conta, e a direção não deixa dúvida: **um segundo fator transforma uma
senha roubada num vazamento em um login que falha.**

É também por isso que ele é o primeiro passo da ordem Zero Trust da aula 7, e a primeira mitigação do
R1 da loja na aula 3: a senha do portal deixa de ser a fechadura inteira.
