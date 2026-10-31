from fastapi import APIRouter

router = APIRouter()

@router.post("/create")
async def create_payment(amount: float, user_id: int):
    return {"payment_id": 1, "amount": amount, "status": "success", "user_id": user_id}

@router.get("/{payment_id}")
async def get_payment(payment_id: int):
    return {"payment_id": payment_id, "status": "paid"}

