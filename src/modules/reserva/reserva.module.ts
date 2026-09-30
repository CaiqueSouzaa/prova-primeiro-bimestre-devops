import { Module } from "@nestjs/common";
import { ReservaRepository } from "../../repositories/reserva/reserva.repository";
import { ReservaService } from "../../services/reserva/reserva.service";

@Module({
    imports: [],
    providers: [
        ReservaRepository,
        ReservaService,
    ],
    exports: [
        ReservaService,
    ],
})
export class ReservaModule {}
