from pathlib import Path
import os

from calcasa.api.api_client import ApiClient
from dotenv import load_dotenv

from oauth import OauthConfiguration


DEFAULT_ENV_PATH = Path(__file__).resolve().parent.parent / ".env"
DEFAULT_USER_AGENT = "Python Application Name/0.0.1"


def load_example_environment(env_path: Path = DEFAULT_ENV_PATH) -> None:
    load_dotenv(env_path)


def get_required_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise Exception(
            f"Please set the {name} environment variable, or use a .env file with the correct value."
        )

    return value


def create_api_client(extra_required_env: list[str] | None = None) -> ApiClient:
    required_env = [
        "CALCASA_CLIENT_ID",
        "CALCASA_CLIENT_SECRET",
        "CALCASA_TOKEN_ENDPOINT",
        "CALCASA_API_BASE_URL",
    ]

    if extra_required_env:
        required_env.extend(extra_required_env)

    for env_name in required_env:
        get_required_env(env_name)

    conf = OauthConfiguration(
        client_id=os.environ["CALCASA_CLIENT_ID"],
        client_secret=os.environ["CALCASA_CLIENT_SECRET"],
        token_url=os.environ["CALCASA_TOKEN_ENDPOINT"],
        host=os.environ["CALCASA_API_BASE_URL"],
    )

    client = ApiClient(conf)
    client.user_agent = DEFAULT_USER_AGENT
    return client