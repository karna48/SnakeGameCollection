import shutil
from pathlib import Path
import sys
import os
import transcrypt.__main__ as ts_main

__module_dir = Path(__file__).parent


def copy_data():
    src = __module_dir.parent / 'common_data'
    dst = __module_dir / 'data'
    shutil.copytree(src, dst, dirs_exist_ok=True)


def compile_py2js(development=True):
    src_target = __module_dir / 'src' / '__target__'

    print('making Transcrypt frontend')
    print('  development:', development)

    shutil.rmtree(src_target, ignore_errors=True)

    if development:
        args = ['-dm', '-a', '-n', '-m']
    else:
        args = []
    # fix arguments and working directory
    argv_old = sys.argv
    last_dir = os.curdir
    os.chdir(__module_dir)
    sys.argv = ['transcrypt'] + args + ['src/snake.py']
    ts_main.main()
    sys.argv = argv_old  # rollback arguments
    os.chdir(last_dir)  # rollback working directory


if __name__ == '__main__':
    if not ('--skip-data' in sys.argv or '-sd' in sys.argv):
        copy_data()

    if not ('--skip-compile' in sys.argv or '-sc' in sys.argv):
        compile_py2js()
