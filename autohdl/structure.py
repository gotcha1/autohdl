import os
import shutil
from collections import namedtuple

from autohdl import hdl_globals
from autohdl import verilog
from autohdl.hdl_logger import logging

alog = logging.getLogger(__name__)


def generate(path=''):
    # create dir structure
    # copy config file
    # return printable tree structure
    root = os.path.abspath(path)
    if not os.path.exists(root):
        os.makedirs(root)
    alog.info('Design root: ' + root)
    for i in hdl_globals.predefined_dirs:
        path = os.path.join(root, i)
        if not os.path.exists(path):
            os.mkdir(path)
    autohdl_cfg = hdl_globals.FILE_USER_CFG
    Copy = namedtuple('Copy', ['src', 'dst'])
    list_to_copy = (
        Copy(autohdl_cfg, os.path.join(root, 'script', 'kungfu.py')),
    )
    for i in list_to_copy:
        if not os.path.exists(i.dst):
            shutil.copy(i.src, i.dst)
    return get(root)


def get(path='', ignore=hdl_globals.ignore_repo_dirs):
    root = os.path.abspath(path)
    return tree(directory=root, ignore=ignore)


def tree(directory, padding=' ', _res=[], ignore=[]):
    _res.append(padding[:-1] + '+-' + os.path.basename(os.path.abspath(directory)) + os.path.sep)
    padding += ' '
    files = os.listdir(directory)
    count = 0
    for f in files:
        if f in ignore:
            continue
        count += 1
        _res.append(padding + '|')
        path = directory + os.path.sep + f
        if os.path.isdir(path):
            if count == len(files):
                tree(directory=path, padding=padding + ' ')
            else:
                tree(directory=path, padding=padding + '|')
        else:
            _res.append(padding + '+-' + f)
    return '\n'.join(_res)


def parse(src_files):
    # input: list of source files
    # output: dict
    # {abs_file_path:
    #   tuple(module_name0: set(inst1, inst2, ...),
    #         module_name1: set(inst1, inst2, ...),
    #        ...
    #        )
    #  abs_file_path2:
    #   ...
    # }
    d = {}
    for afile in src_files:
        with open(afile) as f:
            d.update(verilog.parse(f.read()))
    return d


if __name__ == '__main__':
    pass