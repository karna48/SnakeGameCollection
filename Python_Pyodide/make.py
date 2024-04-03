import shutil
from pathlib import Path


__module_dir = Path(__file__).parent


def copy_data():
    src = __module_dir.parent / 'common_data'
    dst = __module_dir / 'data'
    shutil.copytree(src, dst, dirs_exist_ok=True)


if __name__ == '__main__':
    copy_data()
