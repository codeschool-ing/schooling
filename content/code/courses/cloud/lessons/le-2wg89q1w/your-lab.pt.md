---
title: Seu laboratório, no seu próprio computador
version: 1
---

Este curso não precisa de conta de nuvem, mas precisa de um terminal. **Cada comando das aulas é um
que você digita no seu próprio computador**, e a plataforma não roda nada por você: nenhuma máquina,
nenhum shell no navegador, nenhuma caixa de areia. O que você precisa é pouco: Python 3, duas
ferramentas do dia a dia, `curl` e `jq`, e a linha de comando da AWS, que nunca recebe uma chave. As
aulas 4 e 5 acrescentam dois programas em Python, o **moto** e o **cloud-init**, para imitar um
serviço e conferir um arquivo na sua própria máquina. As duas seções seguintes instalam
tudo isso e entregam o único programa sobre o qual o curso se apoia, a tabela de preços. Nada disso
custa dinheiro, e nada pede cartão.

As aulas foram gravadas no Ubuntu 24.04, e há três jeitos de ter um terminal nele.

| | o que é | o que custa ao seu computador |
|---|---|---|
| **instalado** (recomendado) | as ferramentas no seu próprio sistema: o próprio Ubuntu 24.04, ou o Ubuntu 24.04 no WSL, no Windows | cerca de 1,3 GB de disco, nada rodando em segundo plano, e 4 GB de memória livre enquanto a tabela de preços lê o arquivo maior |
| uma máquina virtual | o Ubuntu Server 24.04 num hipervisor, em qualquer sistema | 2 processadores, 4 GB de memória e 15 GB de disco enquanto ela roda |
| online | um shell Linux alugado no navegador | nada no seu computador; uma conta com alguém, e um limite de quanto tempo ele dura |

**Instale, a não ser que você use um Mac.** No Linux, é o terminal que você já tem. No Windows, o
WSL roda um Ubuntu de verdade ao lado do Windows: `wsl --install -d Ubuntu-24.04` num PowerShell de
administrador o instala, e o item Ubuntu do menu Iniciar abre o terminal dele. Nada que este curso
instala precisa ser um serviço ou mudar as configurações do sistema: tirando cinco pacotes do
repositório do Ubuntu, tudo fica em dois diretórios da sua pasta pessoal, e apagá-los desfaz tudo.

**Uma máquina virtual** é o caminho num Mac, e em qualquer computador que você prefira não mexer. As
ferramentas também rodam no macOS, mas as transcrições foram gravadas no Ubuntu, e algumas delas,
sobretudo as mensagens do próprio sistema, não bateriam. Instale o Ubuntu Server 24.04 a partir da
imagem no hipervisor que o seu sistema oferece: Hyper-V ou VirtualBox no Windows, UTM num Mac com
Apple silicon, GNOME Boxes ou virt-manager no Linux. O Multipass, da Canonical, faz o mesmo com um
comando nos três: `multipass launch 24.04 --name cloud --cpus 2 --memory 4G --disk 15G`, e depois
`multipass shell cloud`. **Esses dois comandos não foram rodados para este curso**, porque a máquina
em que ele foi gravado não roda hipervisor; tudo o que vem depois deles foi.

**Online** é um shell que o computador de outra pessoa roda por você, como o GitHub Codespaces, ou
qualquer máquina Linux pequena alugada por hora. Funciona, porque nada aqui precisa de mais do que um
shell com rede. **Nenhuma aula depende da cota gratuita de uma empresa**, porém, e cada uma tem as
suas horas e os seus termos, que mudam. O CloudShell da própria AWS é o que não serve: ele pede uma
conta AWS, e a ideia deste curso é que você nunca precise de uma.

Seja qual for a escolha, a seção seguinte começa do mesmo lugar: um terminal no Ubuntu 24.04, logado
como você mesmo. A seção depois dela, sobre falhas, é a que se lê quando um comando não responde do
jeito que a transcrição mostra.
