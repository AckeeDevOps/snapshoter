FROM ubuntu:16.04

RUN apt-get update
RUN apt-get -y install lsb-release curl cron
RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
RUN echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update
RUN apt-get -y install google-cloud-sdk

CMD cron && tail -f /var/log/cron.log
