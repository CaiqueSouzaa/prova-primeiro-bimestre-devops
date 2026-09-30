import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/modules/app.module';

// Precisa de um PostgreSQL acessível a partir do host com as variáveis do .env
// (o docker-compose.yml não publica a 5432; use um Postgres local ou publique a porta).
describe('API de Reservas (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();
  });

  it('/health (GET)', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect({ status: 'ok', database: 'up' });
  });

  it('/reservas (POST) rejeita corpo inválido', () => {
    return request(app.getHttpServer()).post('/reservas').send({}).expect(400);
  });

  afterAll(async () => {
    await app.close();
  });
});
