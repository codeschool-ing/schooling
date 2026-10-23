---
title: O armazenamento que ninguém da TI configurou
version: 1
---

**A maior parte dos dados de empresa que vazam por armazenamento em nuvem não vaza da nuvem da
empresa. Vaza de uma conta que uma pessoa abriu com o próprio e-mail, num serviço que a empresa nunca
escolheu, para levar um arquivo de um lugar a outro.** Isso é *armazenamento paralelo* (*shadow
storage*), e esta aula trata dele.

A imagem errada é a de que é um problema de gente descuidada. As pessoas envolvidas normalmente
estão tentando ajudar: a bia quer mandar as consultas do mês para o contador da clínica, o anexo é
grande demais para o e-mail, e ela tem um Google Drive em casa. Em quatro minutos a planilha está no
ar, um link é copiado e o contador a recebe. Nada foi invadido e ninguém quebrou uma regra que
conhecesse.

## O que vai embora junto com o arquivo

A planilha em si é a parte pequena. O que a clínica perdeu nesses quatro minutos foi todo controle
que a aula 9 montou em volta do armazenamento dela:

| | o bucket da clínica | o Drive pessoal da bia |
|---|---|---|
| quem decide quem pode ler | a clínica, por políticas que ela consegue auditar | a bia, por um botão de compartilhar |
| um registro de quem leu | o que a clínica escolheu registrar (aula 15) | o que o Google mostrar à bia, e nada à clínica |
| o que acontece quando a bia sai | o acesso dela é revogado e o arquivo fica | o arquivo vai embora com ela |
| a quem se pede para apagar | aos administradores da própria clínica | à bia, se alguém lembrar de pedir |
| o scanner da aula 16 | o enxerga | não sabe que ele existe |

**A última linha é a que mais pesa.** Toda defesa deste curso começa por um inventário, e um arquivo
numa conta pessoal está fora de todo inventário que a clínica tem. Ninguém protege, audita ou apaga o
que ninguém sabe que existe.

## Por que isso pesa mais numa clínica

A planilha nomeia um paciente em cada linha, e a aula 17 do curso `security-fundamentals` mostrou que
a LGPD trata dado de saúde como dado pessoal *sensível*. A clínica continua controladora desses
dados onde quer que uma cópia vá parar. Então uma cópia numa conta pessoal continua sendo
responsabilidade da clínica, guardada num lugar onde a clínica não consegue protegê-la nem provar o
que aconteceu com ela.

## Três jeitos de acontecer

**Contas pessoais usadas para o trabalho.** Um OneDrive, Dropbox, Google Drive ou iCloud Drive
gratuito, aberto com um endereço pessoal. A empresa não tem administrador nele nem contrato com o
provedor.

**Contas da empresa compartilhadas demais.** A empresa paga o Microsoft 365 ou o Google Workspace, e o
arquivo está no tenant certo, mas a configuração de compartilhamento diz *qualquer pessoa com o
link*. O controle existe; a pessoa escolheu a opção mais frouxa. A próxima seção trata dessas opções.

**Armazenamento em nuvem distribuído por link.** O próprio bucket S3 da empresa, com um link
assinado pela chave de alguém para que uma pessoa de fora baixe um arquivo. É a versão do botão de
compartilhar do engenheiro de nuvem, e a terceira seção desta aula monta uma no seu laboratório.

A primeira está totalmente fora do alcance da empresa. As outras duas estão dentro dele, e é aí que
os controles da última seção valem.
