---
title: Controle de acesso obrigatório, confinando um programa
version: 1
---

**Nada nesta seção foi executado para este curso.** O controle de acesso obrigatório é imposto pelo
kernel, e o kernel que estes contêineres dividem não o oferece a eles; o que vem a seguir foi tirado da
documentação do AppArmor e do SELinux.

## Permissões dizem quem; confinamento diz o quê

As permissões da aula 6 respondem a uma pergunta: esta **conta** pode ler este arquivo? Um programa
herda todos os direitos da sua conta. O portal roda como `portal`, então qualquer coisa que faça o
portal se comportar mal ganha tudo o que `portal` pode fazer, o que na maioria dos servidores é muito
mais do que o portal precisa.

**O controle de acesso obrigatório acrescenta uma segunda pergunta que a conta não consegue
contornar: este programa pode fazer isto, afinal?** Uma política escrita para o portal lista o que ele
pode tocar, os próprios arquivos, a porta dele, as bibliotecas do Python, e o kernel recusa todo o
resto, ao portal, seja qual for a conta, e também ao root rodando o portal. É *obrigatório* porque o
dono de um arquivo não consegue abrir uma exceção, como consegue com permissões.

## AppArmor e SELinux

O Linux tem duas implementações comuns, e uma distribuição traz uma delas:

| | AppArmor | SELinux |
|---|---|---|
| padrão em | Ubuntu, Debian, SUSE | Red Hat, Fedora, Rocky, Alma |
| uma regra nomeia | caminhos: `/opt/portal/** r,` | rótulos em arquivos e processos, casados por tipo |
| escrever um perfil | legível, por programa, muitas vezes gerado em modo de aprendizado | mais difícil de ler, muito granular, em geral trazido pela distribuição |
| dois modos | `complain` registra o que recusaria; `enforce` recusa | `permissive` registra; `enforcing` recusa |

Um perfil do AppArmor para o portal ficaria mais ou menos assim, um esboço a partir da sintaxe
documentada, e não um arquivo testado:

```
/opt/portal/portal.py {
  #include <abstractions/base>
  #include <abstractions/python>
  /opt/portal/** r,
  network inet stream,
  deny /home/** rw,
}
```

O jeito comum de escrever um é o mesmo de toda regra deste curso: rodar o programa em modo
**complain** enquanto ele faz o trabalho normal, ler o que ele tocou, anotar isso como o perfil, e só
então passar para **enforce**. O `aa-status` lista os perfis e os modos, e o `aa-genprof` e o
`aa-logprof` ajudam a montar um perfil a partir do log.

## Por que o laboratório não consegue mostrar

O AppArmor e o SELinux moram na camada de segurança do kernel, que é dividida por todos os contêineres
da máquina, e só o host consegue carregar uma política nela. A imagem do laboratório nem instala as ferramentas do AppArmor, porque
dentro de um contêiner não haveria nada para elas gerenciarem. Na sua própria máquina virtual Ubuntu, fora dos contêineres, o AppArmor
está presente e impondo: o `sudo aa-status` ali lista os perfis que os próprios pacotes do Ubuntu
instalam. Esse é o lugar para experimentar as ideias desta seção, num programa seu.

A aula 12 roda no laboratório uma forma de confinamento: as opções de isolamento que o systemd oferece
a cada serviço, que montam um mundo menor para um programa a partir de namespaces, e não de uma
política do kernel.
