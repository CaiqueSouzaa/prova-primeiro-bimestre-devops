import { Module } from "@nestjs/common";
import { ReservaModule } from "./reserva.module";
import { ReservaApplication } from "../../applications/reserva/reserva.application";
import { ReservaController } from "../../controllers/reserva.controller";

@Module({
    imports: [
        ReservaModule,
    ],
    controllers: [
        ReservaController,
    ],
    providers: [
        ReservaApplication,
    ],
})
export class ReservaApplicationModule {}
