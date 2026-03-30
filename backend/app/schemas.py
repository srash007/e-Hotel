from typing import Optional, Literal
from datetime import date
from pydantic import BaseModel, Field


RoomCapacity = Literal["single", "double", "triple", "quad", "suite"]
RoomView = Literal["none", "sea", "mountain"]
PaymentMethod = Literal["cash", "card", "online", "transfer"]
CustomerIdType = Literal["SSN", "SIN", "DRIVER_LICENCE", "PASSPORT"]


class AvailabilitySearchParams(BaseModel):
    start_date: date
    end_date: date
    capacity: Optional[RoomCapacity] = None
    area: Optional[str] = None
    chain_id: Optional[int] = None
    star_min: Optional[int] = Field(default=None, ge=1, le=5)
    star_max: Optional[int] = Field(default=None, ge=1, le=5)
    total_rooms_min: Optional[int] = Field(default=None, ge=0)
    total_rooms_max: Optional[int] = Field(default=None, ge=0)
    price_min: Optional[float] = Field(default=None, ge=0)
    price_max: Optional[float] = Field(default=None, ge=0)


class BookingCreate(BaseModel):
    customer_id: int
    room_id: int
    start_date: date
    end_date: date


class BookingCancel(BaseModel):
    booking_id: int


class CheckInRequest(BaseModel):
    booking_id: int
    employee_id: int


class WalkInRequest(BaseModel):
    customer_id: int
    room_id: int
    start_date: date
    end_date: date
    employee_id: int


class PaymentCreate(BaseModel):
    renting_id: int
    amount: float = Field(ge=0)
    method: PaymentMethod


class CustomerCreate(BaseModel):
    full_name: str
    street: str
    city: str
    state: Optional[str] = None
    country: str
    postal_code: Optional[str] = None
    id_type: CustomerIdType
    id_value: str


class CustomerUpdate(BaseModel):
    full_name: Optional[str] = None
    street: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    postal_code: Optional[str] = None
    id_type: Optional[CustomerIdType] = None
    id_value: Optional[str] = None


class EmployeeCreate(BaseModel):
    hotel_id: int
    full_name: str
    street: str
    city: str
    state: Optional[str] = None
    country: str
    postal_code: Optional[str] = None
    ssn_sin: str


class HotelCreate(BaseModel):
    chain_id: int
    hotel_name: str
    star_rating: int = Field(ge=1, le=5)
    street: str
    city: str
    state: Optional[str] = None
    country: str
    postal_code: Optional[str] = None
    area: str


class RoomCreate(BaseModel):
    hotel_id: int
    room_number: str
    price_per_night: float = Field(ge=0)
    capacity: RoomCapacity
    view_type: RoomView = "none"
    extendable: bool = False
    problem_notes: Optional[str] = None