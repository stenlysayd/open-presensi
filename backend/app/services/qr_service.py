import io
import uuid
import qrcode
from qrcode.image.pil import PilImage

def generate_member_qr_token(org_id: str, reg_number: str) -> str:
    """
    Generate unique QR token for member ID cards.
    Format: OP-{org_short}-{reg_number}-{random_hex}
    """
    clean_reg = reg_number.strip().replace(" ", "").upper()
    random_suffix = uuid.uuid4().hex[:6].upper()
    return f"OP-{clean_reg}-{random_suffix}"

def generate_qr_image_bytes(data: str) -> bytes:
    """
    Generate PNG bytes for a given QR code payload.
    """
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return buffer.getvalue()
