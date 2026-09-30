import { DataSource } from "typeorm";
import { ENTITIES } from "./entities";
import { MIGRATIONS } from "./migrations";

// DataSource usado pela CLI do TypeORM (migration:generate, migration:run, migration:revert).
// A aplicação Nest usa a configuração do DataBaseModule.
// O .env fica na raiz do repositório; '../.env' cobre a execução a partir de app/.
for (const envFile of ['.env', '../.env']) {
    try {
        process.loadEnvFile(envFile);
        break;
    } catch {
        // Sem .env (ex.: dentro do contêiner): as variáveis já vêm do ambiente
    }
}

export default new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    username: process.env.DB_USERNAME,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_DATABASE,
    entities: ENTITIES,
    migrations: MIGRATIONS,
    logging: process.env.ORM_LOGGING === 'true',
});
