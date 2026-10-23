"""Lesson 1: what it takes to publish stored files, on premises and in the cloud."""
from figures import Fig, T, figure


@figure('l01-steps', 1)
def steps():
    f = Fig('l01-steps', 720, 330, T(
        'What it takes to make stored files reachable from the internet. On premises, four steps '
        'by four different people: the server team shares the directory, the network team puts the '
        'server where the internet can reach it, the firewall team opens a rule, and a change board '
        'approves. Any one of them can say no. In the cloud, one request to the API, put-bucket-policy, '
        'sent by whoever holds a key allowed to send it, takes effect in seconds, and nobody else has '
        'to agree.',
        'O que é preciso para tornar arquivos guardados alcançáveis pela internet. On-premises, quatro '
        'passos de quatro pessoas diferentes: a equipe de servidores compartilha o diretório, a equipe '
        'de rede põe o servidor onde a internet o alcança, a equipe do firewall abre uma regra e um '
        'comitê de mudanças aprova. Qualquer uma delas pode dizer não. Na nuvem, uma requisição à API, '
        'put-bucket-policy, enviada por quem tiver uma chave autorizada a enviá-la, vale em segundos, '
        'e ninguém mais precisa concordar.'))
    f.text(180, 24, T('on premises', 'on-premises'), size=12, weight='600', fill='--paper')
    f.text(540, 24, T('in the cloud', 'na nuvem'), size=12, weight='600', fill='--paper')
    f.line(360, 14, 360, 316, stroke='--wire', dash='4 4')
    rows = [
        (T('share the directory', 'compartilhar o diretório'), T('server team', 'equipe de servidores')),
        (T('move it where the internet reaches', 'pô-lo onde a internet alcança'), T('network team', 'equipe de rede')),
        (T('open a firewall rule', 'abrir uma regra no firewall'), T('firewall team', 'equipe do firewall')),
        (T('approve the change', 'aprovar a mudança'), T('change board', 'comitê de mudanças')),
    ]
    y = 50
    for i, (what, who) in enumerate(rows):
        f.rect(40, y, 280, 50, stroke='--paper-dim', fill='--scan')
        f.text(56, y + 18, what, size=10.5, anchor='start')
        f.text(56, y + 36, who, size=9.5, anchor='start', fill='--paper-dim', italic=True)
        f.text(304, y + 25, str(i + 1), size=11, weight='600', fill='--paper-dim', anchor='end')
        if i < len(rows) - 1:
            f.arrow([(180, y + 52), (180, y + 62)], stroke='--paper-dim')
        y += 64
    f.text(180, 316, T('any one of four people can say no', 'qualquer uma de quatro pessoas pode dizer não'),
           size=10, fill='--phosphor')
    f.rect(400, 130, 280, 70, stroke='--amber', fill='--scan', width=1.4)
    f.text(540, 154, 'aws s3api put-bucket-policy', size=10.5, mono=True)
    f.text(540, 178, T('whoever holds a key that may send it', 'quem tem uma chave que pode enviá-la'),
           size=9.5, fill='--paper-dim', italic=True)
    f.text(540, 228, T('in effect in seconds', 'vale em segundos'), size=10, fill='--amber')
    f.text(540, 248, T('nobody else has to agree', 'ninguém mais precisa concordar'), size=10, fill='--amber')
    return f, T('The same outcome, four approvals against one request. The cloud did not remove the '
                'decision; it removed the people who used to stand in front of it.',
                'O mesmo resultado, quatro aprovações contra uma requisição. A nuvem não tirou a decisão; '
                'tirou as pessoas que ficavam na frente dela.')
