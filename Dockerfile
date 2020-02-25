FROM php:7.4-cli-alpine3.11

WORKDIR /srv/app

RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS; \
    docker-php-ext-install -j$(nproc) pcntl; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .run-deps $runDeps; \
    apk del .build-deps \
    ;

ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN set -eux; \
    composer global require "symfony/flex" --prefer-dist --no-progress --no-suggest --classmap-authoritative; \
    composer clear-cache;

COPY src src/
COPY composer.json composer.lock psalm.xml ./

RUN set -eux; \
    composer install --prefer-dist --no-progress --no-suggest --classmap-authoritative; \
    composer clear-cache;
