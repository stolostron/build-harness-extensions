import json
import sys
import os
from subprocess import run

data = json.load(open(sys.argv[1]))
for v in data:
    component_name = v["name"]
    compenent_tag = v["tag"]
    component_version = v["tag"].replace('-'+v["sha256"],'')
    retag_name = component_version + "-SNAPSHOT-" + sys.argv[2]
    run('echo QUAY_RETAG_NAME={} COMPONENT_NAME={} QUAY_COMPONENT_TAG={} QUAY_DRY_RUN={}'.format(retag_name,component_name,compenent_tag,sys.argv[3]), shell=True)
    run('make quay/retag QUAY_RETAG_NAME={} COMPONENT_NAME={} QUAY_COMPONENT_TAG={} QUAY_DRY_RUN={}'.format(retag_name,component_name,compenent_tag,sys.argv[3]), shell=True, check=True)