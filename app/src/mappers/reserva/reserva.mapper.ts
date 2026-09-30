import { Reserva } from "../../entities/reserva.entity";
import { CreateReservaDTO } from "../../dto/reserva/create-reserva.dto";
import { UpdateReservaDTO } from "../../dto/reserva/update-reserva.dto";

export class ReservaMapper {
    public static fromCreateDTO(dto: CreateReservaDTO): Reserva {
        const reserva = new Reserva();
        reserva.cliente = dto.cliente;
        reserva.data = dto.data;
        reserva.status = dto.status;

        return reserva;
    }

    public static fromUpdateDTO(dto: UpdateReservaDTO): Reserva {
        // Campos não enviados ficam undefined e o service mantém o valor atual
        const reserva = new Reserva();
        reserva.id = dto.id;
        reserva.cliente = dto.cliente as string;
        reserva.data = dto.data as Date;
        reserva.status = dto.status as string;

        return reserva;
    }
}
