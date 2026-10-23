---
title: A Política de Grupo, como a Microsoft documenta
version: 1
---

**Nada nesta seção foi executado para este curso.** O laboratório não tem máquina Windows nem domínio
do Active Directory, então o que vem a seguir é o comportamento documentado pela Microsoft, sem
transcrito e sem captura de tela. Os nomes ficam em inglês, como aparecem no Group Policy Management
Console, para você reconhecê-los na tela.

**Um Group Policy Object** (GPO) é uma coleção de configurações com nome. Tem duas metades: **Computer
Configuration**, aplicada a uma máquina quando ela liga e num horário depois disso, e **User
Configuration**, aplicada a uma pessoa quando ela faz logon, em qualquer máquina que seja. Dentro de
cada metade há Policies (configurações que o sistema impõe, acinzentadas para o usuário) e
Preferences (configurações que ele grava, que um usuário ainda pode mudar entre uma atualização e
outra). Uma linha de base de segurança é quase toda Policies de Computer Configuration: regras de
senha, quais serviços rodam, quem pode fazer logon local, regras de firewall, configurações de
auditoria.

Um GPO não faz nada até ser **vinculado** a um contêiner do diretório: um **site**, o **domínio** ou
uma **unidade organizacional** (UO), que é uma pasta de contas de computadores e de usuários.
Vinculá-lo a uma UO o aplica a cada computador e a cada usuário dessa UO e das UOs abaixo dela. O
mesmo GPO pode ser vinculado em vários lugares, e é assim que uma linha de base chega a vários
departamentos.

## Quando se aplica

Um membro do domínio aplica a Computer Configuration quando liga e a User Configuration quando alguém
faz logon. Depois disso ele atualiza em segundo plano, **a cada 90 minutos mais um deslocamento
aleatório de até 30 minutos**, para que milhares de máquinas não perguntem aos controladores de
domínio no mesmo instante. Controladores de domínio atualizam a cada 5 minutos. As configurações de
segurança são reaplicadas a cada 16 horas mesmo sem nada ter mudado, e é isso que desfaz uma mudança
local numa delas.

Um administrador pode pedir uma atualização na hora com `gpupdate /force` na máquina, e pode
perguntar o que foi aplicado, e por qual GPO, com `gpresult /r`, ou `gpresult /h report.html` para o
relatório completo. Esse relatório, o **conjunto resultante de políticas**, é o equivalente Windows do
`sshd -T` da aula 1: não o que um GPO diz, mas o que a máquina acabou recebendo.

## Quem recebe

Por padrão um GPO se aplica a todo computador e usuário dos contêineres a que está vinculado, porque o
grupo **Authenticated Users** tem a permissão de aplicá-lo. Dois filtros estreitam isso:

- a **filtragem de segurança** troca Authenticated Users por um grupo específico, então um GPO
  vinculado ao domínio inteiro se aplica só aos membros de, digamos, "Notebooks do Financeiro";
- a **filtragem WMI** prende uma consulta sobre a máquina, como a versão do Windows, e o GPO só se
  aplica onde a consulta for verdadeira.

Os dois são fáceis de errar na direção que importa: um filtro que não pega ninguém deixa a linha de
base sem aplicar e não levanta erro nenhum. O `gpresult` lista os GPOs que uma máquina **negou**, com
o motivo, e essa lista é o primeiro lugar a olhar quando falta uma configuração.

## De onde vêm as linhas de base

A Microsoft publica as próprias **linhas de base de segurança** para cada versão do Windows, como GPOs
prontos para importar, no Security Compliance Toolkit, e o CIS publica os Benchmarks de Windows com o
caminho na Política de Grupo de cada configuração. Qualquer um dos dois é o ponto de partida que a
aula 2 descreveu: medir, adotar o que serve e anotar por que o resto não serve.
