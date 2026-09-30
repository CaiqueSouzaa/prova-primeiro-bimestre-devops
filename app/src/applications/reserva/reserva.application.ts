import { Injectable } from "@nestjs/common";
import { ReservaService } from "../../services/reserva/reserva.service";
import { Reserva } from "../../entities/reserva.entity";
import { CreateReservaDTO } from "../../dto/reserva/create-reserva.dto";
import { ShowReservaDTO } from "../../dto/reserva/show-reserva.dto";
import { UpdateReservaDTO } from "../../dto/reserva/update-reserva.dto";
import { DeleteReservaDTO } from "../../dto/reserva/delete-reserva.dto";
import { ResponseReserva } from "../../dto/reserva/response-reserva.dto";
import { ReservaMapper } from "../../mappers/reserva/reserva.mapper";

@Injectable()
export class ReservaApplication {
    constructor(
        private readonly reservaService: ReservaService,
    ) {}

    public async create(dto: CreateReservaDTO): Promise<ResponseReserva> {
        const reserva = ReservaMapper.fromCreateDTO(dto);

        const criada = await this.reservaService.create(reserva);

        return ResponseReserva.fromEntity(criada);
    }

    public async findAll(): Promise<Reserva[]> {
        return this.reservaService.find();
    }

    public async show(dto: ShowReservaDTO): Promise<ResponseReserva> {
        const reserva = await this.reservaService.show(dto.id);

        return ResponseReserva.fromEntity(reserva);
    }

    public async update(dto: UpdateReservaDTO): Promise<ResponseReserva> {
        const reserva = ReservaMapper.fromUpdateDTO(dto);

        const atualizada = await this.reservaService.update(reserva);

        return ResponseReserva.fromEntity(atualizada);
    }

    public async delete(dto: DeleteReservaDTO): Promise<void> {
        await this.reservaService.delete(dto.id);
    }
}
