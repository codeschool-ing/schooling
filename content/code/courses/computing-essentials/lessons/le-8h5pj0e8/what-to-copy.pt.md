---
title: O que de fato precisa ser copiado, e as seis coisas que se esquecem
version: 1
---

Um backup de tudo é lento, caro e raramente termina. Um backup das coisas certas são algumas
dezenas de gigabytes e roda enquanto você faz café.

## A resposta curta

**A sua pasta pessoal, e mais nada.**

Programas se reinstalam. O sistema operacional se reinstala. Nenhum dos dois contém nada que seja
seu, e os dois estão a um download de distância. Um backup que inclui `C:\Windows` está gastando
a maior parte do tempo e do espaço com a parte mais fácil de repor.

Duas exceções que valem ser nomeadas:

- **Uma imagem de disco inteira** é outra ferramenta para outro serviço — ela restaura uma máquina
  inteira como ela estava, com programas e ajustes, num passo só. É genuinamente útil para uma
  máquina de trabalho em que reinstalar custaria um dia, e não substitui copiar os seus arquivos,
  porque uma imagem é um objeto grande e não dá para tirar dela a planilha do mês passado com
  facilidade.
- **Máquinas virtuais e caches grandes** dentro da pasta pessoal muitas vezes valem ser excluídos,
  porque são enormes e se regeneram.

## As seis coisas que se esquecem

Cada uma delas mora fora da pasta que as pessoas imaginam como *meus documentos*, e cada uma é
descoberta faltando no pior momento.

| | onde está | o que perder custa |
|---|---|---|
| **favoritos e senhas do navegador** | a pasta de perfil do navegador | anos de links acumulados, e todo login salvo |
| **códigos de dois fatores** | um aplicativo no celular, muitas vezes sem backup algum | ficar trancado para fora de tudo de uma vez |
| **cofre do gerenciador de senhas** | normalmente sincronizado, às vezes só local | o mesmo, e pior |
| **fotos no celular** | o celular | a metade insubstituível dos dados da maioria |
| **ajustes dos programas** | `AppData`, `~/Library`, `~/.config` | uma semana reconfigurando coisas |
| **e-mail, se não for webmail** | um arquivo de correio local | correspondência, e muitas vezes a única cópia dos anexos |

**A segunda linha é a que dá para resolver hoje.** Perder um celular com um aplicativo
autenticador e sem códigos de recuperação significa provar a sua identidade para uma dúzia de
empresas, várias das quais não vão acreditar em você. Todo autenticador oferece códigos de
recuperação; imprima e guarde num lugar que não seja o celular.

## O que não copiar, e por que isso importa

Excluir coisas não é frescura — é o que mantém um backup rápido o bastante para acontecer todo dia
em vez de todo mês:

- **downloads**, a menos que estejam sendo usados como arquivo morto, contra o que a aula
  anterior argumentou;
- **caches e pastas temporárias**, que são grandes e não valem nada;
- **qualquer coisa já versionada em outro lugar** — um repositório de código, uma pasta de nuvem
  com histórico ligado;
- **instaladores**, que são a definição de rebaixável.

## E a que decide tudo

**As fotografias.** Para a maioria das pessoas o único dado verdadeiramente insubstituível são
imagens, e a maior parte delas está num celular e não na máquina de que esta aula tratou.

Um celular que copia para um serviço de nuvem é uma cópia em um lugar, e esse é o arranjo de que
a terceira linha da grade tratava. Algo automático, mais uma cópia puxada para o computador uma
vez por trimestre, é a resposta inteira — e é a única tarefa doméstica deste curso de que as
pessoas se arrependem de não ter feito.
