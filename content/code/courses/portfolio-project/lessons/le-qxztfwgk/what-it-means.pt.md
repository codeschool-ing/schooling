---
title: O que deploy quer dizer para o seu projeto
version: 2
---

Num portfólio, implantado quer dizer que **quem avalia consegue ver o projeto funcionando sem instalar
nada**, e consegue de novo no mês que vem. Como isso fica depende do que você construiu:

::: track frontend mobile
Para você é uma página num endereço, ou um build que alguém consegue instalar. Um site estático não
precisa de servidor: uma hospedagem estática serve os arquivos, e o deploy é um push. Um app precisa de
uma página na loja, de um build de teste ou, no mínimo, de um vídeo num aparelho de verdade. O resto desta
aula é a metade de trás, de que você talvez não precise; as seções de HTTPS e de *continua no ar* ainda
valem para o que o seu front-end chamar.
:::

::: track backend ai prompt
Para você é exatamente esta aula: um serviço num endereço, respondendo em HTTPS, reiniciado quando cai,
com um health check. Se o serviço chama um modelo, a chave mora no ambiente do servidor, aula 14, e o
health check não deve gastar dinheiro a cada trinta segundos.
:::

::: track data data-science bi
Para você é o resultado num agendamento: um pipeline que roda toda noite e um lugar onde a saída dele
pode ser vista, um relatório renderizado ou um painel num link. A metade *continua no ar* desta aula vira
*roda de novo*: uma tarefa agendada que falha fazendo barulho quando falha.
:::

::: track devops devsecops cloud-engineering
Para você esta aula é o centro do projeto. Tudo abaixo é feito à mão uma vez para poder ser visto; o seu
projeto é a versão em que um commit faz isso, a infraestrutura é código, e um deploy ruim é revertido.
Grave os dois: a execução manual é como quem avalia entende o que o pipeline automatiza.
:::

::: track it-support networks-infra dba
Para você é um ambiente em que outra pessoa pode confiar: um serviço ou um laboratório que continua
rodando, documentado bem o bastante para ser reconstruído, e com uma restauração testada. Os comandos
desta aula são um runbook em formação; registre-os como um.
:::

::: track qa security
Para você é o alvo, rodando onde os seus testes ou a sua avaliação alcançam, e voltando a um estado
conhecido entre uma execução e outra. Implante o sistema sob teste exatamente como esta aula faz, num
laboratório que você controla, para que cada achado possa ser reproduzido.
:::

::: track *
O que quer que você tenha construído, implantado quer dizer que alguém consegue ver funcionando sem você,
no mês que vem tanto quanto hoje. Leia o resto desta aula pelas partes que se aplicam.
:::

Tudo o que vem a seguir acontece num laboratório que você monta na próxima seção: **srv** é um servidor numa
rede privada entre ele e o seu computador, não na internet, e o endereço dele, `loans.lab`, é um nome que só
o seu computador conhece. Isso é deliberado. Um deploy de laboratório pode ser repetido por qualquer pessoa,
para sempre, e não custa nada; a última seção diz o que muda quando o servidor é público.
