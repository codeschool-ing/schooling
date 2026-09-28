---
title: Escolher, e o bucket que alguém deixou público
version: 1
---

Escolha primeiro pelo jeito como o programa chega aos dados, e depois pelo preço. **Um programa que
precisa de um caminho não consegue usar uma chave, e um que precisa de um disco não consegue usar
nenhum dos dois**, diga o gráfico de barras o que disser.

| os dados | para onde vão | por quê |
|---|---|---|
| os arquivos de dados de um banco, PostgreSQL numa instância | um volume de bloco | muitas gravações pequenas em lugares espalhados, um só escritor, e um banco que espera um disco que ele controla |
| o sistema operacional de uma máquina virtual | um volume de bloco | só um dispositivo de bloco serve para dar boot |
| imagens que usuários enviam, lidas por vários servidores web e navegadores | objetos num bucket | gravadas uma vez, lidas muitas vezes pelo nome; o gigabyte mais barato, e um navegador busca uma direto no repositório |
| as mesmas imagens, quando a aplicação só sabe gravar num diretório | um compartilhamento de arquivos | a aplicação quer um caminho; custa mais e não muda código |
| logs de aplicação e backups | objetos, com uma regra de ciclo de vida | gravados uma vez, raramente lidos, guardados por meses; as classes e a expiração fazem a limpeza |
| uma aplicação legada que troca arquivos com outra por um diretório compartilhado | um compartilhamento de arquivos | os dois lados combinaram um caminho, e mudar qualquer um dos programas está fora de questão |

**Três erros aparecem com frequência suficiente para ter nome.** Um banco de dados num
compartilhamento de arquivos, onde cada gravação paga uma ida e volta pela rede e as travas do
próprio banco se encontram com as do sistema de arquivos. Um repositório de objetos montado como se
fosse um sistema de arquivos, com uma das ferramentas que fazem isso: ler funciona, e renomear um
diretório ou acrescentar a um arquivo vira as cópias e regravações que a seção sobre objetos
descreveu. E um volume grande e vazio criado "para depois", que cobra desde o primeiro dia: 1.000 GB
de `gp3` em `sa-east-1` são 1.000 × 0.1520 = 152.00 USD por mês por espaço em que ninguém gravou.

## O bucket que era público

De tempos em tempos uma notícia conta de registros achados num bucket que qualquer um podia ler.
**Buckets são privados por padrão, e aqueles foram deixados públicos por alguém.** Uma política que
dá leitura a todo mundo, ou uma configuração mudada para compartilhar um arquivo depressa, e o
repositório fez exatamente o que mandaram, para cada objeto debaixo dela.

No S3 os padrões ficaram mais rígidos com os anos. Desde abril de 2023 um bucket novo vem com o
Block Public Access ligado e as ACLs de objeto desativadas, então deixar um bucket público exige
hoje duas mudanças deliberadas em vez de uma descuidada. Isso reduz as chances e não as elimina,
porque a configuração ainda pode ser desligada por qualquer um com permissão para mudá-la.

Ler uma política e ver o que ela concede a quem é assunto da aula 7. Achar todo bucket público de
uma conta, cifrar com chaves que você controla e vigiar desvios é assunto do `cloud-security`, que é
onde esta aula passa o bastão.
