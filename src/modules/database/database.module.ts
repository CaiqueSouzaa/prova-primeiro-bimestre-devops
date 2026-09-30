import { Module } from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";

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
                    logging: configService.get<string>('ORM_LOGGING') === 'true',
                    synchronize: configService.get<string>('ORM_SYNCHRONIZE') === 'true',
                };
            }
        })
    ]
})
export class DataBaseModule { }
