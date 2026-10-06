---
title: Acúmulo de privilégios
version: 1
---

O menor privilégio é fácil no dia em que uma conta é criada. A dificuldade é que **acesso é concedido por
motivos e quase nunca retirado quando os motivos acabam.** Uma pessoa cobre as férias de um colega e
fica com o acesso. Um projeto precisa de uma pasta compartilhada e o projeto termina. Alguém passa do
atendimento para o financeiro e chega ao financeiro com o acesso do atendimento ainda pendurado. Depois
de alguns anos, a pessoa mais antiga da empresa alcança quase tudo. Isso é **acúmulo de privilégios**
(*privilege creep*).

Ele é silencioso por natureza: nada quebra quando alguém tem acesso demais, então ninguém reclama. Ele
só aparece num incidente, quando o atacante que pegou a senha de uma pessoa antiga encontra as chaves de
tudo.

### Entradas, mudanças e saídas

A defesa começa tratando o acesso como parte de três eventos que toda organização já administra:

| evento | o que deveria acontecer com o acesso | o que costuma dar errado |
|---|---|---|
| **entrada** | o acesso padrão do cargo, desde o primeiro dia, nada mais | copiar o acesso de um colega "por garantia" |
| **mudança** | o acesso do cargo novo é concedido **e o do antigo é removido** | só a primeira metade acontece |
| **saída** | toda conta desativada no último dia, inclusive as compartilhadas | uma conta esquecida num serviço de que ninguém lembra |

A linha da saída é a de risco mais claro: a conta de alguém que não trabalha mais lá é uma conta que
ninguém está vigiando. A aula 2 listou "ninguém remove a conta quando um funcionário sai" como
vulnerabilidade de processo, e é aqui que ela se corrige.

### Revisões de acesso

A segunda defesa é periódica: uma **revisão de acesso**, em que o dono de cada sistema ou dado olha a
lista de quem o alcança e confirma ou remove cada linha. Quem revisa é o dono, não a TI, pelo mesmo
motivo que o dono do risco decide na aula 3: o bruno sabe se quem embala pedidos precisa da pasta do
financeiro; a ana não sabe.

### Privilégio permanente e temporário

Uma permissão sempre ligada se chama **privilégio permanente** (*standing privilege*). Para acesso
poderoso, o padrão mais seguro é o acesso **just-in-time**: concedido quando uma tarefa precisa, por
algumas horas, e removido automaticamente depois. Um administrador que precisa de `root` no `www` duas
vezes por mês não deveria tê-lo nos outros vinte e oito dias, porque uma senha roubada funciona nos
trinta.

A versão do dia a dia é simples e muito ignorada: **um administrador usa uma conta comum para trabalho
comum.** A ana lê e-mail e navega como usuária comum, e só sobe para direitos de administração para
administrar. Um malware que chega por e-mail roda então com as permissões de uma conta do dia a dia, e
não com as chaves da loja.
