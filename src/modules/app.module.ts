import { Module } from '@nestjs/common';
import { DataBaseModule } from './database/database.module';
import { ReservaApplicationModule } from './reserva/reserva.application.module';

@Module({
  imports: [
    DataBaseModule,
    ReservaApplicationModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
