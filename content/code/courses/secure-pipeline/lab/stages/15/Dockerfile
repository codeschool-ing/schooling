# Build: the pinned dependencies, installed from the wheels the pipeline
# downloaded and checked against requirements.txt. The build itself runs
# with no network, so it can read nothing it was not handed.
FROM python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS build
COPY requirements.txt /
COPY wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links /wheels --require-hashes \
    --target /packages -r /requirements.txt
RUN mkdir /data

# Run: the same Python and nothing else. No shell, no package manager, no
# pip, and a user that is not root. Both images are named by digest, so a
# tag that moves upstream changes nothing here until somebody changes it.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
