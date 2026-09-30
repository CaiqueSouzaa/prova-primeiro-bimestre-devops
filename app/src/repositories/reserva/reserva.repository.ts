import { Injectable } from "@nestjs/common";
import { DataSource, Repository } from "typeorm";
import { Reserva } from "../../entities/reserva.entity";

@Injectable()
export class ReservaRepository {
    private repository: Repository<Reserva>;

    constructor(
        private readonly dataSource: DataSource,
    ) {
        this.repository = this.dataSource.getRepository<Reserva>(Reserva);
    }

    public async create(reserva: Reserva): Promise<Reserva> {
        return this.repository.save(reserva);
    }

    public async find(): Promise<Reserva[]> {
        return this.repository.find();
    }

    public async show(id: number): Promise<Reserva | null> {
        return this.repository.findOne({
            where: {
                id: id,
            },
        });
    }

    public async update(data: Reserva): Promise<Reserva> {
        return this.repository.save(data);
    }

    public async delete(id: number): Promise<void> {
        await this.repository.delete(id);
    }
}
