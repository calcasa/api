#!/usr/bin/env python3
import re
import ruamel.yaml

import os
import shutil
from pathlib import Path
import os
import signal
import subprocess
import sys
import termios


yaml = ruamel.yaml.YAML()  # defaults to round-trip

NUGET_API_KEY = os.getenv("NUGET_API_KEY")

# TODO move to either 6.6 of 7.0
CLI_DOCKER_CONTAINER_VERSION = "openapitools/openapi-generator-cli:v7.13.0"

# API_URL = "http://192.168.2.189:9102"
API_URL = "https://api.staging.calcasa.nl"

MAIN_DIR = Path(".")
TEMPLATE_PATH = Path("templates")
CONFIG_PATH = Path("configs")
LIBRARY_DIR = Path("libraries")
GENERATED_DIR = Path("generated")
CHANGELOG_REGEX = re.compile(
    r"## (?P<date>[0-9]{4}-[0-9]{1,2}-[0-9]{1,2})\s+(\(v(?P<version>[0-9\.\-a-z]+)\)\s+)?(?P<changes>.+?)\s+##",
    re.S,
)
USERAGENT_REGEX = re.compile(r"([^/]+)/[^/]+")

GENERATORS = {
    "csharp": "csharp",
    "php": "php",
    "python": "python",
    "docs": "html2",
    "aspnetcore": "aspnetcore",
}

PUBLISHED_LIBRARIES = [
    "csharp",
    "php",
    "python",
]

PYTHON_SCHEMA_MAPPINGS = {
    "JsonPatchDocument": "list[Operation]",
}

CSHARP_SCHEMA_MAPPINGS_PUBLIC = {
    "ProblemDetails": "Microsoft.AspNetCore.Mvc.ProblemDetails",
    "ValidationProblemDetails": "Microsoft.AspNetCore.Mvc.ValidationProblemDetails",
    "JsonPatchDocument": "List<Microsoft.AspNetCore.JsonPatch.Operations.Operation>",
    "Operation": "Microsoft.AspNetCore.JsonPatch.Operations.Operation",
    "OperationType": "Microsoft.AspNetCore.JsonPatch.Operations.OperationType",
}

CSHARP_SCHEMA_MAPPINGS_SERVER = {
    "AddressMatcherProblemDetails": "Calcasa.Protocols.OnlineValuation.Details.AddressMatcherProblemDetails",
    "AlreadyExistsProblemDetails": "Calcasa.Protocols.Exceptions.Details.AlreadyExistsProblemDetails",
    "CredentialsExpiredProblemDetails": "Calcasa.Protocols.Exceptions.Details.CredentialsExpiredProblemDetails",
    "InvalidArgumentProblemDetails": "Calcasa.Protocols.Exceptions.Details.InvalidArgumentProblemDetails",
    "NotFoundProblemDetails": "Calcasa.Protocols.Exceptions.Details.NotFoundProblemDetails",
    "PermissionsDeniedProblemDetails": "Calcasa.Protocols.Exceptions.Details.PermissionsDeniedProblemDetails",
    "ResourceExhaustedProblemDetails": "Calcasa.Protocols.Exceptions.Details.ResourceExhaustedProblemDetails",
    "TooManyRequestsProblemDetails": "Calcasa.Protocols.Exceptions.Details.TooManyRequestsProblemDetails",
    "ValuationStateImpossibleProblemDetail": "Calcasa.Protocols.OnlineValuation.Details.ValuationStateImpossibleProblemDetail",
    "BusinessRulesProblemDetails": "Calcasa.Api.Exceptions.Details.BusinessRulesProblemDetails",
    "UnauthorizedProblemDetails": "Microsoft.AspNetCore.Mvc.ProblemDetails",  # TODO verifity
}


def die(msg: str = "Error"):
    print(msg)
    exit(1)


