---
title: Vulnerabilidade não é só bug
version: 1
---

Pergunte a um programador o que é uma vulnerabilidade e a resposta vai ser um defeito no software.
Esse é um tipo, e é o tipo com o melhor catálogo. Está longe de ser o único, e **as
vulnerabilidades mais baratas de explorar raramente estão no código.**

| tipo | exemplo na livraria |
|---|---|
| software | o servidor web roda uma versão com uma falha conhecida e publicada |
| configuração | o portal ainda aceita a senha padrão de instalação |
| processo | ninguém remove a conta quando um funcionário sai |
| pessoas | ninguém explicou à equipe como é um e-mail de boleto falso |
| física | o servidor fica embaixo de uma mesa num escritório destrancado |

Vale a pena demorar na linha da configuração. O software pode ser perfeito e estar atualizado, e
uma senha padrão, uma pasta compartilhada com "todos" ou um banco escutando na internet o tornam
explorável sem defeito nenhum. A aula 16 trata de listas de verificação que pegam exatamente esse
tipo.

### O catálogo das falhas de software conhecidas

Vulnerabilidades de software que foram encontradas e divulgadas ganham um identificador na lista
**CVE**, *Common Vulnerabilities and Exposures*. Um identificador tem a cara de `CVE-2021-44228`: o
ano em que foi atribuído e um número de sequência. É um nome e nada mais, e existe para que o aviso
do fabricante, o relatório de um scanner e uma notícia possam dizer que falam da mesma falha.

A maioria dos CVEs traz uma nota **CVSS**, o *Common Vulnerability Scoring System*: um número de 0.0
a 10.0 que descreve, em geral, quão grave é a falha. As faixas são:

| nota | gravidade |
|---|---|
| 0.0 | nenhuma |
| 0.1 a 3.9 | baixa |
| 4.0 a 6.9 | média |
| 7.0 a 8.9 | alta |
| 9.0 a 10.0 | crítica |

O `CVE-2021-44228`, a falha na biblioteca de log Log4j conhecida como Log4Shell, tirou 10.0.

**Uma nota CVSS é gravidade, não risco.** Ela descreve a falha em abstrato, sem saber nada da sua
loja. Não tem como saber se o programa vulnerável é alcançável, se há algo valioso atrás dele ou se
um controle já bloqueia o caminho. Um 9.8 numa máquina sem rede e sem dados pode ser menos urgente
que um 6.5 na página de pagamento pública da loja. Vale a regra da seção anterior: uma
vulnerabilidade só é risco quando uma ameaça consegue alcançá-la e há um ativo atrás dela.

Uma vulnerabilidade que ninguém conhece ainda, nem o fabricante, é chamada de **dia zero**
(*zero-day*): o fabricante teve zero dias para corrigi-la. Não existe patch, então a defesa é todo
o resto deste curso: camadas, menor privilégio e detecção.
