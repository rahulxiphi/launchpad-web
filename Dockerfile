FROM debian:bullseye-slim AS build

ARG API_BASE_URL

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    wget \
    gnupg \
    chromium \
    libgtk-3-0 \
    && rm -rf /var/lib/apt/lists/*

ENV CHROME_BIN=/usr/bin/chromium
ENV CHROME_PATH=/usr/lib/chromium/

RUN useradd -m -s /bin/bash flutter
RUN chown -R flutter:flutter /home/flutter

ENV FLUTTER_HOME="/flutter"
ENV FLUTTER_VERSION="3.38.1"
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
WORKDIR $FLUTTER_HOME
RUN git fetch && git checkout $FLUTTER_VERSION
RUN chown -R flutter:flutter $FLUTTER_HOME

USER flutter
RUN flutter precache
RUN flutter config --enable-web

WORKDIR /app
COPY --chown=flutter:flutter . .

RUN flutter pub get
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL:-http://localhost:8010/api/v1}

FROM nginx:alpine AS production

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
