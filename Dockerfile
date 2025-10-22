FROM python:3.12-alpine AS build
RUN apk add --no-cache py3-pip && \
  apk add --no-cache build-base linux-headers python3-dev hdf5-dev git
COPY requirements.txt /tmp/requirements.txt
RUN pip wheel --no-cache-dir -w /wheels -r /tmp/requirements.txt

FROM python:3.12-alpine
COPY --from=build /wheels /wheels
RUN pip install --no-cache-dir --no-compile /wheels/* && rm -rf /wheels
RUN adduser -D -u 1000 jovyan
USER jovyan
CMD ["jupyter-lab", "--ip=0.0.0.0", "--port=8080", "--no-browser"]