def run_as_fg_process(*args, **kwargs):
    """
    the "correct" way of spawning a new subprocess:
    signals like C-c must only go
    to the child process, and not to this python.

    the args are the same as subprocess.Popen

    returns Popen().wait() value

    Some side-info about "how ctrl-c works":
    https://unix.stackexchange.com/a/149756/1321

    """

    old_pgrp = os.tcgetpgrp(sys.stdin.fileno())
    old_attr = termios.tcgetattr(sys.stdin.fileno())

    user_preexec_fn = kwargs.pop("preexec_fn", None)

    def new_pgid():
        if user_preexec_fn:
            user_preexec_fn()

        # set a new process group id
        os.setpgid(os.getpid(), os.getpid())

        # generally, the child process should stop itself
        # before exec so the parent can set its new pgid.
        # (setting pgid has to be done before the child execs).
        # however, Python 'guarantee' that `preexec_fn`
        # is run before `Popen` returns.
        # this is because `Popen` waits for the closure of
        # the error relay pipe '`errpipe_write`',
        # which happens at child's exec.
        # this is also the reason the child can't stop itself
        # in Python's `Popen`, since the `Popen` call would never
        # terminate then.
        # `os.kill(os.getpid(), signal.SIGSTOP)`

    try:
        # fork the child
        child = subprocess.Popen(*args, preexec_fn=new_pgid, **kwargs)

        # we can't set the process group id from the parent since the child
        # will already have exec'd. and we can't SIGSTOP it before exec,
        # see above.
        # `os.setpgid(child.pid, child.pid)`

        # set the child's process group as new foreground
        os.tcsetpgrp(sys.stdin.fileno(), child.pid)
        # revive the child,
        # because it may have been stopped due to SIGTTOU or
        # SIGTTIN when it tried using stdout/stdin
        # after setpgid was called, and before we made it
        # forward process by tcsetpgrp.
        os.kill(child.pid, signal.SIGCONT)

        # wait for the child to terminate
        ret = child.wait()

    finally:
        # we have to mask SIGTTOU because tcsetpgrp
        # raises SIGTTOU to all current background
        # process group members (i.e. us) when switching tty's pgrp
        # it we didn't do that, we'd get SIGSTOP'd
        hdlr = signal.signal(signal.SIGTTOU, signal.SIG_IGN)
        # make us tty's foreground again
        os.tcsetpgrp(sys.stdin.fileno(), old_pgrp)
        # now restore the handler
        signal.signal(signal.SIGTTOU, hdlr)
        # restore terminal attributes
        termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, old_attr)

    return ret


def github_make_main_release(tag_name: str, release_msg: str, prerelease: bool = False):
    cwd = os.getcwd()
    result = run_as_fg_process(
        [
            "gh",
            "release",
            "create",
            "--repo",
            f"calcasa/api",
            "-t",
            tag_name,
            "-n",
            release_msg,
        ]
        + (["-p"] if prerelease else [])
        + [tag_name]
    )

    os.chdir(cwd)
    return result == 0


def github_make_release(
    language: str, dir: Path, tag_name: str, release_msg: str, prerelease: bool = False
):
    cwd = os.getcwd()
    os.chdir(dir)
    files = map(str, Path(".").glob("dist/*"))
    result = run_as_fg_process(
        [
            "gh",
            "release",
            "create",
            "--repo",
            f"calcasa/api-{language}",
            "-t",
            tag_name,
            "-n",
            release_msg,
        ]
        + (["-p"] if prerelease else [])
        + [tag_name]
        + list(files)
    )

    os.chdir(cwd)
    return result == 0


def pack_publish_csharp(dir: Path, publish: bool = False):
    cwd = os.getcwd()
    os.chdir(dir)
    result = run_as_fg_process(
        [
            "dotnet",
            "pack",
            "--interactive",
            "-c",
            "Release",
            "--verbosity",
            "Minimal",
            "-o",
            "dist",
            "src/Calcasa.Api/Calcasa.Api.csproj",
        ]
    )
    if publish and result == 0:
        files = map(str, Path(".").glob("dist/*.nupkg"))
        symb_files = map(str, Path(".").glob("dist/*.snupkg"))
        result = run_as_fg_process(
            [
                "dotnet",
                "nuget",
                "push",
                "--source",
                "https://api.nuget.org/v3/index.json",
                "--api-key",
                NUGET_API_KEY,
            ]
            + list(files)
            + list(symb_files)
        )

    os.chdir(cwd)
    return result == 0


def pack_publish_python(dir: Path, publish: bool = False):
    cwd = os.getcwd()
    os.chdir(dir)

    result = run_as_fg_process(["python3", "setup.py", "sdist", "bdist_wheel"])
    if publish and result == 0:
        files = list(map(str, Path(".").glob("dist/*")))
        result = run_as_fg_process(["python3", "-m", "twine", "check"] + files)
        if result == 0:
            result = run_as_fg_process(
                ["python3", "-m", "twine", "upload", "--repository", "pypi"] + files
            )

    os.chdir(cwd)
    return result == 0


