FROM node:18-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

# Variables de entorno por defecto (se sobreescriben en K8s)
ENV APP_VERSION=1.0.0
ENV APP_TYPE=stable
ENV FAIL_AFTER=0

CMD ["node", "server.js"]
