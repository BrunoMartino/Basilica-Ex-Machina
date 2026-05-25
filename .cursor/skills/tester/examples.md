# Tester skill — supplementary examples

TypeScript-heavy samples below illustrate patterns only—use your project language, runner, and paths.

## AAA boilerplate

```typescript
it("should calculate the total discount for a given date range", () => {
  // Arrange
  const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
  const guest = new User("1", "John Doe");
  const dateRange = new DateRange(new Date("2026-05-01"), new Date("2026-05-11"));

  // Act
  const booking = new Booking("1", property, guest, dateRange, 2);

  // Assert
  expect(booking.getTotalPrice()).toBe(1800); // 10 nights * 200 = 2000 - 10% = 1800
});
```

## Good example: unit tests (Booking Entity)

```typescript
import { DateRange } from "../value_objects/date_range";
import { Property } from "./property";
import { User } from "./user";
import { Booking } from "./booking";

// em um sistema real, a criação deveria levar em conta uma interface com as demais regras e entidades envolvidas para evitar alto acoplamento e facilidade de teste

describe("Booking Entity", () => {
  it("should create a booking with an id, property, guest, date range, guest count and total price and get the id, property, guest, date range, guest count and total price", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-21"), new Date("2026-05-22"));
    const guestCount = 2;
    const booking = new Booking("1", property, guest, dateRange, guestCount);
    expect(booking.getId()).toBe("1");
    expect(booking.getProperty()).toBe(property);
    expect(booking.getGuest()).toBe(guest);
    expect(booking.getDateRange()).toBe(dateRange);
    expect(booking.getGuestCount()).toBe(guestCount);
    expect(booking.getTotalPrice()).toBe(200);
    expect(booking.getStatus()).toBe("CONFIRMED");
  });

  it("should throw an error if the guest count is not provided", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-10"), new Date("2026-05-15"));
    expect(() => new Booking("1", property, guest, dateRange, 0)).toThrow(
      "O número de hóspedes deve ser maior que zero."
    );
  });

  it("should throw an error if the guest count is greater than the property max guests", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-10"), new Date("2026-05-15"));
    expect(() => new Booking("1", property, guest, dateRange, 5)).toThrow(
      "Número máximo de hóspedes excedido. Máximo permitido: 4."
    );
  });

  it("should throw an error if the property is not available", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-10"), new Date("2026-05-15"));
    const booking = new Booking("1", property, guest, dateRange, 2);
    const dateRange1 = new DateRange(new Date("2026-05-11"), new Date("2026-05-16"));

    expect(() => new Booking("2", property, guest, dateRange1, 2)).toThrow(
      "A propriedade não está disponível para o período selecionado."
    );
  });

  it("should calculate the total discount for a given date range", () => {
    // Arrange
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-01"), new Date("2026-05-11"));

    // Act
    const booking = new Booking("1", property, guest, dateRange, 2);

    // Assert
    expect(booking.getTotalPrice()).toBe(1800); // 10 nights * 200 = 2000 - 10% = 1800
  });

  it("should return a full refund if the booking is cancelled 7 days or more before the check-in date", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-10"), new Date("2026-05-15"));
    const booking = new Booking("1", property, guest, dateRange, 2);
    booking.cancel(new Date("2026-05-01"));
    expect(booking.getTotalPrice()).toBe(0);
    expect(booking.getStatus()).toBe("CANCELLED");
  });

  it("should return a partial refund if the booking is cancelled between 1 and 7 days before the check-in date", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-10"), new Date("2026-05-15"));
    const booking = new Booking("1", property, guest, dateRange, 2);
    booking.cancel(new Date("2026-05-05"));
    expect(booking.getTotalPrice()).toBe(500);
    expect(booking.getStatus()).toBe("CANCELLED");
  });

  it("should not return a refund if the booking is cancelled less than 1 day before the check-in date", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-10"), new Date("2026-05-15"));
    const booking = new Booking("1", property, guest, dateRange, 2);
    booking.cancel(new Date("2026-05-10"));
    expect(booking.getTotalPrice()).toBe(1000);
    expect(booking.getStatus()).toBe("CANCELLED");
  });

  it("should throw a error if the booking is already cancelled", () => {
    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);
    const guest = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-10"), new Date("2026-05-15"));
    const booking = new Booking("1", property, guest, dateRange, 2);
    booking.cancel(new Date("2026-05-01"));
    expect(() => booking.cancel(new Date("2026-05-01"))).toThrow("A reserva já está cancelada.");
  });
});
```

## Good example: integration tests (TypeORMBookingRepository)

