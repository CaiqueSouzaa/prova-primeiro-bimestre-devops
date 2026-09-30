import { Controller, Get, ServiceUnavailableException } from "@nestjs/common";
import { DataSource } from "typeorm";

@Controller('health')
export class HealthController {
    constructor(
        private readonly dataSource: DataSource,
    ) {}

    @Get()
    public async check() {
        // Só está saudável se o banco responder
        try {
            await this.dataSource.query('SELECT 1');
        } catch {
            throw new ServiceUnavailableException({
                status: 'error',
                database: 'down',
            });
        }

        return {
            status: 'ok',
            database: 'up',
        };
    }
}
