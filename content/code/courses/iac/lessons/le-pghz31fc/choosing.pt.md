---
title: Escolher um layout
version: 1
---

Os três layouts dão a cada ambiente o seu estado, que era o problema. **Eles diferem em onde a escolha
do ambiente é feita**, e quase todas as outras diferenças decorrem disso.

| | workspaces | um diretório por ambiente | Terragrunt |
| --- | --- | --- | --- |
| onde o ambiente é escolhido | um arquivo escondido, `.terraform/environment` | o caminho em que você está | o caminho em que você está |
| o que é compartilhado | tudo, configuração e bloco de backend | os módulos; os arquivos raiz são cópias | os módulos e um `root.hcl` |
| o que difere entre ambientes | só os valores, a não ser que o código teste `terraform.workspace` | qualquer coisa, arquivo por arquivo | as entradas de cada unit, ou qualquer outra coisa nela |
| credenciais separadas por ambiente | desajeitado: um bloco de backend, um bucket | natural: cada diretório configura as suas | natural, por unit ou por pasta |
| segurar prod numa versão antiga de um módulo | não dá: um `source` para todos | `?ref=` por ambiente | `?ref=` por unit |
| ferramentas para instalar | Terraform | Terraform | Terraform e Terragrunt |
| o erro clássico | aplicar no workspace errado | editar uma cópia e não a outra | um `run --all` tocando mais do que se pretendia |

Leia a primeira linha e o conselho das três últimas seções sai dela. **Workspaces servem para cópias
que devem ser idênticas e de vida curta**: um ambiente temporário por branch, uma cópia de rascunho
para testar uma mudança, a mesma stack para vários clientes com um conjunto de credenciais. Ali, a
seleção escondida é um risco pequeno porque nada precioso mora em nenhuma delas, e criar uma é um
comando, não um diretório novo.

**Diretórios separados servem para dev e prod**, o caso com que esta aula começou. O ambiente fica
visível no caminho, cada um pode se autenticar de um jeito, e prod pode ficar no módulo do mês passado
enquanto dev testa o deste mês. O preço são os arquivos raiz copiados, e com um punhado de ambientes e
estados é um preço pequeno que as pessoas superestimam.

**O Terragrunt serve para o mesmo layout numa escala em que as cópias doem**: muitos ambientes,
regiões ou contas, cada um com vários estados que dependem uns dos outros. Ele remove a repetição e
acrescenta ordem entre estados, e custa uma segunda ferramenta que todo mundo precisa conhecer.

Duas observações valem qualquer que seja a escolha. Primeiro, os layouts se combinam: um time com prod
e dev em diretórios ainda pode usar workspaces dentro de dev para cópias descartáveis. Segundo, nenhum
deles substitui a camada de baixo. Um estado por ambiente impede o Terraform de misturá-los; só
credenciais separadas, de preferência contas separadas, impedem que uma pessoa ou um pipeline com o
acesso de dev alcance prod.
