FROM ruby:2.2.6
MAINTAINER Milo van der Linden <milo@dogodigi.net>

# Environment variables, change as needed
# Configuring locales
ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV BUNDLE_PATH /bundle_cache
ENV CPLUS_INCLUDE_PATH=/usr/include/gdal
ENV C_INCLUDE_PATH=/usr/include/gdal
ENV PATH=$PATH:/carto/node_modules/grunt-cli/bin

ENV CARTO_ENV development
ENV CARTO_SESSION_DOMAIN localdomain
ENV CARTO_SESSION_PORT 3000

ENV MAP_API_HOST maps-api
ENV MAP_API_PORT 8181
ENV SQL_API_HOST sql-api
ENV SQL_API_PORT 8080

ENV DB_HOST db
ENV DB_PORT 5432
ENV DB_USER postgres

ENV REDIS_HOST redis
ENV REDIS_PORT 6379

# Setup OS
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends apt-utils make g++ git-core \
      unp \
      zip \
      libicu-dev \
      locales \
      lsb-release \
      gdal-bin libgdal1-dev libgdal-dev \
      python-all-dev python-pip \
      nodejs npm && \
      rm -rf /var/lib/apt/lists/* && \
      localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# In Debian, node executable is nodejs. Create symbolic link
RUN ln -s /usr/bin/nodejs /usr/bin/node

# Create a volume for gem files
VOLUME /bundle_cache

# Setup Carto
RUN git clone --depth 1 --branch master https://github.com/cartodb/cartodb.git /carto
WORKDIR /carto
RUN git submodule init && \
  git submodule foreach --recursive 'git rev-parse HEAD | xargs -I {} git fetch origin {} && git reset --hard FETCH_HEAD' && \
  git submodule update --recursive

# Carto configuration
COPY app_config.yml /carto/config/app_config.yml
COPY grunt_docker.json /carto/config/grunt_docker.json
COPY database.yml /carto/config/database.yml
COPY Gruntfile.js /carto/Gruntfile.js

# Node requirements
RUN npm cache clean && npm install -g n && n 0.10 && npm update -g npm@^2
RUN npm install .

# Python requirements
RUN pip install --no-use-wheel -r python_requirements.txt

# Create a volume for assets so we do not have to recreate them all the time
RUN mkdir -p /carto/public/assets
VOLUME /carto/public/assets

# Start
ADD run.sh /run.sh
RUN chmod 755 /*.sh

CMD ["/run.sh"]
