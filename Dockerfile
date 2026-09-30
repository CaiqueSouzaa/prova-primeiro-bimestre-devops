# syntax=docker/dockerfile:1

# Versão fixa do Node (mesma major usada no desenvolvimento local), nunca "latest"
ARG NODE_IMAGE=node:24-alpine

# ---------- 1. Dependências ----------
# Instala todas as dependências (inclusive dev, necessárias para o "nest build").
# Copiar só package.json + lockfile antes do código mantém esta camada em cache
# enquanto as dependências não mudarem.
FROM ${NODE_IMAGE} AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# ---------- 2. Build ----------
# Compila o TypeScript para dist/.
FROM ${NODE_IMAGE} AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json package-lock.json nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

# ---------- 3. Dependências de produção ----------
# Instala apenas o que é necessário em runtime (sem devDependencies).
FROM ${NODE_IMAGE} AS prod-deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# ---------- 4. Execução ----------
# Imagem final: só dist/ + node_modules de produção.
FROM ${NODE_IMAGE} AS runtime
ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app

COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./

# Usuário não-root que já existe na imagem oficial do Node
USER node

EXPOSE 3000

# As migrations pendentes são aplicadas na inicialização (migrationsRun no DataBaseModule).
# O healthcheck fica no docker-compose.yml; ele usa o wget do BusyBox, já presente no Alpine.
CMD ["node", "dist/main.js"]
