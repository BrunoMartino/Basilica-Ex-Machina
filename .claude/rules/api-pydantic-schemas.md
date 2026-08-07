# Pydantic API Contracts

For every API endpoint, define explicit Pydantic models for:
- request payloads (body/query/path when applicable)
- response payloads (success and error shapes)

## Required Practices

- Do not accept or return raw `dict`, `Any`, or untyped JSON structures.
- Validate incoming data with request schemas before business logic runs.
- Serialize responses through response schemas before returning to clients.
- Keep endpoint contracts stable and explicit; version schemas when breaking changes are needed.

## FastAPI Example

```python
# ❌ BAD
@router.post("/users")
async def create_user(payload: dict) -> dict:
    return {"id": 1, "name": payload.get("name")}

# ✅ GOOD
class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr

class CreateUserResponse(BaseModel):
    id: int
    name: str
    email: EmailStr

@router.post("/users", response_model=CreateUserResponse)
async def create_user(payload: CreateUserRequest) -> CreateUserResponse:
    return CreateUserResponse(id=1, name=payload.name, email=payload.email)
```
