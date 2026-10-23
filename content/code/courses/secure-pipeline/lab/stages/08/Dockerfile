# Build: the pinned dependencies, installed into one directory by the pip
# of an image that has one.
FROM python:3.13-slim AS build
COPY requirements.txt /
RUN pip install --no-cache-dir --target /packages -r /requirements.txt
RUN mkdir /data

# Run: the same Python and nothing else. No shell, no package manager, no
# pip, and a user that is not root.
FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
