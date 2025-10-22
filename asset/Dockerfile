FROM node:22-alpine 

WORKDIR /app

# 1. キャッシュ最適化：
COPY package*.json ./ 
RUN npm install

# 2. プロジェクトのソースコードをコピー
COPY . .

EXPOSE 5173

CMD ["npm", "run", "dev"]