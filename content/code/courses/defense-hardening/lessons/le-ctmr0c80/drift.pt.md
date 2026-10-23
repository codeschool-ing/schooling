---
title: Achando o desvio antes de corrigi-lo
version: 1
---

**Desvio é qualquer diferença entre uma máquina e a descrição com que ela deveria bater.** A Política
de Grupo trata a maior parte em silêncio: uma configuração de política mudada localmente volta na
próxima atualização. O Ansible, rodado num horário, faz o mesmo. Mas devolver sem olhar perde
informação, porque uma configuração que alguém mudou à mão foi mudada por um motivo, e o motivo é ou
um problema que a linha de base não trata ou alguém que não deveria estar ali.

## Uma edição à mão numa estação

No `desk`, alguém aumentou o número de tentativas de SSH no próprio arquivo da linha de base, talvez
para um colega com um teclado que trava não ser cortado:

```
ana@desk:~$ sudo sed -i "s/^MaxAuthTries .*/MaxAuthTries 10/" /etc/ssh/sshd_config.d/10-baseline.conf; grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf
MaxAuthTries 10
```

Rode a linha de base a partir do `admin` em **modo de verificação**: `--check` pergunta a cada tarefa
o que ela mudaria e não muda nada, `--diff` imprime a diferença e `--limit desk` restringe a uma
máquina.

```
ana@admin:~$ ansible-playbook -i hosts.ini baseline.yml --check --diff --limit desk | grep -E "^[-+]|changed=|TASK \[SSH"
TASK [SSH, with this machine's values] *****************************************
--- before: /etc/ssh/sshd_config.d/10-baseline.conf
+++ after: /etc/ssh/sshd_config.d/10-baseline.conf
-MaxAuthTries 10
+MaxAuthTries 3
desk                       : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ana@desk:~$ grep MaxAuth /etc/ssh/sshd_config.d/10-baseline.conf
MaxAuthTries 10
```

O diff é o desvio, linha por linha: o arquivo diz 10 e a linha de base diz 3. O resumo conta duas
mudanças que *faria*, o arquivo e o reload que ele dispararia, e o segundo comando mostra o arquivo
intocado. **O modo de verificação transforma uma ferramenta de configuração numa ferramenta de
auditoria**: a mesma descrição que corrige máquinas consegue informar o quanto cada uma se afastou,
que é o que você quer antes de decidir entre corrigir e mudar a descrição.

## Duas respostas ao desvio

| | quando é a certa |
|---|---|
| devolver | a mudança foi um erro, um atalho, ou ninguém sabe dizer quem a fez |
| mudar a descrição | a mudança atendeu a uma necessidade real, então a necessidade pertence à linha de base, como variável de grupo ou de host com um motivo ao lado |

Aqui, um teclado não é motivo para triplicar as tentativas que um atacante ganha em cada conexão. A
linha de base fica, e a próxima execução devolve o 3.

## Desvio que a ferramenta não enxerga

O modo de verificação informa diferenças no que o playbook administra, e mais nada, que é o limite
que a aula 2 encontrou pelo outro lado. Um arquivo novo em `sshd_config.d`, um pacote instalado à
mão, uma segunda conta com id de usuário 0: nenhum deles está no `baseline.yml`, então nenhum aparece
no diff. A Política de Grupo tem o mesmo limite, e mais um: um valor de registro gravado por uma
política antiga que já foi removida fica na máquina, **tatuado**, porque nada o administra mais. Os
dois são o motivo de a aula 2 ter mantido uma verificação separada que pergunta à máquina o que é
verdade, e de a aula 18 coletar o inventário do que está de fato lá.
