"""THE STAND-IN SCORER. It is not a model and it learned nothing.

It is four lines of arithmetic the course wrote to behave the way a model
trained on Tarefa's past hires would plausibly behave. Most of Tarefa's
clients are in the Southeast and have mostly hired freelancers near them, so
a model fitted to who got hired learns that nearness predicts a hire. The
stand-in says that outright: a bonus for a CEP that starts with 0, 1, 2 or 3,
which are the postcodes of São Paulo, Rio de Janeiro, Espírito Santo and
Minas Gerais.

It never reads the `region` field. That is the point of it: the CEP carries
the region in, and removing the protected column removed nothing.
"""
THRESHOLD = 6.0


def score(profile):
    s = 1.0 * profile["rating"] + 0.05 * profile["jobs"]
    if profile["cep"][0] in "0123":
        s += 1.0
    return round(s, 2)
