import { BadRequestException, Injectable, NotFoundException } from "@nestjs/common";
import { ReservaRepository } from "../../repositories/reserva/reserva.repository";
import { Reserva } from "../../entities/reserva.entity";

@Injectable()
export class ReservaService {
    constructor(
        private readonly repository: ReservaRepository,
    ) { }

    public async create(reserva: Reserva): Promise<Reserva> {
        // Monta uma nova reserva sem o id, para que o save sempre insira em vez de atualizar
        const novaReserva = new Reserva();
        novaReserva.cliente = this.validarCliente(reserva.cliente);
        novaReserva.data = this.validarData(reserva.data);
        novaReserva.status = this.validarStatus(reserva.status);

        return this.repository.create(novaReserva);
    }

    public async find(): Promise<Reserva[]> {
        return this.repository.find();
    }

    public async show(id: number): Promise<Reserva> {
        const idReserva: number = this.validarId(id);
        const reserva: Reserva | null = await this.repository.show(idReserva);

        if (!reserva) {
            throw new NotFoundException(`ID de reserva ${ idReserva } não localizada`);
        }

        return reserva;
    }

    public async update(data: Reserva): Promise<Reserva> {
        // A reserva precisa existir, senão o save criaria uma nova
        const reserva = await this.show(data.id);

        // Atualiza apenas os campos enviados, validando cada um
        if (data.cliente !== undefined) {
            reserva.cliente = this.validarCliente(data.cliente);
        }

        if (data.data !== undefined) {
            reserva.data = this.validarData(data.data);
        }

        if (data.status !== undefined) {
            reserva.status = this.validarStatus(data.status);
        }

        return this.repository.update(reserva);
    }

    public async delete(id: number): Promise<void> {
        await this.show(id);
        return this.repository.delete(id);
    }

    // Id precisa ser um inteiro positivo
    private validarId(id: number | string | undefined | null): number {
        const idReserva = Number(id);

        if (!Number.isInteger(idReserva) || idReserva <= 0) {
            throw new BadRequestException('Id da reserva inválido');
        }

        return idReserva;
    }

    // Nome do cliente é obrigatório
    private validarCliente(cliente: string | undefined | null): string {
        if (!cliente || cliente.trim().length === 0) {
            throw new BadRequestException('Nome de cliente é obrigatório');
        }

        return cliente.trim();
    }

    // Data é obrigatória e precisa ser válida
    private validarData(data: Date | string | undefined | null): Date {
        if (!data) {
            throw new BadRequestException('Data é obrigatória');
        }

        const dataReserva = new Date(data);

        if (isNaN(dataReserva.getTime())) {
            throw new BadRequestException('Data inválida');
        }

        return dataReserva;
    }

    // Status é obrigatório
    private validarStatus(status: string | undefined | null): string {
        if (!status || status.trim().length === 0) {
            throw new BadRequestException('Status é obrigatório');
        }

        return status.trim();
    }
}
