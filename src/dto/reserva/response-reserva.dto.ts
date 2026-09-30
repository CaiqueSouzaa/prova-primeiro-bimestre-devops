import { Reserva } from "../../entities/reserva.entity";

export class ResponseReserva {
    id: number;
    cliente: string;
    data: Date;
    status: string;

    public static fromEntity(reserva: Reserva): ResponseReserva {
        const response = new ResponseReserva();
        response.id = reserva.id;
        response.cliente = reserva.cliente;
        response.data = reserva.data;
        response.status = reserva.status;

        return response;
    }
}
