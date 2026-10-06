---
title: Instalando em cada sistema
version: 1
---

**Instalar o Docker Desktop são os mesmos três passos em qualquer sistema: atender aos requisitos,
rodar o instalador do Docker, abrir o aplicativo uma vez.** O que muda é o requisito que falha. Esta
etapa nomeia os passos e as falhas; ela não tem transcrições, porque o laboratório do curso é um
servidor Linux e o Desktop é um aplicativo de desktop, e **nenhum dos passos abaixo foi executado
para este curso**. As telas mudam de uma versão para outra, então os passos estão escritos como o que
precisa ser verdade, e não como o botão que se aperta.

## Windows

1. **A virtualização por hardware precisa estar ligada.** É um ajuste do firmware (BIOS ou UEFI),
   em geral chamado Intel VT-x ou AMD-V, e alguns notebooks vêm com ele desligado. A aba Desempenho do
   Gerenciador de Tarefas mostra se está habilitado.
2. **O WSL 2 precisa estar instalado.** Num PowerShell de administrador, `wsl --install` o configura;
   a máquina pede para reiniciar.
3. Rode o instalador do site do Docker e mantenha a opção de usar o WSL 2. Saia da conta e entre de
   novo se ele pedir.
4. Abra o Docker Desktop e espere a janela dizer que o motor está rodando.

As falhas mais comuns são as duas primeiras: um erro dizendo que a virtualização não está
disponível, ou um dizendo que o WSL precisa ser atualizado, o que o `wsl --update` resolve.

## macOS

1. **Escolha o instalador certo**: há um para Apple silicon e um para Intel. O "Sobre Este Mac", no
   menu Apple, diz que chip a máquina tem.
2. Abra a imagem de disco baixada e arraste o Docker para Aplicativos.
3. Abra-o a partir de Aplicativos. A primeira abertura pede a sua senha, para instalar as partes que
   precisam de direitos de administrador.

A falha mais comum é o instalador errado, que se recusa a abrir, e depois dela, um notebook da
empresa cujo software de gestão bloqueia esse passo.

## Linux

O Docker Desktop para Linux é instalado a partir de um pacote que o Docker publica para cada
distribuição suportada, e precisa do KVM, a virtualização do kernel, que o `ls /dev/kvm` mostra se
está disponível. **Para a maioria de quem usa Linux, o Docker Engine sozinho é a melhor escolha**, e
a aula 6 trata dele. Instale um ou outro; os dois na mesma máquina são dois conjuntos separados de
containers, com o `docker context` decidindo qual deles cada comando alcança.

## Depois de qualquer um: o tamanho da VM

Os ajustes do Docker Desktop decidem quantos processadores, quanta memória e quanto disco a VM
recebe. **Os containers nunca podem usar mais do que a VM tem**, seja o que for que o notebook tenha:
uma VM com 2 GB não roda um banco que precisa de 4, por mais memória que sobre do lado de fora. Se
containers estão sendo mortos sem motivo aparente, o código de saída 137 da aula 4 é a primeira coisa
a conferir, e o ajuste de memória da VM é a segunda. A próxima etapa mostra como ler o que a VM
recebeu.
