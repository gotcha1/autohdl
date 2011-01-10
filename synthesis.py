import os
import sys
import re
import shutil
import subprocess

import structure
import toolchain

from hdlLogger import *


class SynthesisException(Exception):
  def __init__(self, iString):
    self.string = iString
  def __str__(self):
    return self.string


def synchSrcFile(ioSrcFresh, ioScriptContent, iNum, iLine):
  match = re.search(r'add_file\s+?"(.*?)"', iLine)
  if match:
    res = match.group(1)
    if ioSrcFresh.count(res):
      ioSrcFresh.remove(res)
    else:
      if iLine.strip()[0] != '#':
        ioScriptContent[iNum] = '# {0} WAS DELETED'.format(iLine) 
    return True


def synchTopModule(ioScriptContent, iTopModule, iNum, iLine):
  match = re.search(r'set_option\s+?-top_module\s+?"(.*?)"', iLine)
  if match:
    ioScriptContent[iNum] = 'set_option -top_module "{0}"'.format(iTopModule)
    return True


def synchResultFile(ioScriptContent, iTopModule, iNum, iLine):
  match = re.search(r'project\s+?-result_file\s+"(.*?)"', iLine)
  if match:
    resultFile = '%s/%s/%s%s' % (os.getcwd(), '../synthesis', iTopModule, '.edf')
    resultFile = os.path.abspath(resultFile).replace('\\','/')
    ioScriptContent[iNum] = 'project -result_file "{0}"'.format(resultFile)
    return True
  
  
def merge(ioSrcFresh, ioScriptContent, iTopModule):
  '''
  Precondition: items trimmed, files in in quotes
  '''
  lastEntry = 1
  for num, line in enumerate(ioScriptContent):
    if synchSrcFile(ioSrcFresh, ioScriptContent, num, line):
      lastEntry = num+1
      continue
    if synchTopModule(ioScriptContent, iTopModule, num, line):
      continue
    if synchResultFile(ioScriptContent, iTopModule, num, line):
      continue

  ioScriptContent[lastEntry:lastEntry] = ['add_file "{0}"'.format(k) for k in ioSrcFresh]


def getSrcFromFileSys(iDsn):
  log.debug('def getSrcFromFileSys=> iDsn=\n'+str(iDsn))
  fileMain = iDsn.getFileMain(iOnly = ['src'])
  fileDep = iDsn.getDeps()
  log.debug('deps:='+str(fileDep))
  return (fileMain + list(fileDep))  

  
def genScript(iTopModule = ''):
  log.debug('def genScript=> iTopModule='+iTopModule)
  pathCur = os.getcwd()
  if os.path.split(pathCur)[1] != 'script':
    msg = 'Expected current directory: script; Got: ' + pathCur
    log.error(msg)
    raise SynthesisException(msg)
  # get src files, regenerate structure
  dsn = structure.Design('..')
  
  pathSynthesisPrj = '%s/%s' % (pathCur,'synthesis.prj')
  if os.path.exists(pathSynthesisPrj):
    log.info('Refreshing existing script')
    f = open(pathSynthesisPrj, 'r')
  else:  
    log.info('Generating default script')
    f = open(pathCur+'/../resource/synthesis_default', 'r')
  scriptContent = f.read()
  f.close()
  
  contentAsList = scriptContent.split('\n')
  srcFiles = getSrcFromFileSys(dsn)
  merge(srcFiles, contentAsList, iTopModule)
  scriptContent = '\n'.join(contentAsList)

  f = open('%s/%s' % (pathCur,'synthesis.prj'), 'w')
  f.write(scriptContent)
  f.close


def parseLog(path_this_script):
  log.debug('def parseLog=> path_this_script='+path_this_script)
  f = open(path_this_script + '/synthesis.prj', 'r')
  scriptContent = f.read()
  match = re.search(r'-top_module\W+(\w+)', scriptContent)
  top_module = match.group(1)
  
  logFile = path_this_script + '/../synthesis/' + top_module + '.srr'
  logFile = os.path.abspath(logFile)
  if os.path.exists(logFile):
    f = open(logFile, 'r')
    res = f.read()
    errors = res.count('@E:')
    warnings = res.count('@W:')
    ignoreWarnings = res.count('Initial value is not supported on state machine state')
    if errors or (warnings - ignoreWarnings):
      print >> sys.stderr , 'Errors: ', errors
      print >> sys.stderr, 'Warnings: ', warnings
      subprocess.Popen(['notepad', logFile])
    else:
      print 'Errors: ', errors
      print 'Warnings: ', warnings
    print 'see log in ' + logFile
  
    if errors:
      sys.exit()
    
  return logFile 




def preparation(iPathCur):
  '''
  Creates synthesis directory and copies project script
  '''
  log.debug('def preparation=> iPathCur='+iPathCur)
  synthesisDir = '%s/%s' % (iPathCur, '../synthesis')
  
  if os.path.exists(synthesisDir):
    shutil.rmtree(synthesisDir)
  os.makedirs(synthesisDir)
    
  shutil.copyfile(iPathCur     + '/synthesis.prj',
                  synthesisDir + '/synthesis.prj')
  
  os.chdir(synthesisDir)
  


def runTool(iMode, iPathCur):
  '''
  Runs external tool for synthesis
  '''
  log.debug('def runTool')
  
  synplify = toolchain.getPath(iMode)
  synthesisScript = iPathCur + '/../synthesis/synthesis.prj'
  
  if iMode == 'synplify_batch':
    run = '"%s" %s %s %s %s' % (synplify,
                  '-product synplify_premier',
                  '-licensetype synplifypremier',
                  '-batch', synthesisScript)
    subprocess.call(run)
  elif iMode == 'synplify_gui':
    subprocess.call([synplify, synthesisScript])
    return #doesn't need to parse log
  else:
    print >> sys.stderr, 'no such tool for synthesis'
        
  print 'SYNTHESIS DONE'  
  return parseLog(iPathCur)
  


def run(iMode = 'synplify_batch', iTopModule = ''):
  log.debug('def run=> iMode='+iMode+' iTopModule='+iTopModule)
  pathCur = os.getcwd()
  genScript(iTopModule)
  preparation(pathCur)
  logFile = runTool(iMode = iMode, iPathCur = pathCur)
  os.chdir(pathCur)
  return logFile