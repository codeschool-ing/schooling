"""Lesson 9: the four grants that make an object public, and the guardrail above them."""
from figures import Fig, T, figure


@figure('l09-paths', 9)
def paths():
    f = Fig('l09-paths', 720, 360, T(
        'Four grants make an S3 object readable by somebody outside the account, and each lives in a '
        'different place. On the bucket: a bucket policy whose principal is a star, which answers '
        'everyone, and a bucket ACL granting READ to AllUsers, which lets everyone list the keys. On '
        'each object: an object ACL granting READ to AllUsers, which answers everyone, and an object '
        'ACL granting READ to AuthenticatedUsers, which answers anybody with an AWS account. Above all '
        'four sits Block Public Access, which refuses new public grants and ignores existing ones.',
        'Quatro concessões tornam um objeto do S3 legível por alguém de fora da conta, e cada uma mora '
        'num lugar diferente. No bucket: uma política de bucket cujo principal é uma estrela, que '
        'responde a todos, e uma ACL de bucket concedendo READ a AllUsers, que deixa todos listarem as '
        'chaves. Em cada objeto: uma ACL de objeto concedendo READ a AllUsers, que responde a todos, e '
        'uma ACL de objeto concedendo READ a AuthenticatedUsers, que responde a qualquer um com conta '
        'na AWS. Acima das quatro fica o Block Public Access, que recusa concessões públicas novas e '
        'ignora as existentes.'))
    f.rect(30, 16, 660, 50, stroke='--phosphor', fill='--scan', width=1.4)
    f.text(360, 34, T('Block Public Access, above every grant', 'Block Public Access, acima de toda concessão'),
           size=11, weight='600', fill='--phosphor')
    f.text(360, 53, T('refuses new public grants and ignores the ones already written',
                      'recusa concessões públicas novas e ignora as já escritas'), size=9.5, fill='--paper-dim')
    f.rect(30, 84, 660, 262, stroke='--paper-dim', fill='--panel', dash='6 4')
    f.text(46, 102, T('the bucket', 'o bucket'), size=10.5, anchor='start', weight='600', fill='--paper-dim')
    f.text(470, 102, T('who it answers', 'a quem responde'), size=10, anchor='start', weight='600',
           fill='--paper-dim')
    rows = [
        (130, '1', T('bucket policy', 'política de bucket'), 'Principal: "*"',
         T('everyone', 'todos'), None),
        (178, '2', T('bucket ACL', 'ACL do bucket'), 'AllUsers READ',
         T('everyone, as a list of keys', 'todos, como lista de chaves'), None),
        (262, '3', T('object ACL', 'ACL do objeto'), 'AllUsers READ',
         T('everyone', 'todos'), None),
        (310, '4', T('object ACL', 'ACL do objeto'), 'AuthenticatedUsers READ',
         T('anybody with an AWS account', 'qualquer um com conta na AWS'), None),
    ]
    f.rect(46, 222, 400, 112, stroke='--wire', fill='--scan')
    f.text(62, 238, T('each object, on its own', 'cada objeto, por conta própria'), size=10, anchor='start',
           weight='600', fill='--paper-dim')
    for y, n, what, code, who, _ in rows:
        f.circle(70, y, 10, fill=None, stroke='--amber', width=1.4)
        f.text(70, y + 0.5, n, size=10, weight='600', fill='--amber')
        f.text(90, y - 7, what, size=10.5, anchor='start')
        f.text(90, y + 9, code, size=9.5, anchor='start', mono=True, fill='--paper-dim')
        f.arrow([(400, y), (462, y)], stroke='--amber')
        f.text(470, y, who, size=10, anchor='start', fill='--amber')
    return f, T('A review that reads only the bucket policy sees route 1. Routes 3 and 4 are set file by '
                'file and never show on the bucket, and route 4 refuses the anonymous test that would '
                'catch it.',
                'Uma revisão que lê só a política de bucket vê o caminho 1. Os caminhos 3 e 4 são definidos '
                'arquivo por arquivo e nunca aparecem no bucket, e o caminho 4 recusa o teste anônimo que o '
                'pegaria.')
