import os
from datetime import datetime

from autohdl.verilog import cache, vpreprocessor, vparser


def get_instances(file):
    """
    Input: file
    Output: dictionary
    moduleName: path      : full_path
                inctances : set()
    """
    if cache.refreshCache():
        cache.clean()
    cached = cache.load(file)
    if cached:
        return cached['parsed']
    preprDict = vpreprocessor.Preprocessor(file).result
    # res = vparser.Parser(preprDict).result
    res = vparser.Parser(preprDict['preprocessed']).parse()
    preprDict.update({'parsed': res})
    cache.dump(preprDict)
    return res


if __name__ == '__main__':
    start = datetime.now()
    cache.CACHE_PATH = '.'
    cache.CACHE = False
    try:
        for root, dirs, files in os.walk(r'D:\repo\github\autohdl\test\verilog\in\func'):
            for f in files:
                path = root + '/' + f
                print(get_instances(path))
    except Exception as e:
        print(e)
        print(path)
        raise
    print(datetime.now() - start)