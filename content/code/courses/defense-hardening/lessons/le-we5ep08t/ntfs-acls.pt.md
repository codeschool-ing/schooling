---
title: Permissões NTFS no Windows
version: 1
---

**Nada nesta seção foi executado para este curso.** O laboratório não tem máquina Windows. O que vem
a seguir é o comportamento documentado do Windows, e os comandos aparecem como a Microsoft os
documenta, sem transcrito.

O Windows não tem nove bits por baixo: todo arquivo e pasta no NTFS tem uma lista de controle de
acesso desde o começo, e essa lista é tudo o que existe. Cada entrada, uma **access control entry**
(ACE), cita um usuário ou grupo, um conjunto de direitos e se os **permite** ou **nega**. Os direitos
são mais finos que os três do Linux: ler, gravar, executar, apagar, mudar permissões e tomar posse são
separados, e os pacotes comuns se chamam Read, Read & execute, Modify e Full control.

## Duas diferenças que importam

**Entradas de negação existem e, no mesmo nível, vencem.** O Windows avalia entradas explícitas antes
das herdadas e, dentro de cada uma, negação antes de permissão. Então uma negação explícita para um
grupo vence uma permissão explícita para um usuário que está nele, o que é o contrário da surpresa do
Linux na seção anterior: no Linux uma entrada de usuário nomeado pode restringir um membro de um
grupo generoso; no Windows uma negação no grupo restringe o usuário diga a entrada dele o que disser.
O conselho da Microsoft é usar negação com parcimônia, porque o resultado de misturar as duas é
difícil de ler.

**A herança é o caso normal.** No Linux uma ACL padrão é algo que você acrescenta. No NTFS as
permissões descem de cada pasta para tudo dentro dela a não ser que a herança seja quebrada, e a
maior parte das permissões de um sistema de arquivos é herdada, não escrita no arquivo. Uma entrada
pode dizer até onde vai: só esta pasta, subpastas, arquivos, ou todos. Quebrar a herança numa pasta,
para dar a ela uma lista própria, é o equivalente ao `setfacl` do Linux num diretório, e é o lugar
onde costuma se esconder uma exceção esquecida.

## icacls

O `icacls` é a ferramenta de linha de comando, e as respostas dele se leem como as do `getfacl`:

```
icacls D:\Clientes
icacls D:\Clientes /grant "JATOBA\Auditoria:(OI)(CI)R"
icacls D:\Clientes /inheritance:r
```

O primeiro lista cada entrada com os direitos em forma curta, `(F)` para controle total, `(M)`
modificar, `(RX)` ler e executar, `(R)` ler, e as marcas de herança `(OI)` herança de objeto
(arquivos) e `(CI)` herança de contêiner (pastas); um `(I)` marca uma entrada herdada. O segundo dá à
auditora leitura na pasta e em tudo abaixo dela, que é o `setfacl -m` e o `setfacl -d` desta aula
num só. O terceiro tira as entradas herdadas e mantém só as explícitas, que é como uma pasta deixa
de confiar na pasta mãe.

Vale o mesmo conselho do Linux. Conceda a grupos e não a pessoas, para que alguém que muda de função
mude de grupo e não de cem listas. Pergunte ao sistema o que uma pessoa consegue de fato fazer, pela
aba **Effective Access** nas configurações avançadas de segurança de uma pasta, em vez de ler a lista
e somar de cabeça.
