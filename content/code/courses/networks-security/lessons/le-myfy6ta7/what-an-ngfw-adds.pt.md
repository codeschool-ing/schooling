---
title: O que mais um firewall de nova geração traz junto
version: 1
---

"Próxima geração" é um termo de marketing, e cobre vários recursos sem relação entre si vendidos numa
caixa só. Vale reconhecer cada um pelo que ele faz de fato:

| recurso | o que faz | onde este curso cobre o mecanismo |
|---|---|---|
| identificação de aplicação | nomeia o protocolo pela carga útil | esta aula |
| identidade do usuário | liga um endereço a uma pessoa autenticada, para uma regra poder dizer "financeiro" em vez de uma sub-rede | aula 22 |
| prevenção de intrusão | descarta tráfego que casa com a assinatura de um ataque conhecido | aulas 14 e 15 |
| filtragem de URL e de categoria | permite ou bloqueia pela categoria do site, a partir do SNI ou do host HTTP | aula 9 |
| inspeção de TLS | descriptografa para ler o conteúdo | esta aula |
| feeds de inteligência de ameaças | bloqueiam endereços e nomes que um fornecedor viu se comportarem mal | aula 23 |
| sandboxing | roda arquivos baixados num lugar seguro para observar o que fazem | aula 9 |

**Cada item custa vazão.** Um firewall que só casa cabeçalhos encaminha perto da velocidade do seu
hardware. Cada recurso que lê cargas úteis é software trabalhando por pacote, e os fornecedores
informam um número de vazão separado, menor, com a inspeção ligada. Dimensionar um firewall pelo
número de destaque e depois ligar todos os recursos é o jeito comum de descobrir isso.

## Onde ele fica

Um NGFW pertence ao ponto onde o tráfego que vale a pena ler cruza uma fronteira: a borda com a
internet, e entre zonas de confiança diferente (aula 4). Ele é a ferramenta errada no fundo de um
data center, onde o volume é maior e a maioria dos fluxos é entre máquinas que já confiam umas nas
outras; a aula 21 cuida disso com regras nas próprias máquinas.

**As camadas se somam**: o filtro sem estado da aula 1 na borda joga fora o que
nunca pode ser legítimo, o firewall com estado decide quais conversas podem existir, e o motor de
inspeção lê as poucas que interessam à política.
