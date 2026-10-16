# Argo CD's image, laid out as upstream's Dockerfile lays it out, from the
# released argocd-linux-amd64 binary. The base differs: buildpack-deps already
# carries git, gpg and ssh, which upstream installs with apt into Ubuntu, and
# this machine cannot reach an apt mirror from inside a build. No tini either;
# every Argo CD container names its own command.
FROM buildpack-deps:trixie-scm
RUN groupadd -g 999 argocd && useradd -r -u 999 -g argocd argocd && \
    mkdir -p /home/argocd && chown argocd:0 /home/argocd && chmod g=u /home/argocd
COPY gpg-wrapper.sh git-verify-wrapper.sh entrypoint.sh helm kustomize argocd /usr/local/bin/
RUN chmod 0755 /usr/local/bin/* && ln -s /usr/local/bin/entrypoint.sh /usr/local/bin/uid_entrypoint.sh
WORKDIR /app/config/ssh
RUN touch ssh_known_hosts && ln -sf /app/config/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts
WORKDIR /app/config
RUN mkdir -p tls gpg/source gpg/keys && chown argocd gpg/keys && chmod 0700 gpg/keys
RUN for n in server repo-server cmp-server application-controller dex notifications \
      applicationset-controller k8s-auth commit-server; do \
      ln -s /usr/local/bin/argocd /usr/local/bin/argocd-$n; done
ENV USER=argocd GRPC_ENABLE_TXT_SERVICE_CONFIG=false
USER 999
WORKDIR /home/argocd
