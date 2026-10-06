---
title: Duas perguntas
version: 1
---

As pessoas dizem "login" para tudo o que acontece entre digitar a senha e ver uma página, e quem
trabalha com segurança diz **autenticação** e **autorização**, muitas vezes abreviadas como authN e
authZ, que se parecem na escrita e no som. Elas respondem a perguntas diferentes, e confundi-las está
por trás de uma das falhas mais comuns em software.

| | pergunta | no portal da loja | respondida por |
|---|---|---|---|
| **identificação** | quem você diz ser? | "sou a ana" | um nome de usuário |
| **autenticação** | consegue provar? | a senha que só a ana sabe | uma senha, um segundo fator, uma chave |
| **autorização** | o que você pode fazer? | a ana pode ler o próprio holerite | as regras do portal |
| **contabilização** (*accounting*) | o que você fez? | a ana leu o holerite, e quando | o log |

As quatro juntas se chamam **AAA**, de *authentication*, *authorization* e *accounting*, com a
identificação embutida na primeira.

**Identificação** é só uma alegação. Digitar "ana" não prova nada; qualquer um digita.

**Autenticação** confere a alegação contra algo que só a ana verdadeira deveria ter. A aula 9 trata
dos três tipos de evidência e de por que um deles raramente basta.

**Autorização** acontece depois da autenticação e usa o resultado dela. Saber com certeza que o
pedido vem da ana ainda não diz nada sobre se a ana pode ler o holerite do bruno; essa é uma decisão
separada, tomada por regras sobre o que o papel, a posse ou a situação da ana permitem.

**Contabilização** registra o que uma identidade autenticada fez, para que a responsabilização da aula
1 seja possível. O log do portal, que apareceu nas aulas 4 e 7, é a contabilização dele.

### Por que a ordem importa

A autorização precisa da autenticação antes, porque uma regra como "uma pessoa pode ler o próprio
holerite" não quer dizer nada até o sistema saber quem é a pessoa. O contrário não vale: uma
autenticação bem-sucedida não concede nada sozinha. **Ser alguém não é permissão para fazer algo.**

O erro de que esta aula trata é um sistema que para no primeiro passo: confere que o usuário está
logado e depois serve o que ele pedir. Todo usuário logado passa então a ler os dados de todo outro
usuário mudando um número ou um nome no endereço. As duas próximas seções mostram o portal fazendo
direito, primeiro de fora e depois no código.
