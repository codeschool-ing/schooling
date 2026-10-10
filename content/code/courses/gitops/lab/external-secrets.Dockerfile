# The External Secrets Operator, built from its tagged source by lab.sh. The
# upstream image is the same binary on distroless/static, from gcr.io, which
# the recording machine cannot reach; this base carries the CA certificates
# the binary needs and nothing it uses besides.
FROM buildpack-deps:trixie-curl
COPY external-secrets /bin/external-secrets
USER 65534
ENTRYPOINT ["/bin/external-secrets"]
