"""Grant or remove the admin role (the only way to make an admin; there is no API for it).

python -m scripts.set_role rider@example.com admin
python -m scripts.set_role rider@example.com rider
docker compose exec backend python -m scripts.set_role rider@example.com admin
"""

import argparse
import asyncio

from sqlalchemy import func, update

from app.core.config import get_settings
from app.db.session import create_engine, create_session_factory
from app.modules.users.models import USER_ROLES, User


async def _main(email: str, role: str) -> int:
    engine = create_engine(get_settings())
    try:
        async with create_session_factory(engine)() as session:
            result = await session.execute(
                update(User).where(func.lower(User.email) == email.strip().lower()).values(role=role)
            )
            await session.commit()
    finally:
        await engine.dispose()
    if result.rowcount == 0:  # type: ignore[attr-defined]
        print(f"No user with e-mail {email!r}")
        return 1
    print(f"{email}: role = {role}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("email")
    parser.add_argument("role", choices=USER_ROLES)
    args = parser.parse_args()
    return asyncio.run(_main(args.email, args.role))


if __name__ == "__main__":
    raise SystemExit(main())
