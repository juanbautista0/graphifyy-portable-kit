FROM python:3.12.13-slim-trixie@sha256:57cd7c3a7a273101a6485ba99423ee568157882804b1124b4dd04266317710de

ARG GRAPHIFY_VERSION=0.9.22

LABEL org.opencontainers.image.title="Graphifyy"
LABEL org.opencontainers.image.description="Portable Graphifyy CLI for local repository knowledge graph generation"
LABEL org.opencontainers.image.version="${GRAPHIFY_VERSION}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://pypi.org/project/graphifyy/"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV HOME=/tmp

COPY docker/graphify-requirements.txt /tmp/graphify-requirements.txt

RUN python -m pip install --no-cache-dir --root-user-action=ignore -r /tmp/graphify-requirements.txt && \
    rm -f /tmp/graphify-requirements.txt && \
    groupadd --gid 10001 graphify && \
    useradd --uid 10001 --gid 10001 --home-dir /tmp --shell /usr/sbin/nologin --no-create-home --no-log-init graphify

WORKDIR /workspace

USER 10001:10001

ENTRYPOINT ["graphify"]

