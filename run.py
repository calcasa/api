#!/bin/python3
import re
import ruamel.yaml

import os
import shutil
from pathlib import Path
import requests
import os
import signal
import subprocess
import sys
import termios

from packaging import version

yaml = ruamel.yaml.YAML()  # defaults to round-trip

NUGET_API_KEY = os.getenv('NUGET_API_KEY')

MAIN_DIR = Path('.')
TEMPLATE_PATH = Path("templates")
CONFIG_PATH = Path("configs")
LIBRARY_DIR = Path("libraries")
GENERATED_DIR = Path("generated")
CHANGELOG_REGEX = re.compile(
    r"### (?P<date>[0-9]{4}-[0-9]{1,2}-[0-9]{1,2})\s+(\(v(?P<version>[0-9\.\-a-z]+)\)\s+)?(?P<changes>[^#]*)\s+", re.S)
USERAGENT_REGEX = re.compile(r"([^/]+)/[^/]+")
SPEC_FILE = Path('openapi.yaml')

GENERATORS = {
    'csharp': 'csharp-netcore',
    'php': 'php',
    'python': 'python'
}

def die(msg:str="Error"):
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
        child = subprocess.Popen(*args, preexec_fn=new_pgid,
                                 **kwargs)

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


def github_make_main_release(tag_name:str, release_msg:str, prerelease:bool = False):
    cwd = os.getcwd()
    result = run_as_fg_process([
        'gh',
        'release',
        'create',
        '--repo',
        f'calcasa/api',
        '-t',
        tag_name,
        '-n',
        release_msg
    ] + (['-p'] if prerelease else [])+
    [
        tag_name
    ]
    )

    os.chdir(cwd)
    return result == 0

def github_make_release(language:str, dir:Path, tag_name:str, release_msg:str, prerelease:bool = False):
    cwd = os.getcwd()
    os.chdir(dir)
    files = map(str,Path('.').glob("dist/*"))
    result = run_as_fg_process([
        'gh',
        'release',
        'create',
        '--repo',
        f'calcasa/api-{language}',
        '-t',
        tag_name,
        '-n',
        release_msg
    ] + (['-p'] if prerelease else [])+
    [
        tag_name
    ] + list(files)
    )

    os.chdir(cwd)
    return result == 0

def pack_publish_csharp(dir: Path, publish: bool = False):
    cwd = os.getcwd()
    os.chdir(dir)
    result = run_as_fg_process([
        'dotnet',
        'pack',
        '-c',
        'Release',
        '--verbosity',
        'Minimal',
        '-o',
        'dist',
        'src/Calcasa.Api/Calcasa.Api.csproj'
    ]
    )
    if publish and result == 0:
        files = map(str,Path('.').glob("dist/*.nupkg"))
        symb_files = map(str,Path('.').glob("dist/*.snupkg"))
        result = run_as_fg_process([
            'dotnet',
            'nuget',
            'push',
            '--source',
            'https://api.nuget.org/v3/index.json',
            '--api-key',
            NUGET_API_KEY
        ]  + list(files) + list(symb_files)
        )

    os.chdir(cwd)
    return result == 0


