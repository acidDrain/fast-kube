FROM node:9


COPY ./package.json /srv
COPY ./server.js /srv

WORKDIR /srv

RUN npm install

ENTRYPOINT ["node", "server.js"]

