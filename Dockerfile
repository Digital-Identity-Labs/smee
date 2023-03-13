FROM hexpm/elixir:1.14.2-erlang-25.3-alpine-3.17.2

LABEL description="Smee library" \
      maintainer="pete@digitalidentitylabs.com" \
       org.opencontainers.image.source="https://github.com/Digital-Identity-Labs/smee"


#RUN apk update \
#      && apk add ruby ruby-bigdecimal ruby-bundler ruby-io-console ruby-irb ca-certificates libressl libcurl libxslt libxml2 \
#      && apk add --virtual build-dependencies build-base ruby-dev libressl-dev libxml2-dev libxslt-dev pcre-dev libffi-dev \
#      && bundle config git.allow_insecure true \
#      && gem install json --no-document  \
#      && gem install mdqt xmldsig  --no-document \
#      && gem cleanup \
#      && apk del build-dependencies \
#      && rm -rf /usr/lib/ruby/gems/*/cache/* /var/cache/apk/* /tmp/* /var/tmp/*
#RUN   mkdir -p /opt/app && adduser -S mdqt && chown -R mdqt /opt/app
#
#USER mdqt
RUN apk add --update --no-cache libxslt xmlsec libxml2-utils curl bash ca-certificates
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
COPY . /opt/app
WORKDIR /opt/app
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get \
    && mix compile

# RUN rustup self uninstall
# ~/.cargo/.package-cache

#ENTRYPOINT ["/usr/local/bin/iex -S mix"]
#CMD ["iex -S mix"]
