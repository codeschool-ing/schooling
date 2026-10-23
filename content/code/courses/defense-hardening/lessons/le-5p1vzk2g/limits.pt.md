---
title: O que um scanner não consegue ver
version: 1
---

**O antivírus responde a uma pergunta: este arquivo é um que reconhecemos como ruim?** Tudo o que ele
faz bem decorre dessa pergunta, e tudo o que ele deixa passar também. Quem defende e conhece o que
passa consegue pôr outros controles nesses lugares, que é o assunto do resto deste curso.

## Quatro lacunas

**O novo.** Uma assinatura só existe depois que alguém viu o arquivo, julgou e distribuiu a
descrição. As primeiras horas de qualquer coisa nova passam antes disso, e passa também qualquer coisa
feita para um alvo só, que nenhum fabricante chega a ver. As heurísticas estreitam essa lacuna e não a
fecham.

**O modificado.** A seção de hash mostrou isso com um espaço: uma descrição exata falha no primeiro
byte de diferença. Regras de conteúdo e heurísticas seguem variantes mais longe, ao custo dos falsos
positivos das próprias seções.

**O sem arquivo.** Algumas intrusões nunca gravam um programa no disco. Usam o que já está instalado,
um shell, uma linguagem de script, uma ferramenta de administrador, e os comandos que rodam vivem na
memória e na linha de comando. Um scanner de arquivos não tem arquivo para examinar. É para essa
lacuna que o EDR existe, e a aula 8 é construída sobre ela.

**O legítimo.** Um invasor que entra com uma senha roubada e roda as ferramentas do próprio escritório
não faz nada que um scanner possa chamar de malicioso, porque nada é. Os controles para isso são as
contas e os acessos das aulas 1, 6 e 15, e o inventário da aula 18.

## O que isso faz do antivírus

Não algo inútil: ele barra o volume enorme de malware conhecido e em circulação, barato, em toda
máquina, e esse volume é a maior parte do que chega a um escritório pequeno. **É um piso, não um
muro.** Um scanner dizendo "limpo" afirma que o arquivo não casa com nada que o fabricante descreveu,
o que diz tanto sobre o conhecimento do fabricante quanto sobre o arquivo.

Então ele é medido como qualquer outro controle deste curso. Teste-o com o arquivo EICAR depois de
cada mudança no gateway de e-mail ou na política do endpoint, como esta aula fez, e acompanhe a idade
das assinaturas. E ponha as próximas camadas onde estão as lacunas dele: um host que roda só o que
deve (aulas 1 e 12), um registro do que os programas de fato fazem (aula 8) e um inventário que sabe o
que pertence ali (aula 18).