```typescript
import { DataSource } from "typeorm";
import { TypeORMBookingRepository } from "./typeorm_booking_repository";
import { BookingEntity } from "../persistence/entities/booking_entity";
import { PropertyEntity } from "../persistence/entities/property_entity";
import { UserEntity } from "../persistence/entities/user_entity";
import { Booking } from "../../domain/entities/booking";
import { User } from "../../domain/entities/user";
import { DateRange } from "../../domain/value_objects/date_range";
import { Property } from "../../domain/entities/property";

describe("TypeORMBookingRepository", () => {
  let dataSource: DataSource;
  let bookingRepository: TypeORMBookingRepository;

  beforeAll(async () => {
    dataSource = new DataSource({
      type: "sqlite",
      database: ":memory:",
      dropSchema: true,
      entities: [BookingEntity, PropertyEntity, UserEntity],
      synchronize: true,
      logging: false,
    });
    await dataSource.initialize();
    bookingRepository = new TypeORMBookingRepository(dataSource.getRepository(BookingEntity));
  });

  afterAll(async () => {
    await dataSource.destroy();
  });

  it("should create a booking", async () => {
    const propertyRepository = dataSource.getRepository(PropertyEntity);
    const userRepository = dataSource.getRepository(UserEntity);

    const propertyEntity = propertyRepository.create({
      id: "1",
      name: "Apartamento",
      description: "Apartamento moderno",
      maxGuests: 4,
      basePricePerNight: 200,
    });
    await propertyRepository.save(propertyEntity);

    const property = new Property(
      "1",
      "Casa na Praia",
      "Vista para o mar",
      6,
      200
    );

    const userEntity = userRepository.create({
      id: "1",
      name: "John Doe",
    });
    await userRepository.save(userEntity);

    const user = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-21"), new Date("2026-05-26"));

    const booking = new Booking("1", property, user, dateRange, 2);
    await bookingRepository.save(booking);

    const savedBooking = await bookingRepository.findById("1");

    expect(savedBooking).not.toBeNull();
    expect(savedBooking?.getId()).toBe("1");
    expect(savedBooking?.getProperty().getId()).toBe("1");
    expect(savedBooking?.getGuest().getId()).toBe("1");
  });

  it("should return null when a invalid id is provided", async () => {
    const booking = await bookingRepository.findById("999");
    expect(booking).toBeNull();
  });

  it("should save a booking, make a reservation and cancel it", async () => {
    const propertyRepository = dataSource.getRepository(PropertyEntity);
    const userRepository = dataSource.getRepository(UserEntity);

    const propertyEntity = propertyRepository.create({
      id: "1",
      name: "Apartamento",
      description: "Apartamento moderno",
      maxGuests: 4,
      basePricePerNight: 200,
    });
    await propertyRepository.save(propertyEntity);

    const property = new Property("1", "Apartamento", "Apartamento moderno", 4, 200);

    const userEntity = userRepository.create({
      id: "1",
      name: "John Doe",
    });
    await userRepository.save(userEntity);

    const user = new User("1", "John Doe");
    const dateRange = new DateRange(new Date("2026-05-21"), new Date("2026-05-26"));

    const booking = new Booking("1", property, user, dateRange, 2);
    await bookingRepository.save(booking);

    booking.cancel(new Date("2026-05-15"));
    await bookingRepository.save(booking);

    const updatedBooking = await bookingRepository.findById("1");

    expect(updatedBooking).not.toBeNull();
    expect(updatedBooking?.getStatus()).toBe("CANCELLED");
    expect(updatedBooking?.getTotalPrice()).toBe(500);
  });
});
```

## Bad example: unit test (never call subject, never assert)

Avoid this pattern—the test always passes.

```typescript
describe("BookingMapper", () => {
  it("should convert BookingEntity to Booking", () => {
    const bookingEntity = new BookingEntity();
    bookingEntity.id = "1";
    bookingEntity.property = new PropertyEntity();
    bookingEntity.property.id = "1";
    bookingEntity.property.name = "Apartamento";
    bookingEntity.property.description = "Apartamento moderno";
    bookingEntity.property.maxGuests = 4;
    bookingEntity.property.basePricePerNight = 200;
    // nunca chama o mapper, nunca faz assert — o teste sempre passa
  });
});
```

## Bad example: integration test (order-dependent)

Avoid this—the cancel case assumes booking `1` was created only by running the earlier test first.

```typescript
describe("BookingController", () => {
  it("should create a booking", async () => {
    const response = await request(app).post("/bookings").send({
      propertyId: "1",
      guestId: "1",
      startDate: "2026-05-21",
      endDate: "2026-05-22",
      guestCount: 2,
    });

    expect(response.status).toBe(201);
  });

  it("should cancel a booking", async () => {
    // depende do teste anterior — não cria a reserva aqui
    const cancelResponse = await request(app).post("/booking/1/cancel");

    expect(cancelResponse.status).toBe(200);
  });
});
```
