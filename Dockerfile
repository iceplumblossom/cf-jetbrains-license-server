FROM alpine as cmdTest
ADD entrypoint.sh .
ADD register.sh .
ADD register_test.sh .
ADD register_mock.sh ./register
ENV LCSRV_HOME /
ENV SLEEPING 0

RUN chmod +x ./register \
  && ./register_test.sh

FROM golang:1.10-alpine as build

WORKDIR /go/src/register
ADD register.go .

RUN apk add --no-cache \
 git \
 && go get gopkg.in/headzoo/surf.v1 \
 && go get github.com/PuerkitoBio/goquery \
 && go build register.go \
 && chmod +x ./register

FROM java:8-jre-alpine as runtime

ENV LCSRV_HOME /usr/bin/jetbrains/license-server
ENV SLEEPING 30
COPY --from=build /go/src/register/register $LCSRV_HOME/

RUN apk add --no-cache \
 ca-certificates \
 wget \
 openssl \
 && wget -q https://download.jetbrains.com/lcsrv/license-server-installer.zip \
 && mkdir -p $LCSRV_HOME \
 && unzip license-server-installer.zip -d $LCSRV_HOME \
 && rm -f license-server-installer.zip

ADD entrypoint.sh /entrypoint.sh
ADD register.sh /register.sh

EXPOSE 8111

WORKDIR $LCSRV_HOME

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
