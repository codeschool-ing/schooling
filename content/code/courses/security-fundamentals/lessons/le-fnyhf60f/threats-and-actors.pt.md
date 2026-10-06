---
title: De onde vêm as ameaças
version: 1
---

Quando as pessoas imaginam uma ameaça, imaginam um hacker de moletom. Essa imagem deixa de fora a
maioria das ameaças que um pequeno negócio de fato encontra. **Ameaças vêm de três fontes, e a
intencional nem sempre é a maior.**

| fonte | exemplos na livraria | o que defende contra ela |
|---|---|---|
| **natural** ou ambiental | enchente, incêndio, onda de calor, queda de energia | localização, energia de reserva, cópias fora do local |
| **acidental** | uma pasta apagada, um preço errado importado, um notebook esquecido no ônibus | treinamento, backups, revisão de mudanças |
| **intencional** | um criminoso, um fraudador, um ex-funcionário com raiva | a maior parte deste curso |

A linha acidental merece mais respeito do que recebe. Um erro não tem intenção por trás, então ele
nunca desiste, nunca se cansa e nunca se intimida com a ideia de ser pego. Uma política de backup
desenhada só contra atacantes ainda falha no dia em que alguém apaga a pasta errada e ninguém
percebe por um mês.

### As intencionais: agentes de ameaça

A pessoa ou o grupo por trás de uma ameaça intencional é um **agente de ameaça** (*threat actor*).
Eles diferem no que querem e no que conseguem fazer, e essas duas diferenças importam mais que o
nome:

| agente | quer | capacidade típica |
|---|---|---|
| criminoso oportunista | dinheiro, de quem for mais fácil | ferramentas automáticas apontadas para a internet inteira |
| crime organizado | dinheiro em escala: ransomware, fraude | habilidoso, financiado, paciente |
| insider (alguém de dentro) | vingança, dinheiro, ou nada (um funcionário descuidado) | já tem acesso, e esse é o perigo |
| hacktivista | atenção para uma causa | pichação de sites, vazamentos, enxurradas de tráfego |
| Estado-nação | inteligência, sabotagem | o mais capaz, e raramente interessado numa livraria |

**O adversário realista da livraria é a primeira linha.** Ninguém mira uma livraria de nove pessoas
pelo nome; ferramentas automáticas varrem a internet atrás de qualquer página de login com senha
padrão e de qualquer servidor sem patch, e a loja simplesmente está na internet. Isso muda a
defesa: contra um oportunista, ser um pouco mais difícil que a média basta, porque ele passa para
um alvo mais fácil. Contra um agente determinado não basta, e a aula 4 explica por que as camadas
importam nesse caso.

A linha do insider é a desconfortável. Nove pessoas já têm contas, chaves e a confiança dos
colegas. A maioria dos incidentes de insider é descuido, e não malícia, e os controles são os
mesmos nos dois casos: dar a cada pessoa só o que o trabalho dela pede (aula 6) e registrar quem
fez o quê (a responsabilização da aula 1).

Um **vetor de ameaça**, ou vetor de ataque, é o caminho que uma ameaça usa para chegar ao ativo:
e-mail, uma página web pública, um pen drive, um telefonema para o suporte. Listar os vetores que
chegam a um ativo é como um defensor descobre onde pôr controles. O `attacks-threats` percorre os
vetores intencionais um a um; este curso só precisa da ideia de que eles existem.
