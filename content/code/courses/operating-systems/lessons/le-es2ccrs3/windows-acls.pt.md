---
title: Windows: uma lista em vez de três perguntas
version: 1
---

O NTFS, o sistema de arquivos da aula 2, não tem dono, grupo e outros. **Todo arquivo e pasta carrega
uma lista de controle de acesso**, uma *ACL*: uma lista de entradas, cada uma dizendo um usuário ou
grupo, se ele é *permitido* ou *negado*, e o quê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A lista de controle de acesso de uma pasta do Windows, D:\\Accounts, como a aba Segurança a mostra, uma linha por entrada. SYSTEM, permitir, controle total, herdada de D:. Administradores, permitir, controle total, herdada de D:. O grupo Accounts de OFFICE, permitir, modificar, definida nesta pasta. O grupo Interns de OFFICE, negar, leitura, definida nesta pasta.\"><defs><marker id=\"ac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">D:\\Accounts, aba Segurança: uma lista de controle de acesso</text><text x=\"26\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem</text><text x=\"206\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">permitir / negar</text><text x=\"336\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o quê</text><text x=\"476\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de onde</text><rect x=\"20\" y=\"54\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SYSTEM</text><text x=\"206\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Permitir</text><text x=\"336\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Controle total</text><text x=\"476\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">herdada de D:\\</text><rect x=\"20\" y=\"90\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Administradores</text><text x=\"206\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Permitir</text><text x=\"336\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Controle total</text><text x=\"476\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">herdada de D:\\</text><rect x=\"20\" y=\"126\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">OFFICE\\Accounts</text><text x=\"206\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Permitir</text><text x=\"336\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Modificar</text><text x=\"476\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">esta pasta</text><rect x=\"20\" y=\"162\" width=\"680\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">OFFICE\\Interns</text><text x=\"206\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Negar</text><text x=\"336\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Leitura</text><text x=\"476\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">esta pasta</text></svg>", "caption": "Não três perguntas fixas, e sim uma lista, do tamanho que precisar, com qualquer usuário ou grupo. As entradas descem da pasta de cima, a não ser que a herança seja desligada.", "same": ["SYSTEM", "OFFICE\\Accounts", "OFFICE\\Interns"]}
```

As permissões que uma entrada pode dar vêm em alguns pacotes padrão:

| permissão | permite |
|---|---|
| **Controle total** | tudo, inclusive mudar as próprias permissões |
| **Modificar** | ler, gravar, criar e apagar |
| **Ler e executar** | abrir arquivos e rodar programas |
| **Leitura** | abrir arquivos e listar pastas |
| **Gravar** | criar arquivos e mudá-los |

Três regras decidem o que uma pessoa realmente recebe:

1. **As entradas se somam.** Um usuário em dois grupos recebe as permissões dos dois.
2. **Negar vence permitir**, quando os dois estão definidos no mesmo lugar. É assim que o desenho deixa
   os estagiários de fora mesmo que eles estejam também num grupo que pode ler. Entradas de negação são
   poderosas e difíceis de raciocinar, então são usadas com parcimônia.
3. **As entradas são herdadas** da pasta de cima, a não ser que a herança seja desligada. Uma entrada
   definida direto numa pasta vence uma herdada.

O **Avançado > Acesso Efetivo** da aba *Segurança* responde a única pergunta que importa num chamado:
com todas as entradas, o que *esta* pessoa pode fazer aqui?

Pela rede há uma segunda lista, as **permissões de compartilhamento** da pasta compartilhada. **O usuário
recebe a mais restritiva das duas**, e é por isso que um arranjo comum é compartilhar com *Todos:
Controle total* no compartilhamento e fazer todo o trabalho de verdade na lista do NTFS.

```sh
icacls D:\Accounts                                        # list the entries
icacls D:\Accounts /grant "OFFICE\Accounts:(OI)(CI)M"    # Modify, passed down to files and folders
icacls D:\Accounts /remove "OFFICE\Interns"              # take an entry away
Get-Acl D:\Accounts | Format-List                         # the same list, as an object
```

**Nada disso foi rodado para esta aula.** `(OI)(CI)` quer dizer que a entrada desce para arquivos
(*object inherit*) e subpastas (*container inherit*), e `M` é Modificar. O `Get-Acl` do PowerShell lê a
mesma lista no Windows. No Linux ele não existe:

```
PS /srv/office> Get-Acl payroll.txt
Get-Acl: The term 'Get-Acl' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
```
