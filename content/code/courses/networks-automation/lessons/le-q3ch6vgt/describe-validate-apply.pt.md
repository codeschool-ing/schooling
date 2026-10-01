---
title: Descrever, validar, aplicar, verificar
version: 1
---

Os scripts até aqui misturam duas coisas: **o que a rede deve ser**, uma rede numa prefix list, e
**como levá-la até lá**, SSH e comandos. Separar as duas é o passo de um script para automação de
redes, e toda aula daqui em diante as mantém separadas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O ciclo que toda mudança deste curso segue. Descrever: intent.yaml no ctl diz o que a rede deve ser. Validar: verificações rodam no ctl, e um valor que falha nelas para ali. Aplicar: a mudança é enviada aos roteadores. Verificar: cada roteador é lido de volta e comparado com a descrição. Uma diferença achada ao verificar volta para descrever.\"><defs><marker id=\"cy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Descrever</text><text x=\"90.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que deve ser</text><text x=\"90.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">intent.yaml</text><rect x=\"200\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Validar</text><text x=\"270.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">verificações no ctl</text><text x=\"270.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes de qualquer roteador</text><rect x=\"380\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Aplicar</text><text x=\"450.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">enviar a mudança</text><text x=\"450.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Netmiko, NETCONF, API</text><rect x=\"560\" y=\"70\" width=\"140\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Verificar</text><text x=\"630.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ler de volta</text><text x=\"630.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">comparar com a intenção</text><path d=\"M162 110 L198 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><path d=\"M342 110 L378 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><path d=\"M522 110 L558 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><path d=\"M630 152 L630 200 L90 200 L90 154\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cy-ah)\"></path><text x=\"470\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma diferença volta para a descrição</text><path d=\"M270 152 L270 250\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cy-ah)\"></path><rect x=\"170\" y=\"252\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"270.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">recusado</text><text x=\"380\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum roteador chega a ver</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma mudança, quatro passos</text></svg>", "caption": "Descrever, validar, aplicar, verificar. As aulas 10 a 14 reforçam, cada uma, um dos quatro passos.", "same": ["intent.yaml", "Netmiko, NETCONF, API"]}
```

**Descrever** é escrever o estado desejado como dado. Aqui é um arquivo YAML no `ctl`:

```yaml
management_network: 192.0.2.0/24
routers:
  - core1
  - edge1
  - edge2
```

**Validar** é conferir essa descrição antes que qualquer coisa toque um equipamento, **aplicar**
a envia, e **verificar** lê cada equipamento de volta e compara:

```schooling-example
{
  "language": "python",
  "file": "apply.py",
  "parts": [
    {
      "code": "import ipaddress\nimport sys\n\nimport yaml\nfrom netmiko import ConnectHandler\n\nintent = yaml.safe_load(open(\"intent.yaml\"))\n",
      "note": "**Descrever.** O que a rede deve ser é um arquivo, não uma sequência de comandos. `yaml.safe_load` o transforma num dicionário."
    },
    {
      "code": "try:\n    net = ipaddress.ip_network(intent[\"management_network\"])\nexcept ValueError as e:\n    sys.exit(f\"refused: {e}\")\nif not net.subnet_of(ipaddress.ip_network(\"192.0.2.0/24\")):\n    sys.exit(f\"refused: {net} is not inside the management range 192.0.2.0/24\")\n",
      "note": "**Validar, antes de enviar qualquer coisa.** O valor tem de ser uma rede, e dentro da faixa de gerência do laboratório. A aula 13 constrói verificações de verdade; o que importa aqui é onde elas ficam: um valor ruim para no ctl, e nenhum roteador o vê."
    },
    {
      "code": "want = f\"ip prefix-list MGMT seq 10 permit {net}\"\nfor name in intent[\"routers\"]:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")\n    if want not in router.send_command(\"show running-config\").splitlines():\n        router.send_config_set([want])\n        router.save_config()\n    ok = want in router.send_command(\"show running-config\").splitlines()\n    router.disconnect()\n    print(f\"{name}: {'verified' if ok else 'NOT as intended'}\")",
      "note": "**Aplicar, depois verificar.** O último passo lê cada roteador de volta em vez de confiar que o envio deu certo."
    }
  ]
}
```

```
ana@ctl:~$ python apply.py
core1: verified
edge1: verified
edge2: verified
```

Agora a descrição é editada com o erro da primeira seção, e o script roda de novo:

```
ana@ctl:~$ sed -i 's#192.0.2.0/24#192.0.12.0/24#' intent.yaml
ana@ctl:~$ python apply.py; echo "exit status $?"
refused: 192.0.12.0/24 is not inside the management range 192.0.2.0/24
exit status 1
```

**O erro nunca chegou a um roteador.** Ele foi recusado no `ctl`, com uma frase dizendo por quê,
e o script terminou com status de saída diferente de zero, que é como um programa avisa o
próximo programa de um pipeline que falhou. A aula 14 depende exatamente disso: um pipeline que
para na primeira falha.

A verificação é pequena de propósito, e só pegou o erro porque este saiu da faixa de gerência.
Um erro que ficasse dentro dela, `192.0.2.0/25` por exemplo, teria passado. **A validação pega o
que alguém pensou em verificar**, e é por isso que a aula 13 a trata como um assunto próprio.

O resto do curso preenche cada caixa:

| passo | onde o curso o constrói |
|---|---|
| descrever | modelos YANG na aula 5, templates na aula 10, o NetBox como fonte da verdade na aula 12 |
| validar | aula 13, e o pipeline da aula 14 |
| aplicar | APIs nas aulas 2 a 4, bibliotecas Python na aula 8, Ansible na aula 9 |
| verificar | backups e diffs na aula 11, verificações de estado na aula 13 |
