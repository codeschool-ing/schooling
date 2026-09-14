---
title: A tabela, uma vez
version: 1
---

Dezessete seções fizeram, cada uma, uma comparação de passagem. Esta é a coisa inteira num lugar
só, para ser lida uma vez e consultada depois — e aí o curso para de falar de Windows até a aula
10, que dá ao PowerShell o tratamento sério que ele merece.

## A tabela

| | Linux | Windows |
|---|---|---|
| **separador de caminho** | `/` | `\` |
| **onde um caminho começa** | uma árvore em `/` | uma letra de unidade — `C:`, `D:` |
| **um segundo disco** | montado num diretório | ganha a letra dele |
| **maiúsculas em nomes** | `a.txt` ≠ `A.txt` | o mesmo arquivo |
| **o que faz um arquivo executar** | um bit de permissão | a extensão `.exe` |
| **arquivos ocultos** | um nome começando com `.` | um atributo no arquivo |
| **finais de linha** | `LF` | `CRLF` |
| **configuração da máquina** | arquivos de texto em `/etc` | o registro |
| **instalar software** | repositório assinado, um comando | baixar e rodar um instalador |
| **atualizar** | um comando, sem reboot | por programa, e com reboot |
| **programas em segundo plano** | daemons, rodados pelo systemd | serviços, rodados pelo SCM |
| **administrador** | `root`, uid 0 — você pede com `sudo` | Administrador — você clica Sim |
| **o shell** | bash — texto entra, texto sai | PowerShell — objetos entram, objetos saem |
| **logs** | texto em `/var/log` | o Log de Eventos, pelo visualizador |
| **acesso remoto** | SSH, desde sempre | RDP, ou SSH mais recentemente |

## As quatro linhas que não são só diferença de nome

Quase tudo naquela tabela são dois jeitos de escrever uma ideia. Quatro linhas são ideias
genuinamente diferentes, e são as que mudam como você trabalha.

**Configuração como texto.** Essa é a maior. Porque o `/etc` é texto, toda ferramenta da aula 8
administra esta máquina: você pode dar `grep` na configuração, `diff` entre duas máquinas, pôr o
`/etc` no git, e mandar uma mudança para alguém como um patch. Um registro binário pode ser
editado, exportado e automatizado — mas não pelas ferramentas que você já tem, e não revisado por
uma pessoa lendo um diff.

**Texto como interface entre programas.** O `|` é o assunto da aula 8 e a razão de comandos
pequenos se combinarem em qualquer coisa. O PowerShell responde ao mesmo problema passando
**objetos**, que é uma resposta real e discutivelmente melhor — a aula 10 defende isso com
honestidade, em vez de defender esta. O que importa aqui é que são respostas diferentes, não
sintaxes diferentes.

**O bit de permissão, não a extensão.** No Windows, `.exe` quer dizer executável e renomear um
arquivo muda o que o sistema vai fazer com ele. No Linux, executar é um bit no modo, então um
arquivo chamado `backup` sem extensão nenhuma roda e um `virus.exe` parado na sua casa não —
seção 11 e aula 4.

**Atualizar sem reiniciar.** A seção 15 já fez o argumento. É a razão de as máquinas que rodam a
internet rodarem Linux, e não é preferência.

## O que de fato atravessa

Você não está começando do zero em nenhum dos lados:

- **As ideias atravessam por completo.** Arquivos, diretórios, processos, permissões, usuários,
  serviços e logs existem nos dois. Você está aprendendo um sistema, não um vocabulário.
- **Os comandos não**, nativamente. A aula 10 te dá os equivalentes no PowerShell e as armadilhas —
  os apelidos que fazem o `ls` funcionar lá e então se comportar diferente.
- **E o WSL elimina a pergunta.** Um Linux de verdade ao lado do Windows, onde tudo neste curso se
  aplica sem mudança. Se você está no Windows, a seção 04 já mandou instalar.

## O que este curso faz daqui em diante

Ele para de comparar. Tudo depois desta seção é Linux nos termos dele, porque a comparação cumpriu
o papel: agora você sabe quais dos seus hábitos atravessam e quais eram hábitos de Windows que você
tratava como computação.

A aula 10 é a única exceção, e ela não é comparação — é o PowerShell ensinado como coisa própria,
porque um ambiente misto é o ambiente normal e saber um shell só é saber metade do seu trabalho.
