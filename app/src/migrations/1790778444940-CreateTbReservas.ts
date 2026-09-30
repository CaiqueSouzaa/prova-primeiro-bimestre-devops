import { MigrationInterface, QueryRunner } from "typeorm";

export class CreateTbReservas1790778444940 implements MigrationInterface {
    name = 'CreateTbReservas1790778444940'

    public async up(queryRunner: QueryRunner): Promise<void> {
        // IF NOT EXISTS: bancos que já tinham a tabela criada pelo synchronize apenas registram a migration
        await queryRunner.query(`CREATE TABLE IF NOT EXISTS "tb_reservas" ("id" SERIAL NOT NULL, "cliente" character varying NOT NULL, "data" TIMESTAMP NOT NULL, "status" character varying NOT NULL, CONSTRAINT "PK_1ec24572f37959046ce280d48fc" PRIMARY KEY ("id"))`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE "tb_reservas"`);
    }

}