def pack_publish_php(dir: Path, publish: bool = False):
    return True


def pack_publish(language: str, dir: Path, publish: bool = False):
    if language == "csharp":
        return pack_publish_csharp(dir, publish)
    elif language == "python":
        return pack_publish_python(dir, publish)
    elif language == "php":
        return pack_publish_php(dir, publish)
    else:
        raise ValueError("Language not supported.")


def git_add_all(git_repo: Path):
    result = run_as_fg_process(["git", "-C", f"{git_repo.absolute()}", "add", "-A"])
    return result == 0


def git_commit(git_repo: Path, msg: str):
    result = run_as_fg_process(
        ["git", "-C", f"{git_repo.absolute()}", "commit", "-m", msg]
    )
    return result == 0


def git_tag(git_repo: Path, tag_name: str, msg: str):
    result = run_as_fg_process(
        [
            "git",
            "-C",
            f"{git_repo.absolute()}",
            "tag",
            "-a",
            tag_name,
            "-m",
            msg,
            "--force",
        ]
    )
    return result == 0


def git_check_tag(git_repo: Path, tag_name: str):
    return git_check_revision(git_repo, f"tags/{tag_name}")


def git_check_branch(git_repo: Path, branch_name: str):
    return git_check_revision(git_repo, f"heads/{branch_name}")


def git_check_revision(git_repo: Path, rev_name: str):
    result = run_as_fg_process(
        [
            "git",
            "-C",
            f"{git_repo.absolute()}",
            "rev-parse",
            "--verify",
            f"refs/{rev_name}",
        ]
    )
    return result == 0


def git_checkout(git_repo: Path, branch_name: str, create: bool = False):
    args = ["git", "-C", f"{git_repo.absolute()}", "checkout"]
    if create:
        args.append("-b")

    args.append(branch_name)

    result = run_as_fg_process(args)
    return result == 0


def git_push(git_repo: Path):
    result = run_as_fg_process(
        ["git", "-C", f"{git_repo.absolute()}", "push", "origin", "--all", "--force"]
    )
    if result == 0:
        result = run_as_fg_process(
            [
                "git",
                "-C",
                f"{git_repo.absolute()}",
                "push",
                "origin",
                "--tags",
                "--force",
            ]
        )
    return result == 0


def openapi_validate(spec_file: Path):
    cwd = os.getcwd()
    result = run_as_fg_process(
        [
            "docker",
            "run",
            "--rm",
            "-v",
            f"{spec_file.absolute()}:/spec/validate.yaml:ro",
            CLI_DOCKER_CONTAINER_VERSION,
            "validate",
            "-i",
            "/spec/validate.yaml",
        ]
    )
    os.chdir(cwd)
    return result == 0


