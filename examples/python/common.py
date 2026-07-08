from io import BytesIO
from pathlib import Path
import os

from calcasa.api.api_client import ApiClient
from dotenv import load_dotenv

from oauth import OauthConfiguration
from brotli import MODE_GENERIC, MODE_TEXT, Compressor

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

from gzip import GzipFile
from collections import deque


CHUNK = 1024 * 1024

class Buffer (object):
    def __init__ (self):
        self.__buf = deque()
        self.__size = 0
    def __len__ (self):
        return self.__size
    def write (self, data):
        self.__buf.append(data)
        self.__size += len(data)
    def read (self, size=-1) -> bytes:
        if size < 0: size = self.__size
        ret_list = []
        while size > 0 and len(self.__buf):
            s = self.__buf.popleft()
            size -= len(s)
            ret_list.append(s)
        if size < 0:
            ret_list[-1], remainder = ret_list[-1][:size], ret_list[-1][size:]
            self.__buf.appendleft(remainder)
        ret = b''.join(ret_list)
        self.__size -= len(ret)
        return ret
    def flush (self):
        pass
    def close (self):
        pass

class GzipCompressReadStream (object):
    def __init__ (self, fileobj, compresslevel=2):
        self.__input = fileobj
        self.__buf = Buffer()
        self.__gzip = GzipFile(None, mode='wb', compresslevel=compresslevel, fileobj=self.__buf)
    def read (self, size=-1) -> bytes:
        while size < 0 or len(self.__buf) < size:
            s = self.__input.read(CHUNK)
            if not s:
                self.__gzip.close()
                break
            self.__gzip.write(s)
        return self.__buf.read(size)
    
class BrotliCompressReadStream(object):
    def __init__ (self, fileobj, compresslevel=2, mode=MODE_GENERIC):
        self.__input = fileobj
        self.__buf = Buffer()
        self.__brotli = Compressor(quality=compresslevel, mode=mode)
    def read (self, size=-1) -> bytes:
        while size < 0 or len(self.__buf) < size:
            s = self.__input.read(CHUNK)
            #print("Read chunk of size", len(s), "bytes from file", self.__input.name)
            if not s:
                #print("Finishing brotli compression for file", self.__input.name)
                self.__buf.write(self.__brotli.finish())
                break
            #print("Compressing chunk of size", len(s), "bytes for file", self.__input.name)
            comp = self.__brotli.process(s)
            self.__buf.write(comp)
            #print("Compressed chunk of size", len(comp), "bytes for file", self.__input.name, "total compressed size so far", len(self.__buf), "bytes")
        return self.__buf.read(size)