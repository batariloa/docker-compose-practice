#base

FROM node:16 as base

EXPOSE 80
WORKDIR /app
COPY package*.json ./

RUN npm config list
RUN npm ci \
    && npm cache clean --force


ENV PATH /app/node_modules/.bin:$PATH

CMD ["node", "server.js"]

#DEVELOPMENT

FROM base as dev
ENV NODE_ENV=development

# NOTE: these apt dependencies are only needed
# for testing. they shouldn't be in production
RUN apt-get update -qq \
    && apt-get install -qy --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    libfontconfig \
    && rm -rf /var/lib/apt/lists/*
RUN npm config list
RUN npm install --only=development \
    && npm cache clean --force 
COPY . .
CMD ["nodemon", "server.js"]



#TEST
FROM dev as test
COPY . .
RUN npm audit fix --force
RUN npm audit

#PREPROD
FROM test as preprod
RUN rm -rf ./tests && rm -rf ./node_modules



FROM base as prod
COPY --from=preprod /app /app

HEALTHCHECK CMD curl http://127.0.0.1/ || exit 1
CMD ["node", "server.js"]
