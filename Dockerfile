FROM node:20-alpine

WORKDIR /app

# Install deps first (better layer caching)
COPY package*.json ./
RUN npm ci --omit=dev || npm i --omit=dev

# Copy app code
COPY . .

ENV NODE_ENV=production
EXPOSE 3000

CMD ["node", "index.js"]
