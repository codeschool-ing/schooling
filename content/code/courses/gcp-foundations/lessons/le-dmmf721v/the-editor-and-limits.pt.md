---
title: O editor, o preview e os limites
version: 1
---

**O Cloud Shell vem com um editor**, aberto pela barra de ferramentas do terminal ou com `cloudshell edit
ARQUIVO`, que edita os arquivos do seu diretório home no navegador. Ele é feito sobre o núcleo de código aberto
do Visual Studio Code, com as extensões do Google para os próprios serviços, e é um lugar razoável para mudar um
arquivo de Terraform durante um incidente a partir de um computador emprestado. Não é motivo para manter
trabalho no Cloud Shell: os arquivos continuam no diretório home da seção anterior, com as regras dela.

## Web preview

Um programa no Cloud Shell pode escutar numa porta, e o **web preview** o abre no seu navegador pelo proxy do
Google, na porta 8080 a menos que se escolha outra. Só você abre esse endereço: ele é autenticado com a sua conta
do Google. É como uma pequena aplicação web é testada antes de qualquer coisa ser implantada, e é o único jeito
de algo dentro do Cloud Shell ser alcançado de fora.

## Os limites que lhe dão forma

O Cloud Shell é uma máquina gratuita dividida por todo mundo que abre uma, e é racionado. O Google documenta:

- **uma cota semanal de horas** de uso, depois da qual o Cloud Shell se recusa a iniciar até a cota renovar;
- **uma duração máxima para uma sessão**, e um fim para qualquer sessão deixada ociosa por um tempo;
- **um diretório home pequeno**, de alguns gigabytes;
- **um modo efêmero**, escolhido por sessão, sem diretório home nenhum: tudo some quando ela acaba.

Os números mudam, e é por isso que não estão aqui; a página de limites da documentação do Cloud Shell os tem.

## Duas coisas a decidir antes de confiar nele

**Ele age como você.** Um script colado no Cloud Shell roda com todo papel que a sua conta tem, em todo projeto,
sem confirmação. Para um engenheiro com papéis em produção, essa é a mesma exposição do laptop dele, num lugar
em que é mais fácil colar um comando achado na internet. A regra do planner da lição 22 vale aqui também:
produção por uma conta de serviço, impersonada, nunca como si mesmo.

**Ele pode ser desligado.** Um administrador do Google Workspace ou do Cloud Identity, lição 10, pode desligar o
Cloud Shell para os usuários da organização. Uma empresa cujos engenheiros só podem trabalhar de máquinas
gerenciadas faz isso, e um runbook que diz *abra o Cloud Shell* vira então um runbook que falha na noite em que
é necessário. Os runbooks do planner dizem o que digitar, e só supõem um terminal com gcloud: o Cloud Shell, ou
o laptop da lição 1.
