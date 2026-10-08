---
title: Duas chaves e um arquivo curto
version: 1
---

A maioria das VPNs começa com uma autoridade certificadora, um banco de usuários e páginas de
configuração. **O WireGuard começa com duas chaves por máquina e um arquivo de uma dúzia de linhas.** Não
há usuário, nem senha, nem negociação de algoritmos. Cada ponta é conhecida pela chave pública, e a
criptografia é fixada pelo protocolo: Curve25519 para combinar as chaves, ChaCha20-Poly1305 para
criptografar e autenticar os dados.

O par de chaves é gerado na máquina que vai usá-lo:

```
ana@hq:~$ sudo sh -c "umask 077; wg genkey > /etc/wireguard/hq.key"
ana@hq:~$ sudo cat /etc/wireguard/hq.key | wg pubkey | sudo tee /etc/wireguard/hq.pub
B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=
ana@hq:~$ sudo ls -l /etc/wireguard
total 8
-rw------- 1 root root 45 Sep 28 18:08 hq.key
-rw-r--r-- 1 root root 45 Sep 28 18:08 hq.pub
```

O `wg genkey` grava uma chave privada e o `wg pubkey` deriva dela a pública. O inverso não é possível, e
esse é o sentido do par. O `umask 077` na frente faz o arquivo novo ser legível só pelo dono. O `ls -l`
mostra o resultado: **`hq.key` é `-rw-------`, do root e de mais ninguém**, enquanto `hq.pub` pode ser
lido por todos. Os dois têm 45 bytes, 44 caracteres de base64 e uma quebra de linha.

A chave pública foi impressa porque é a metade que se entrega às outras máquinas. A privada nunca
apareceu na tela, e **também não tem lugar numa janela de chat, num chamado ou num repositório**: quem a
tiver é `hq`, para todos os pares.

Gere os pares de `branch` e de `remote` do mesmo jeito, cada um na própria máquina e com o próprio nome
no lugar de `hq`: `branch.key` e `branch.pub` em `branch`, `remote.key` e `remote.pub` em `remote`. Cada
máquina recebe então um arquivo de configuração, `/etc/wireguard/wg0.conf`, com a própria chave privada e
a chave pública de cada par com quem conversa. Escreva cada um com `sudo nano` na sua máquina. Este é o de
`hq`, com a chave privada escondida, já que o arquivo de verdade a guarda em claro:

```schooling-example
{"language": "ini", "file": "wg0.conf", "parts": [{"code": "[Interface]\nAddress = 10.20.0.1/24\nListenPort = 51820", "note": "Esta máquina. `Address` é o endereço do próprio `hq` dentro do túnel, que o `wg-quick` põe na interface. `ListenPort` é a porta UDP em que ele espera, 51820 por convenção."}, {"code": "PrivateKey = (hidden here, in the file it is the key)", "note": "A chave privada, em claro no arquivo de verdade. Por isso o arquivo é do root e ninguém mais o lê, como a chave de onde ela foi copiada."}, {"code": "# the branch office\n[Peer]\nPublicKey = n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=", "note": "Um bloco por par, e a chave pública é a identidade inteira do par: quem tiver a chave privada correspondente é `branch`, para `hq`. O comentário é para pessoas."}, {"code": "Endpoint = 198.51.100.2:51820", "note": "Para onde mandar. `branch` tem um endereço público fixo, então `hq` pode começar a conversa."}, {"code": "AllowedIPs = 10.20.0.2/32, 192.168.20.0/24", "note": "Os endereços atrás deste par: o endereço de túnel dele e a LAN da filial. Pacotes para eles vão para `branch`, e pacotes de `branch` têm de vir deles."}, {"code": "# Ana, at home\n[Peer]\nPublicKey = FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE=", "note": "O segundo par, o laptop da Ana em casa."}, {"code": "AllowedIPs = 10.20.0.3/32", "note": "Um endereço, o dela, e nenhum `Endpoint`: `hq` descobre onde ela está pelo primeiro pacote dela."}]}
```

**As chaves destas listagens são as que esta gravação gerou, e as suas são outras.** Em cada linha
`PrivateKey` vai a chave privada daquela máquina, que `sudo cat /etc/wireguard/hq.key` imprime em `hq`;
em cada linha `PublicKey` vai a chave pública do par, do arquivo `.pub` dele na própria máquina. Uma
chave pública copiada desta página nomearia uma máquina que você não tem.

`branch` tem um par, `hq`:

```schooling-example
{"language": "ini", "file": "wg0.conf", "parts": [{"code": "[Interface]\nAddress = 10.20.0.2/24\nListenPort = 51820\nPrivateKey = (hidden here, in the file it is the key)", "note": "`branch`, com a mesma forma de `hq`: o próprio endereço de túnel, a mesma porta e a própria chave privada na última linha."}, {"code": "[Peer]\nPublicKey = B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=\nEndpoint = 203.0.113.2:51820\nAllowedIPs = 10.20.0.1/32, 192.168.10.0/24", "note": "Um par, `hq`, pela chave pública, no endereço público fixo dele. Atrás dele ficam o endereço de túnel de `hq` e a LAN da matriz."}]}
```

E `remote`, o laptop da Ana, também tem um, `hq` de novo:

```schooling-example
{"language": "ini", "file": "wg0.conf", "parts": [{"code": "[Interface]\nAddress = 10.20.0.3/24\nPrivateKey = (hidden here, in the file it is the key)", "note": "O laptop da Ana. Sem `ListenPort`: ninguém começa uma conversa com um laptop em casa, então qualquer porta livre serve."}, {"code": "[Peer]\nPublicKey = B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=\nEndpoint = vpn.example.com:51820\nAllowedIPs = 10.20.0.0/24, 192.168.10.0/24", "note": "`hq`, achado pelo nome, que o servidor DNS da rede responde. Pelo túnel vão a própria rede do túnel e a LAN da matriz, e mais nada."}, {"code": "PersistentKeepalive = 25", "note": "A única linha de que um laptop atrás de NAT precisa e um roteador não. A seção sobre roaming diz por quê."}]}
```

**Um par não tem nome no protocolo, só uma chave pública.** `# the branch office` e `# Ana, at home` são
comentários para quem lê o arquivo; o `wg` nunca os imprime, e a seção sobre o OpenVPN volta ao que isso
custa.

Duas linhas decidem quase tudo no resto desta aula. `Endpoint` diz para onde mandar os pacotes de um par,
e o par de casa não tem, porque ninguém sabe de antemão onde a Ana vai estar. `AllowedIPs` diz quais
endereços pertencem a um par, e a seção sobre cryptokey routing mostra que ele significa duas coisas ao
mesmo tempo.