def pack_publish_python(dir: Path, publish: bool = False):
    cwd = os.getcwd()
    os.chdir(dir)

    result = run_as_fg_process([
        'python',
        'setup.py',
        'sdist',
        'bdist_wheel'
    ]
    )
    if publish and result == 0:
        files = list(map(str,Path('.').glob("dist/*")))
        result = run_as_fg_process([
            'python',
            '-m',
            'twine',
            'check'
        ] + files
        )
        if result == 0:
            result = run_as_fg_process([
                'python',
                '-m',
                'twine',
                'upload',
                '--repository',
                'pypi'
            ] + files
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
    result = run_as_fg_process([
        'git',
        '-C',
        f'{git_repo.absolute()}',
        'add',
        '-A'
    ]
    )
    return result == 0


def git_commit(git_repo: Path, msg: str):
    result = run_as_fg_process([
        'git',
        '-C',
        f'{git_repo.absolute()}',
        'commit',
        '-m',
        msg
    ]
    )
    return result == 0


def git_tag(git_repo: Path, tag_name: str, msg: str):
    result = run_as_fg_process([
        'git',
        '-C',
        f'{git_repo.absolute()}',
        'tag',
        '-a',
        tag_name,
        '-m',
        msg,
        '--force'
    ]
    )
    return result == 0

def git_check_tag(git_repo:Path, tag_name:str):
    return git_check_revision(git_repo,f'tags/{tag_name}')

def git_check_branch(git_repo:Path, branch_name:str):
    return git_check_revision(git_repo,f'heads/{branch_name}')

def git_check_revision(git_repo:Path, rev_name:str):
    result = run_as_fg_process([
        'git',
        '-C',
        f'{git_repo.absolute()}',
        'rev-parse',
        '--verify',
        f'refs/{rev_name}'
    ]
    )
    return result == 0

def git_checkout(git_repo:Path, branch_name:str, create:bool=False):
    args = [
        'git',
        '-C',
        f'{git_repo.absolute()}',
        'checkout']
    if create:
        args.append('-b')
    
    args.append(branch_name)

    result = run_as_fg_process(args)
    return result == 0

def git_push(git_repo: Path):
    result = run_as_fg_process([
        'git',
        '-C',
        f'{git_repo.absolute()}',
        'push',
        'origin',
        '--all',
        '--force'
    ]
    )
    if result == 0:
        result = run_as_fg_process([
            'git',
            '-C',
            f'{git_repo.absolute()}',
            'push',
            'origin',
            '--tags',
            '--force'
        ]
        )
    return result == 0


def openapi_validate(spec_file: Path):
    cwd = os.getcwd()
    result = run_as_fg_process([
        'docker',
        'run',
        '--rm',
        '-v',
        f'{spec_file.absolute()}:/spec/validate.yaml:ro',
        'openapitools/openapi-generator-cli:latest',
        'validate',
        '-i',
        '/spec/validate.yaml'
    ]
    )
    os.chdir(cwd)
    return result == 0


def openapi_generate(language: str, spec_file: Path, gen_dir: Path):
    if language not in GENERATORS:
        raise ValueError(
            f'Language \'{language}\' is not supported at this time.')
    cwd = os.getcwd()
    args = [
        'docker',
        'run',
        '--rm',
        '-v',
        f'{spec_file.absolute()}:/spec/generate.yaml:ro',
        '-v',
        f'{CONFIG_PATH.absolute()}:/config:ro',
        '-v',
        f'{TEMPLATE_PATH.absolute()}:/templates:ro',
        '-v',
        f'{gen_dir.absolute()}:/out',
        'openapitools/openapi-generator-cli:latest',
        'generate',
        '--ignore-file-override',
        '/config/.openapi-generator-ignore',
        '-i', '/spec/generate.yaml',
        '-g', GENERATORS[language],
        '-c', f'/config/config-{language}.yaml',
        '-o', '/out',
        '-t', f'/templates/{language}'
    ]
    print(args)
    result = run_as_fg_process(args)
    os.chdir(cwd)
    return result == 0


def postprocess_csharp(dir: Path):
    return True


def postprocess_python(dir: Path):
    return True


def postprocess_php(dir: Path):
    result = run_as_fg_process([
        'php',
        'postprocess/php/php-postprocess.php',
        dir.absolute()
    ]
    )
    return result == 0


def postprocess(language: str, dir: Path):
    if language == "csharp":
        return postprocess_csharp(dir)
    elif language == "python":
        return postprocess_python(dir)
    elif language == "php":
        return postprocess_php(dir / 'lib/Model')
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
            print('Failed to delete %s. Reason: %s' % (file_path, e))


def main():
    version_req = requests.get("https://api.calcasa.nl/api-docs/versions.yaml")
    version_obj = yaml.load(version_req.content)

    sorted_versions = sorted(
        version_obj, key=lambda d: d['version'], reverse=False)

    master_branch_version = sorted_versions[-1]['version']

    for version_info in sorted_versions:

        is_master_branch = master_branch_version == version_info['version']
        
        if git_check_tag(MAIN_DIR, version_info['specVersion']):
            print(f"Version {version_info['specVersion']} is already tagged, skipping...")
            continue

        branch_name = version_info['urlVersion'] if not is_master_branch else 'master'

        print(f"Processing version {version_info['specVersion']} ({version_info['urlVersion']}) on branch {branch_name}...")
        
        git_checkout(MAIN_DIR, branch_name, create=not git_check_branch(MAIN_DIR,branch_name))

        version_parsed = version.parse(version_info['specVersion'])
        prerelease = version_parsed.is_prerelease or version_parsed.major == 0

        print(version_info, version_parsed)

        openapi_req = requests.get(f"https://api.calcasa.nl{version_info['specUrl']}")
        openapi_obj = yaml.load(openapi_req.content)

        with SPEC_FILE.open('wb') as openapi_file:
            openapi_file.write(openapi_req.content)

        desc = openapi_obj['info']['description']

        matches = [m.groupdict() for m in CHANGELOG_REGEX.finditer(desc)]
        release_msg = ''
        for match in matches:
            if match['version'] == version_info['specVersion']:
                print(match)
                release_msg = f"Release {version_info['specVersion']} ({match['date']})\n\n{match['changes']}\n"

        configs = {}

        for config in CONFIG_PATH.glob("*.yaml"):
            confobject = {}
            with config.open("r") as config_file:
                confobject = yaml.load(config_file)
                configs[config.name.replace(
                    'config-', '').replace('.yaml', '')] = confobject

                confobject['packageVersion'] = version_info['specVersion']
                confobject['httpUserAgent'] = USERAGENT_REGEX.sub(
                    rf"\1/{version_info['specVersion']}", confobject['httpUserAgent'])
            with config.open('w') as config_file:
                yaml.dump(confobject, config_file)
        if openapi_validate(SPEC_FILE):
            for language in configs:
                print(f"Processing {language}...")
                gen_dir = GENERATED_DIR / language
                lib_dir = LIBRARY_DIR / f'api-{language}'
                if gen_dir.exists():
                    shutil.rmtree(gen_dir)

                gen_dir.mkdir(parents=True, exist_ok=True)

                if git_check_tag(lib_dir, version_info['specVersion']):
                    print(f"Version {version_info['specVersion']} is already tagged for {language}, skipping...")
                    continue

                git_checkout(lib_dir, branch_name, create=not git_check_branch(lib_dir,branch_name))

                if lib_dir.exists():
                    empty_dir(lib_dir, ['.git'])
                else:
                    lib_dir.mkdir(parents=True, exist_ok=True)
                openapi_generate(language, SPEC_FILE, gen_dir) or die(f"Error with openapi_generate for {language}")

                postprocess(language, gen_dir) or die(f"Error with postprocess for {language}")

                shutil.copytree(gen_dir, lib_dir, dirs_exist_ok=True, ignore=shutil.ignore_patterns('git_push.sh', 'appveyor.yml', 'docs', 'test', 'tox.ini',
                                                                                                    'phpunit*', '.gitlab-ci.yml', '.travis.yml', 'test-requirements.txt', '.openapi-generator', '.openapi-generator-ignore', '.php_cs'))
                shutil.copy2('LICENSE', lib_dir)

                git_add_all(lib_dir) or die(f"Error with git_add_all for {language}")
                git_commit(lib_dir, release_msg) or die(f"Error with git_commit for {language}")
                git_tag(lib_dir, version_info['specVersion'], release_msg) or die(f"Error with git_tag for {language}")

                #git_push(lib_dir) or die(f"Error with git_push for {language}")

                #pack_publish(language, lib_dir, publish=True) or die(f"Error with pack_publish for {language}")

                #github_make_release(language, lib_dir, version_info['specVersion'], release_msg, prerelease)  or die(f"Error with github_make_release for {language}")
            
            if len(configs) > 0:
                git_add_all(MAIN_DIR) or die("Error with git_add_all for main repo")
                git_commit(MAIN_DIR, release_msg) or die("Error with git_commit for main repo")
                git_tag(MAIN_DIR, version_info['specVersion'], release_msg) or die("Error with git_tag for main repo")
                #git_push(MAIN_DIR) or die("Error with git_push for main repo")
                #github_make_main_release(version_info['specVersion'], release_msg, prerelease)  or die(f"Error with github_make_main_release for main repo")


if __name__ == "__main__":
    if not NUGET_API_KEY:
        die("NUGET_API_KEY not set.")
    else:
        print(f"Got NUGET_API_KEY ({len(NUGET_API_KEY)}) from environment.")
    
    main()
