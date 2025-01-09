FROM gcr.io/instruqt/virtual-browser

COPY /c10e /c10e
RUN chown -R user:user /c10e

COPY policies.json /usr/lib/firefox-esr/distribution/policies.json
RUN chmod 666 /usr/lib/firefox-esr/distribution/policies.json

COPY start.sh /start.sh
RUN chmod +x /start.sh

RUN apt-get update \
  && apt-get upgrade -y

RUN apt-get install zip -y
