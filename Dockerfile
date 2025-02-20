FROM node:latest

COPY package.json app/
COPY src app/

WORKDIR /app

RUN npm install

EXPOSE 8181

CMD [ "node", "server.js"]

