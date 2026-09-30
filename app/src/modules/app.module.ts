import { Module } from '@nestjs/common';
import { DataBaseModule } from './database/database.module';
import { ReservaApplicationModule } from './reserva/reserva.application.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    DataBaseModule,
    ReservaApplicationModule,
    HealthModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