def openapi_generate(language: str, spec_file: Path, gen_dir: Path):
    if language not in GENERATORS:
        raise ValueError(f"Language '{language}' is not supported at this time.")
    cwd = os.getcwd()

    if language == "aspnetcore" or language == "csharp":
        schema_mappings_arg = "--schema-mappings="
        import_mappings_arg = "--import-mappings="
        type_mappings_arg = "--type-mappings="
        primitives_arg = "--language-specific-primitives="

        schema_mappings = (
            dict(CSHARP_SCHEMA_MAPPINGS_PUBLIC, **CSHARP_SCHEMA_MAPPINGS_SERVER)
            if language == "aspnetcore"
            else CSHARP_SCHEMA_MAPPINGS_PUBLIC
        )

        type_mappings = schema_mappings.copy()
        if language == "aspnetcore":
            type_mappings["list"] = "IEnumerable"
            type_mappings["array"] = "IEnumerable"

        schema_mappings_arg += ",".join(
            map(lambda x: f"{x[0]}={x[1]}", schema_mappings.items())
        )
        import_mappings_arg += ",".join(
            map(lambda x: f"{x[0]}={x[1]}", schema_mappings.items())
        )
        type_mappings_arg += ",".join(
            map(lambda x: f"{x[0]}={x[1]}", type_mappings.items())
        )
        primitives_arg += ",".join(map(lambda x: f"{x[1]}", schema_mappings.items()))
    elif language == "python":
        schema_mappings_arg = "--schema-mappings="
        import_mappings_arg = "--import-mappings="
        type_mappings_arg = "--type-mappings="
        primitives_arg = "--language-specific-primitives="

        schema_mappings = PYTHON_SCHEMA_MAPPINGS
        schema_mappings_arg += ",".join(
            map(lambda x: f"{x[0]}={x[1]}", schema_mappings.items())
        )
        import_mappings_arg += ",".join(
            map(lambda x: f"{x[0]}={x[1]}", schema_mappings.items())
        )
        type_mappings_arg += ",".join(
            map(lambda x: f"{x[0]}={x[1]}", schema_mappings.items())
        )
        primitives_arg += ",".join(map(lambda x: f"{x[1]}", schema_mappings.items()))

    args = [
        "docker",
        "run",
        "--rm",
        "-v",
        f"{spec_file.absolute()}:/spec/generate.yaml:ro",
        "-v",
        f"{CONFIG_PATH.absolute()}:/config:ro",
        "-v",
        f"{TEMPLATE_PATH.absolute()}:/templates:ro",
        "-v",
        f"{gen_dir.absolute()}:/out",
        CLI_DOCKER_CONTAINER_VERSION,
        "generate",
        "--ignore-file-override",
        "/config/.openapi-generator-ignore",
        "-i",
        "/spec/generate.yaml",
        "-g",
        GENERATORS[language],
        "-c",
        f"/config/config-{language}.yaml",
        "-o",
        "/out",
        "-t",
        f"/templates/{language}",
    ]
    if language == "aspnetcore" or language == "csharp":
        args.append(schema_mappings_arg)
        args.append(import_mappings_arg)
        args.append(type_mappings_arg)
        args.append(primitives_arg)
    elif language == "python":
        args.append(schema_mappings_arg)
        args.append(import_mappings_arg)
        args.append(type_mappings_arg)
        args.append(primitives_arg)
    print(args)
    result = run_as_fg_process(args)
    os.chdir(cwd)
    return result == 0


def tsp_compile(src_dir: Path):
    cwd = os.getcwd()

    args = ["tsp", "compile", str(src_dir)]
    result = run_as_fg_process(args)
    os.chdir(cwd)
    return result == 0


def postprocess_csharp(dir: Path):
    return True


def postprocess_aspnetcore(dir: Path):
    for file in dir.glob("**/*.cs"):
        print("Post-processing: ", file)
        with file.open("r") as f:
            content = f.read()
        if " : ControllerBase" in content:
            content = content.replace(
                " : ControllerBase",
                "(IUserTokenScoped userTokenScoped, IOptions<MvcNewtonsoftJsonOptions> mvcNewtonsoftJsonOptions, IExtendedAuthenticationTransient authenticationTransient) : CalcasaControllerBaseV1(userTokenScoped, mvcNewtonsoftJsonOptions, authenticationTransient)",
            )

            content = content.replace(
                "public abstract async Task", "public abstract Task"
            )
        elif "DeelWaarderingWebhookPayload" in content:
            content = content.replace(
                "DeelWaarderingWebhookPayload",
                "DeelWaarderingWebhookPayload : Calcasa.Api.Webhooks.IWebhookPayload",
            )
            content = content.replace(
                '[Required]\n        [DataMember(Name="callbackName", EmitDefaultValue=false)]\n        public string CallbackName { get; set; }',
                '[DataMember(Name="callbackName", EmitDefaultValue=false)]\n        public string CallbackName => "deel-waardering";',
            )
        elif "WaarderingWebhookPayload" in content:
            content = content.replace(
                "WaarderingWebhookPayload",
                "WaarderingWebhookPayload : Calcasa.Api.Webhooks.IWebhookPayload",
            )
            content = content.replace(
                '[Required]\n        [DataMember(Name="callbackName", EmitDefaultValue=false)]\n        public string CallbackName { get; set; }',
                '[DataMember(Name="callbackName", EmitDefaultValue=false)]\n        public string CallbackName => "waardering";',
            )
        with file.open("w") as f:
            f.write(content)
    return True


