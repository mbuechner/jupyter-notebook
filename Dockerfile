FROM python:3.12-alpine AS build
RUN apk add --no-cache py3-pip && \
  apk add --no-cache build-base linux-headers python3-dev hdf5-dev git
COPY requirements.txt /tmp/requirements.txt
RUN pip wheel --no-cache-dir -w /wheels -r /tmp/requirements.txt

FROM python:3.12-alpine
LABEL maintainer="Michael Büchner <m.buechner@dnb.de>"

USER root
RUN apk add --no-cache bash ca-certificates tzdata curl tini sudo shadow
ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=1000
RUN addgroup -g ${NB_GID} -S ${NB_USER} \
 && adduser  -u ${NB_UID} -G ${NB_USER} -S -D -h /home/${NB_USER} -s /bin/bash ${NB_USER} \
 && chown -R ${NB_UID}:${NB_GID} /home/${NB_USER}
COPY --chmod=+x run-hooks.sh start.sh /usr/local/bin/
COPY --from=build /wheels /wheels
RUN pip install --no-cache-dir --no-compile /wheels/* \
 && rm -rf /wheels \
 && mkdir -p /usr/local/bin/start-notebook.d /usr/local/bin/before-notebook.d

# USER ${NB_UID}
WORKDIR /home/${NB_USER}
ENV HOME=/home/${NB_USER}
ENV NB_USER=${NB_USER}
ENV NB_UID=${NB_UID}
ENV NB_GID=${NB_GID}

EXPOSE 8888

# Init + Singleuser als Standard
ENTRYPOINT ["/sbin/tini", "-g", "--", "/usr/local/bin/start.sh"]
CMD ["jupyterhub-singleuser"]
