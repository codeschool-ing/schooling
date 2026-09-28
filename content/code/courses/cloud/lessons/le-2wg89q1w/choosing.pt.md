---
title: "Escolhendo: controle, trabalho e a porta de saída"
version: 1
---

Não existe modelo melhor, e a crença de que existe, em geral "serverless é o futuro" ou "engenheiro de
verdade roda as próprias máquinas", é o que vale deixar para trás. **Cada degrau acima na linha tira
trabalho e tira controle, e tira os dois juntos, fileira por fileira.** A escolha é quais fileiras você
precisa manter. Três perguntas decidem.

## Que fileiras você precisa controlar?

Suba pela pilha e pergunte, de cada fileira, se alguma coisa no seu sistema precisa que ela seja sua.

Um programa que precisa de um sistema operacional específico, de um ajuste de kernel, de um pacote de
sistema que nenhuma plataforma instala, ou de um processo que roda por dias precisa da fileira do sistema
operacional, e isso quer dizer IaaS. Uma aplicação web comum, numa linguagem suportada, não precisa de
nada abaixo do próprio código, e uma plataforma a roda. Uma tarefa que é igual para todo negócio, como
e-mail, agenda, helpdesk ou uma loja padrão, não precisa de nenhuma fileira abaixo dos dados, e um
produto pronto a resolve.

**Se você não consegue citar um motivo para manter uma fileira, outra pessoa pode operá-la**, e
provavelmente já fez isso mais vezes do que você.

## O que você consegue levar junto?

Sair de um provedor é raro, mas o custo disso é decidido no dia em que você escolhe o modelo, não no dia
em que sai.

Em IaaS, uma máquina rodando Ubuntu, PostgreSQL e a sua aplicação roda do mesmo jeito em qualquer
provedor que alugue máquinas virtuais, e a lição 3 cita vários. Mudar dá trabalho, mas é o mesmo
trabalho em todo lugar. Em PaaS, uma aplicação escrita em convenções comuns, que escuta numa porta e lê
as configurações de variáveis de ambiente, muda com alterações modestas; os arquivos de build, os
complementos e os serviços próprios da plataforma precisam ser refeitos para a próxima. Em SaaS você
leva o que a exportação entrega e refaz todo o resto à mão.

Ficar preso a um provedor desse jeito se chama **lock-in**. Não é um defeito a evitar a qualquer preço:
um serviço gerenciado pode poupar mais trabalho do que uma mudança jamais custaria. É um preço, e sai
mais barato conhecê-lo antes de assinar.

## Para onde vai o custo?

Uma plataforma cobra pelas tarefas que faz. Por unidade de computação, uma plataforma ou um banco
gerenciado costuma custar mais que uma máquina virtual do mesmo tamanho, porque os patches, os reinícios
e os backups estão no preço. Pela tabela do curso, uma máquina pequena em São Paulo com um disco e um
endereço deu 18,95 dólares por mês. Esse número não tem hora de trabalho de ninguém dentro, e é no tempo
que está o resto do custo do IaaS.

**O custo sai das pessoas e vai para a conta.** Para três desenvolvedores sem ninguém que queira aplicar
patches em servidores, a conta mais alta da plataforma sai mais barata que as horas; para uma equipe com
alguém cujo trabalho é operar máquinas, e uma carga que quase não muda, máquinas virtuais podem custar
menos no total. A lição 10 trata de ler a conta; as horas ficam para você contar.

## Uma tabela curta

| se isto vale para o sistema | puxe para |
|---|---|
| a tarefa é uma que todo negócio tem: e-mail, documentos, uma loja padrão | SaaS |
| você escreveu a aplicação e ninguém quer operar servidores | PaaS, ou funções (lição 8) |
| ele precisa de sistema operacional próprio, pacotes de sistema ou processos longos | IaaS |
| ele precisa mudar de provedor com o mínimo de retrabalho | IaaS, com software que você rodaria em qualquer lugar |
| os dados dele precisam ficar no Brasil | qualquer modelo, de um provedor com região aqui (lição 9) |

A última linha está ali porque é outra pergunta. O modelo diz quem opera cada fileira; a **região** diz
onde as fileiras rodam, e as duas coisas se escolhem separadamente.

A maioria das empresas acaba com os três ao mesmo tempo, um por sistema, e esse é o resultado certo, não
uma incoerência. Trace a linha de cada sistema, anote quais fileiras são suas, e garanta que cada uma
tenha um nome ao lado.
