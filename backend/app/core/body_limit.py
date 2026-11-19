"""Request body size cap (docs/SECURITY_AUDIT.md, OWASP API4 "Unrestricted Resource Consumption").

FastAPI reads and parses the whole body before the endpoint runs, so a size check inside the
endpoint comes too late. This middleware enforces the cap while the body streams in: a declared
Content-Length over the cap is refused before anything is read, and a chunked body is cut off as
soon as it passes the cap. Both answer 413 `payload_too_large`. The API takes only JSON bodies, so
one cap applies to every content type.
"""

from starlette.exceptions import HTTPException
from starlette.responses import JSONResponse
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.core.errors import error_body

_MESSAGE = "Request body is too large"


class BodySizeLimitMiddleware:
    def __init__(self, app: ASGIApp, *, max_bytes: int) -> None:
        self.app = app
        self.max_bytes = max_bytes

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        headers = dict(scope.get("headers") or [])
        limit = self.max_bytes

        declared = headers.get(b"content-length")
        if declared is not None and (not declared.isdigit() or int(declared) > limit):
            response = JSONResponse(status_code=413, content=error_body("payload_too_large", _MESSAGE))
            await response(scope, receive, send)
            return

        received = 0

        async def limited_receive() -> Message:
            nonlocal received
            message = await receive()
            if message["type"] == "http.request":
                received += len(message.get("body", b""))
                if received > limit:
                    # FastAPI re-raises HTTPException from body parsing; the app's handler answers 413.
                    raise HTTPException(status_code=413, detail=_MESSAGE)
            return message

        await self.app(scope, limited_receive, send)
