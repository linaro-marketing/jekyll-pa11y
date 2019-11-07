# Tool for providing link checks against a statically-built website.

# Set the base image to Ubuntu (version 18.04).
# Uses the new "ubuntu-minimal" image.
FROM ubuntu:18.04
# FROM alekzonder/puppeteer:1

LABEL maintainer="it-services@linaro.org"

USER root

################################################################################
# Install locale packages from Ubuntu repositories and set locale.
RUN export DEBIAN_FRONTEND=noninteractive && \
 apt-get clean -y && \
 apt-get update && \
 apt-get install apt-utils -y && \
 apt-get upgrade -y && \
 apt-get install -y language-pack-en && \
 locale-gen en_US.UTF-8 && \
 dpkg-reconfigure locales && \
 apt-get --purge autoremove -y && \
 apt-get clean -y \
 && \
 rm -rf \
 /tmp/* \
 /var/cache/* \
 /var/lib/apt/lists/* \
 /var/log/*

# Set the defaults
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

################################################################################
# Install unversioned dependency packages from Ubuntu repositories.

ENV UNVERSIONED_DEPENDENCY_PACKAGES \
 # Needed by the bash script to determine if this is the latest container.
 curl \
 jq \
 # Needed to install the Python packages
 python3-pip \
 python3-setuptools

RUN export DEBIAN_FRONTEND=noninteractive && \
 apt-get update && \
 apt-get upgrade -y && \
 apt-get install -y --no-install-recommends \
 ${UNVERSIONED_DEPENDENCY_PACKAGES} \
 && \
 apt-get --purge autoremove -y && \
 apt-get clean -y \
 && \
 rm -rf \
 /tmp/* \
 /var/cache/* \
 /var/lib/apt/lists/* \
 /var/log/*

# Install NodeJS
RUN apt-get update && apt-get install -y nodejs

# Install NPM
RUN apt-get -y install npm

# Install puppeteer dependencies
RUN apt-get update && \
apt-get install -yq gconf-service libasound2 libatk1.0-0  \
libc6 libcairo2 libcups2 libdbus-1-3 \
libexpat1 libfontconfig1 libgcc1 libgconf-2-4 \
libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6  \
libx11-xcb1 libxcb1 libxcomposite1 \
libxcursor1 libxdamage1 libxext6 libxfixes3 \
libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
fonts-ipafont-gothic fonts-wqy-zenhei \
fonts-thai-tlwg fonts-kacst  \
ca-certificates fonts-liberation libappindicator1  \
libnss3 lsb-release xdg-utils wget && \
wget https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64.deb && \
dpkg -i dumb-init_*.deb && rm -f dumb-init_*.deb && \
apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*


# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g puppeteer@1.8.0 && npm cache clean

ENV NODE_PATH="/usr/local/share/.config/npm/global/node_modules:${NODE_PATH}"

RUN mkdir /tools

ENV PATH="/tools:${PATH}"

RUN groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser

# COPY --chown=pptruser:pptruser /tools

# Set language to UTF8
ENV LANG="C.UTF-8"

WORKDIR /srv

# Add user so we don't need --no-sandbox.
RUN mkdir /screenshots \
	&& mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /usr/local/lib/node_modules \
    && chown -R pptruser:pptruser /screenshots
    # && chown -R pptruser:pptruser /app \
    # && chown -R pptruser:pptruser /tools

# Install pa11y
RUN npm install -g pa11y

COPY check-a11y.py check-a11y.sh /usr/local/bin/
COPY pa11y.config.json /tmp
RUN chmod a+rx /usr/local/bin/check-a11y.py /usr/local/bin/check-a11y.sh
# Run everything after as non-privileged user.
USER pptruser
ENTRYPOINT ["check-a11y.sh"]
