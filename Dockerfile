FROM python:3.5-slim-jessie

# ensure unoconv can locate the uno library
ENV PYTHONPATH=/usr/lib/python3/dist-packages

RUN usermod -d /home www-data \
    && chown www-data:www-data /home \
    && apt-get update \
    # mfr dependencies
    && apt-get install -y \
        git \
        make \
        gcc \
        build-essential \
        gfortran \
        r-base \
        libblas-dev \
        libevent-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libpng12-dev \
        libtiff5-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        # convert .step to jsc3d-compatible format
        freecad \
        # pspp dependencies
        pspp \
        # gosu dependencies
        curl \
    # gosu
    && export GOSU_VERSION='1.10' \
    && gpg --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
  	&& curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
  	&& gpg --verify /usr/local/bin/gosu.asc \
  	&& rm /usr/local/bin/gosu.asc \
  	&& chmod +x /usr/local/bin/gosu \
    # /gosu
    && apt-get clean \
    && apt-get autoremove -y \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && pip install -U pip \
    && pip uninstall -y setuptools \
    && rm -f /usr/local/lib/python3.5/site-packages/mfr-nspkg.pth \
    && pip install setuptools==30.4.0 \
    && mkdir -p /code

ENV LIBREOFFICE_VERSION 6.0.1.1
ENV LIBREOFFICE_ARCHIVE LibreOffice_6.0.1.1_Linux_x86-64_deb.tar.gz
RUN apt-get update \
    && apt-get install -y \
        curl \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys AFEEAEA3 \
    && curl -SL "https://downloadarchive.documentfoundation.org/libreoffice/old/$LIBREOFFICE_VERSION/deb/x86_64/$LIBREOFFICE_ARCHIVE" -o $LIBREOFFICE_ARCHIVE \
    && curl -SL "https://downloadarchive.documentfoundation.org/libreoffice/old/$LIBREOFFICE_VERSION/deb/x86_64/$LIBREOFFICE_ARCHIVE.asc" -o $LIBREOFFICE_ARCHIVE.asc \
    && gpg --verify "$LIBREOFFICE_ARCHIVE.asc" \
    && mkdir /tmp/libreoffice \
    && tar -xvf "$LIBREOFFICE_ARCHIVE" -C /tmp/libreoffice/ --strip-components=1 \
    && dpkg -i /tmp/libreoffice/**/*.deb \
    && rm $LIBREOFFICE_ARCHIVE* \
    && rm -Rf /tmp/libreoffice \
    && apt-get clean \
    && apt-get autoremove -y \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install unoconv==0.8.2

WORKDIR /code

COPY ./requirements.txt ./

RUN pip install --no-cache-dir -r ./requirements.txt

# Copy the rest of the code over
COPY ./ ./

ARG GIT_COMMIT=
ENV GIT_COMMIT ${GIT_COMMIT}

RUN python setup.py develop

EXPOSE 7778

CMD ["gosu", "www-data", "invoke", "server"]
