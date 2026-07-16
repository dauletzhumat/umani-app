# Dev-образ: только для локальной разработки с hot-reload (docker-compose монтирует ./backend поверх /app).
# Production-сборка (multi-stage, без volume-монтирования) добавляется отдельно в задаче T0.5.
FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .

CMD ["npm", "run", "start:dev"]
