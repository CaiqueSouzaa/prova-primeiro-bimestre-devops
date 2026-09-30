import { Type } from "class-transformer";
import { IsDate, IsInt, IsNotEmpty, IsOptional, IsPositive, IsString } from "class-validator";

export class UpdateReservaDTO {
    @Type(() => Number)
    @IsInt()
    @IsPositive()
    id: number;

    @IsOptional()
    @IsString()
    @IsNotEmpty()
    cliente?: string;

    @IsOptional()
    @Type(() => Date)
    @IsDate()
    data?: Date;

    @IsOptional()
    @IsString()
    @IsNotEmpty()
    status?: string;
}