def postprocess_python(dir: Path):
    for file in dir.glob("**/*.py"):
        print("Post-processing: ", file)
        with file.open("r") as f:
            content = f.read()
        if "from calcasa.api.models.list[operation] import list[Operation]" in content:
            content = content.replace(
                "from calcasa.api.models.list[operation] import list[Operation]",
                "from calcasa.api.models.operation import Operation",
            )
            content = content.replace(
                "CallbackName = callbackName;", 'CallbackName = "deel-waardering";'
            )
        with file.open("w") as f:
            f.write(content)
    return True


def postprocess_php(dir: Path):
    result = run_as_fg_process(
        ["php", "postprocess/php/php-postprocess.php", dir.absolute()]
    )
    return result == 0


def postprocess(language: str, dir: Path):
    if language == "csharp":
        return postprocess_csharp(dir)
    elif language == "aspnetcore":
        return postprocess_aspnetcore(dir)
    elif language == "python":
        return postprocess_python(dir)
    elif language == "php":
        return postprocess_php(dir / "lib/Model")
    elif language == "docs" or language == "docs2" or language == "docs3":
        return True
    else:
        raise ValueError("Language not supported.")


def empty_dir(folder: os.PathLike, ignore=[]):
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        try:
            if os.path.basename(file_path) in ignore:
                continue
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print("Failed to delete %s. Reason: %s" % (file_path, e))


