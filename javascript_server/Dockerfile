FROM node:8


COPY ./package.json /srv
COPY ./server.js /srv

WORKDIR /srv

RUN npm install

ENTRYPOINT ["node", "server.js"]

