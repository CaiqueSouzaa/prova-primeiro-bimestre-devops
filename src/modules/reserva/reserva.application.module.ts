import { Module } from "@nestjs/common";
import { ReservaModule } from "./reserva.module";
import { ReservaApplication } from "../../applications/reserva/reserva.application";

@Module({
    imports: [
        ReservaModule,
    ],
    controllers: [
        
    ],
    providers: [
        ReservaApplication,
    ],
})
export class ReservaApplicationModule {}