def main():
    branch_name = "master"

    if (MAIN_DIR / "tsp-output").exists():
        print(f"Removing content from existing tsp-output directory...")
        empty_dir(MAIN_DIR / "tsp-output")

    VERSION = "dev"
    prerelease = True

    with (MAIN_DIR / "CHANGELOG.md").open("r") as changelog_file:
        desc = changelog_file.read()
        matches = [m.groupdict() for m in CHANGELOG_REGEX.finditer(desc)]
        release_msg = ""
        for match in matches:
            VERSION = match["version"]
            if "-" in VERSION:
                prerelease = True
            else:
                prerelease = False
            release_msg = f"Release {VERSION} ({match['date']})\n\n{match['changes']}\n"
            print(
                f"Found {'prerelease ' if prerelease else ''}release {VERSION} ({match['date']}) with changes:\n{match['changes']}"
            )
            break

    SPEC_FILE = Path(f"tsp-output/@typespec/openapi3/openapi.{VERSION}.yaml")
    print(f"Compiling TypeSpec...")

    if tsp_compile(MAIN_DIR / "src"):
        if not SPEC_FILE.exists():
            die(f"TypeSpec compilation failed, file {SPEC_FILE} does not exist.")

        configs = {}

        for config in CONFIG_PATH.glob("*.yaml"):
            confobject = {}
            with config.open("r") as config_file:
                confobject = yaml.load(config_file)
                configs[config.name.replace("config-", "").replace(".yaml", "")] = (
                    confobject
                )

                if "packageVersion" in confobject:
                    confobject["packageVersion"] = VERSION
                if "httpUserAgent" in confobject:
                    confobject["httpUserAgent"] = USERAGENT_REGEX.sub(
                        rf"\1/{VERSION}", confobject["httpUserAgent"]
                    )
            with config.open("w") as config_file:
                yaml.dump(confobject, config_file)
        if openapi_validate(SPEC_FILE):
            for language in configs:
                print(f"Processing {language}...")
                gen_dir = GENERATED_DIR / language
                lib_dir = LIBRARY_DIR / f"api-{language}"
                if gen_dir.exists():
                    shutil.rmtree(gen_dir)

                gen_dir.mkdir(parents=True, exist_ok=True)

                if language in PUBLISHED_LIBRARIES:
                    if git_check_tag(lib_dir, VERSION):
                        print(
                            f"Version {VERSION} is already tagged for {language}, skipping..."
                        )
                        continue

                    print(f"Checking out {branch_name} in {lib_dir}...")
                    git_checkout(
                        lib_dir,
                        branch_name,
                        create=not git_check_branch(lib_dir, branch_name),
                    )

                    if lib_dir.exists():
                        empty_dir(lib_dir, [".git"])
                    else:
                        lib_dir.mkdir(parents=True, exist_ok=True)
                openapi_generate(language, SPEC_FILE, gen_dir) or die(
                    f"Error with openapi_generate for {language}"
                )

                postprocess(language, gen_dir) or die(
                    f"Error with postprocess for {language}"
                )

                if language in PUBLISHED_LIBRARIES:
                    print(f"Copying generated files to {lib_dir}..")
                    shutil.copytree(
                        gen_dir,
                        lib_dir,
                        dirs_exist_ok=True,
                        ignore=shutil.ignore_patterns(
                            ".github",
                            "git_push.sh",
                            "appveyor.yml",
                            "docs",
                            "test",
                            "tox.ini",
                            "phpunit*",
                            ".gitlab-ci.yml",
                            ".travis.yml",
                            "test-requirements.txt",
                            ".openapi-generator",
                            ".openapi-generator-ignore",
                            ".php_cs",
                            "openapi.yaml",
                            "**/README.md",
                            "*.Test",
                        ),
                    )
                    shutil.copy2("LICENSE", lib_dir)
                elif language == "aspnetcore":
                    public_api_service_dir = (
                        MAIN_DIR.absolute().parent / "public-api-service"
                    )
                    if public_api_service_dir.exists():
                        print("Copying generated files to public-api-service...")
                        calcasa_api_dir = public_api_service_dir / "Calcasa.Api" / "V1"
                        empty_dir(calcasa_api_dir)
                        shutil.copytree(
                            gen_dir / "src" / "Calcasa.Api.V1",
                            calcasa_api_dir,
                            dirs_exist_ok=True,
                            ignore=shutil.ignore_patterns(
                                ".github",
                                "git_push.sh",
                                "appveyor.yml",
                                "docs",
                                "test",
                                "openapi.yaml",
                                "**/README.md",
                                "*.Test",
                                "*.csproj",
                                "*.nuspec",
                                ".gitignore",
                                "Dockerfile",
                                "wwwroot",
                                "Program.cs",
                                "Startup.cs",
                                "appsettings.json",
                                "appsettings.Development.json",
                                "Properties",
                            ),
                        )
                        print("Creating OpenApiSpecVersion class...")
                        (calcasa_api_dir / "OpenApiSpecVersion.cs").write_text(
                            f'// This file is auto-generated by build.py, do not edit.\nnamespace Calcasa.Api.V1;\npublic static class OpenApiSpecVersion\n{{\n    public const string Value = "{VERSION}";\n}}\n'
                        )
                        print("Copying original Open API spec YAML and JSON...")
                        docs_dir = (
                            public_api_service_dir
                            / "Calcasa.PublicApi.Service"
                            / "docs"
                            / "v1"
                        )
                        docs_dir.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(SPEC_FILE, docs_dir / "openapi.yaml")
                        shutil.copy2(
                            gen_dir
                            / "src"
                            / "Calcasa.Api.V1"
                            / "wwwroot"
                            / "openapi-original.json",
                            docs_dir / "openapi.json",
                        )

                if not postprocess(language, lib_dir):
                    die(f"Error with postprocess for {language}")

                if language in PUBLISHED_LIBRARIES:
                    git_add_all(lib_dir) or die(
                        f"Error with git_add_all for {language}"
                    )
                    git_commit(lib_dir, release_msg) or die(
                        f"Error with git_commit for {language}"
                    )
                    git_tag(lib_dir, VERSION, release_msg) or die(
                        f"Error with git_tag for {language}"
                    )

                    git_push(lib_dir) or die(f"Error with git_push for {language}")

                    pack_publish(language, lib_dir, publish=True) or die(
                        f"Error with pack_publish for {language}"
                    )

                    github_make_release(
                        language, lib_dir, VERSION, release_msg, prerelease
                    ) or die(f"Error with github_make_release for {language}")

            if any(filter(lambda x: x in PUBLISHED_LIBRARIES, configs)):
                git_add_all(MAIN_DIR) or die("Error with git_add_all for main repo")
                git_commit(MAIN_DIR, release_msg) or die(
                    "Error with git_commit for main repo"
                )
                git_tag(MAIN_DIR, VERSION, release_msg) or die(
                    "Error with git_tag for main repo"
                )
                git_push(MAIN_DIR) or die("Error with git_push for main repo")
                github_make_main_release(VERSION, release_msg, prerelease) or die(
                    f"Error with github_make_main_release for main repo"
                )


if __name__ == "__main__":
    if not NUGET_API_KEY:
        die("NUGET_API_KEY not set.")
    else:
        print(f"Got NUGET_API_KEY ({len(NUGET_API_KEY)}) from environment.")

    main()
