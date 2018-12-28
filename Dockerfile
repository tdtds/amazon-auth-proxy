#
# Dockerfile for Amazon Auth Proxy
#
# need some ENVs:
#   AMAZON_ACCESS_KEY
#   AMAZON_SECRET_KEY
#
FROM ruby:2.6
LABEL maintainer "@tdtds <t@tdtds.jp>"

RUN mkdir /app
COPY ["Gemfile", "Gemfile.lock", "/app/"]

WORKDIR /app
RUN bundle --path=vendor/bundle --without=development:test --jobs=4 --retry=3
COPY [".", "/app/"]

ENV RACK_ENV=production
ENV TZ=Asia/Tokyo
EXPOSE 80
CMD ["bundle", "exec", "thin", "start", "-p", "80"]
