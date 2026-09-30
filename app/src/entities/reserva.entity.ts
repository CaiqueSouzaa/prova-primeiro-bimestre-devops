import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

@Entity('tb_reservas')
export class Reserva {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({
        name: 'cliente',
        nullable: false,
    })
    cliente: string;

    @Column({
        name: 'data',
        nullable: false,
    })
    data: Date;

    @Column({
        name: 'status',
        nullable: false,
    })
    status: string;
}
