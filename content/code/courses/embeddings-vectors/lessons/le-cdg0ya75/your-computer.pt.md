---
title: Seu computador é o laboratório
version: 1
---

Tudo neste curso roda no seu próprio computador: os modelos de embedding, os bancos vetoriais e um
pequeno servidor que faz o papel das APIs dos provedores. Nada aqui precisa de conta nem de cartão.
O que precisa é de um terminal Linux, e esta seção é sobre onde esse terminal fica.

## Do que o curso precisa

- **Ubuntu 24.04.** Todas as transcrições do curso foram gravadas nele, pela Ana, uma
  desenvolvedora da livraria de que as aulas tratam, num diretório chamado `~/emb`. O seu prompt
  vai mostrar o seu nome e a sua máquina no lugar de `ana@lab`, e nada mais na saída deve mudar.
- **Cerca de 2 GB de disco** para as bibliotecas do Python, o modelo e os dados. A próxima seção
  mede isso.
- **Cerca de 4 GB de memória livres.** O maior programa do curso, a busca da aula 11 sobre um
  milhão de vetores, chegou a 3 GB na máquina em que o curso foi gravado, e nenhum outro passou de
  1,4 GB.
- **Uma conexão com a internet durante a preparação**, para baixar as bibliotecas e o modelo.
  Depois disso, três coisas vão à rede, uma vez cada: na aula 7, a tabela do tokenizador que o
  `tiktoken` lê e a planilha de preços, e na aula 12 a cópia do modelo que o próprio Chroma usa.

Qualquer computador dos últimos dez anos tem isso. O que muda é o jeito de pôr o Ubuntu nele, e são
três.

## Três jeitos de chegar lá

**Recomendado: instalado, no computador que você já usa.** Num computador Linux que rode o Ubuntu
24.04, não há nada a fazer. No Windows 10 ou 11, o WSL roda o Ubuntu dentro do Windows, com um
terminal próprio. Abra o PowerShell como administrador, digite `wsl --install -d Ubuntu-24.04`,
reinicie quando ele pedir, abra o *Ubuntu 24.04* pelo menu Iniciar e escolha um nome de usuário e
uma senha. É nesse terminal que entram todos os comandos do curso. O WSL precisa do disco acima e
mais os arquivos do próprio Ubuntu, e só tira memória do Windows enquanto está rodando.

**Uma máquina virtual**, para um Mac, ou para quem prefere manter o curso separado do próprio
sistema. Instale o **Ubuntu Server 24.04 LTS** como convidado: no VirtualBox, no Windows ou no
Linux, e no UTM, num Mac. Dê a ela 2 processadores, 25 GB de disco e pelo menos 4 GB de memória, 5 se o seu
computador tiver de sobra. Essa memória sai do seu computador enquanto a máquina estiver ligada,
então ela pede um computador com 8 GB ou mais. A aula 4 do curso `virtualization` cria uma máquina no VirtualBox passo a passo, se você
nunca fez isso.

**Online**, quando o seu computador não dá conta de nenhum dos dois. Uma pequena máquina Linux
alugada de um provedor de nuvem, ou um GitHub Codespace, dá a você um terminal no navegador. Escolha
o Ubuntu 24.04 onde houver escolha. Alguns têm uma cota gratuita; nada neste curso depende dela, e,
quando ela acaba, a máquina é cobrada por hora, então desligue-a quando não estiver estudando.

Os três terminam do mesmo jeito: um terminal no Ubuntu 24.04. A próxima seção começa ali.
