FROM node:22-alpine 

WORKDIR /app
# ここでは何もインストールしません
EXPOSE 3000
# コンテナがすぐ終了しないよう、シェルを起動させておく
CMD ["sh"]