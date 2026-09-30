import { Type } from "class-transformer";
import { IsDate, IsNotEmpty, IsString } from "class-validator";

export class CreateReservaDTO {
    @IsString()
    @IsNotEmpty()
    cliente: string;

    @Type(() => Date)
    @IsDate()
    data: Date;

    @IsString()
    @IsNotEmpty()
    status: string;
}
