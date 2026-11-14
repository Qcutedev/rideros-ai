"""Request body size cap (docs/SECURITY_AUDIT.md, OWASP API4 "Unrestricted Resource Consumption").

FastAPI parses a multipart form (and spools its files to disk) before the endpoint runs, so a
size check inside the endpoint comes too late. This middleware enforces the cap while the body
streams in: a declared Content-Length over the cap is refused before anything is read, and a
chunked body is cut off as soon as it passes the cap. Both answer 413 `payload_too_large`.
"""

from starlette.exceptions import HTTPException
from starlette.responses import JSONResponse
from starlette.types import ASGIApp, Message, Receive, Scope, Send

from app.core.errors import error_body

_MESSAGE = "Request body is too large"


class BodySizeLimitMiddleware:
    def __init__(self, app: ASGIApp, *, json_max_bytes: int, multipart_max_bytes: int) -> None:
        self.app = app
        self.json_max_bytes = json_max_bytes
        self.multipart_max_bytes = multipart_max_bytes

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        headers = dict(scope.get("headers") or [])
        content_type = headers.get(b"content-type", b"").decode("latin-1").lower()
        limit = self.multipart_max_bytes if content_type.startswith("multipart/") else self.json_max_bytes

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
