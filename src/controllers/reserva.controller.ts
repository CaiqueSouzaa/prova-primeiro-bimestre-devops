import { Body, Controller, Delete, Get, Param, Post, Put } from "@nestjs/common";
import { ReservaApplication } from "../applications/reserva/reserva.application";
import { CreateReservaDTO } from "../dto/reserva/create-reserva.dto";
import { ShowReservaDTO } from "../dto/reserva/show-reserva.dto";
import { UpdateReservaDTO } from "../dto/reserva/update-reserva.dto";
import { DeleteReservaDTO } from "../dto/reserva/delete-reserva.dto";

@Controller('reservas')
export class ReservaController {
    constructor(
        private readonly reservaApplication: ReservaApplication,
    ) {}

    @Post()
    public async create(@Body() data: CreateReservaDTO) {
        return this.reservaApplication.create(data);
    }

    @Get()
    public async find() {
        return this.reservaApplication.findAll();
    }

    @Get(':id')
    public async show(@Param() param: ShowReservaDTO) {
        return this.reservaApplication.show(param);
    }

    @Put(':id')
    public async update(@Param() param: ShowReservaDTO, @Body() data: UpdateReservaDTO) {
        data.id = param.id;
        return this.reservaApplication.update(data);
    }

    @Delete(':id')
    public async delete(@Param() param: DeleteReservaDTO) {
        return this.reservaApplication.delete(param);
    }
}
