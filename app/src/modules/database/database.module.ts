import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";
import { ENTITIES } from "../../database/entities";
import { MIGRATIONS } from "../../database/migrations";

@Module({
    imports: [
        ConfigModule.forRoot({
            envFilePath: '.env',
        }),
        TypeOrmModule.forRootAsync({
            imports: [
                ConfigModule,
            ],
            inject: [
                ConfigService,
            ],
            useFactory: (configService: ConfigService) => {
                return {
                    type: 'postgres',
                    host: configService.get<string>('DB_HOST'),
                    port: configService.get<number>('DB_PORT'),
                    username: configService.get<string>('DB_USERNAME'),
                    password: configService.get<string>('DB_PASSWORD'),
                    database: configService.get<string>('DB_DATABASE'),
                    entities: ENTITIES,
                    migrations: MIGRATIONS,
                    // Executa as migrations pendentes ao subir; as já aplicadas ficam registradas na tabela "migrations"
                    migrationsRun: true,
                    logging: configService.get<string>('ORM_LOGGING') === 'true',
                    synchronize: configService.get<string>('ORM_SYNCHRONIZE') === 'true',
                };
            }
        })
    ]
})
export class DataBaseModule { }
