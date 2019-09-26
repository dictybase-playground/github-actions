FROM dictybase/chrome-headless:latest

# Download latest Lighthouse build from npm
# Cache bust to ensure latest version when building the image
ARG CACHEBUST=1
RUN npm install -g lighthouse

# Disable Lighthouse error reporting to prevent prompt
ENV CI=true

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]