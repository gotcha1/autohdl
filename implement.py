import os
import shutil
import subprocess
import hdlGlobals

import toolchain
import structure


from hdlLogger import log_call, logging
log = logging.getLogger(__name__)


@log_call
def bit2mcs(iTopModule, iSize):
  proc = '{tool} -u 0 {top} -s {size} -w'.format(tool = toolchain.getPath('ise_promgen'),
                                                 top = iTopModule,
                                                 size = iSize)
  subprocess.call(proc)


@log_call
def run(iTopModule, iUCF, iFlashSize = ''):
  try:
    if os.path.exists('../implement'):
      for root, dirs, files in os.walk('../implement'):
        for f in files:
          if os.path.splitext(f)[1] not in ['.mcs', '.bit']:
            os.remove(os.path.join(root, f))
#      shutil.rmtree('../implement')
  except OSError:
    log.warning("Can\'t clean folder ../implement")
  if not os.path.exists('../implement'):
    os.makedirs('../implement')  
    
  top = structure.search(iPath = '../synthesis', iOnly = [iTopModule+'\.edf'])[0]
  netlists = structure.search(iPath = '../src', iOnly = ['\.edf', '\.ngc'], iIgnore = hdlGlobals.ignore )

  shutil.copyfile(iUCF, '../implement/'+iTopModule+'.ucf')
  shutil.copyfile(top, '../implement/'+iTopModule+'.edf')
  for i in netlists:
    shutil.copyfile(i, '../implement/'+os.path.split(i)[1])
  
  
  os.chdir('../implement')
  subprocess.call(('{xflow} -implement balanced.opt'
                   ' -config bitgen.opt {netlist}.edf').format(xflow=toolchain.getPath('ise_xflow'),
                                                              netlist=iTopModule))
  
  if iFlashSize:
    bit2mcs(iTopModule, iFlashSize)
    
  log.info('Implementation done')

