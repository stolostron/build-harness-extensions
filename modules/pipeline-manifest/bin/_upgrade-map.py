import json
import sys
import os
import requests

# Parameters:
#  sys.argv[1] - version number to calculate upgrade mapping for
#  sys.argv[2] - repository in quay (i.e. open-cluster-management or acm-d)

# Dependencies:
#  QUAY_TOKEN defined in the environment - read access to quay repo defined in argv[2]

# Assumptions:
#  Tags in quay are in chronological order
#  GA versions of index tags are in the form "vX.Y.Z", snapshots are "X.Y.Z..."
#  Some new kind of mapping will be necessary to figure out full version boundaries
#    (i.e. when does 3.0 minus 1 equal 2.4, or when does 2.7 plus 1 equal 3.0)

base_version = sys.argv[1]
splits = base_version.split('.')
base_x = int(splits[0])
base_y = int(splits[1])
repository = sys.argv[2]

QUAY_TOKEN = os.getenv('QUAY_TOKEN')

def semver_plus(x,y):
  y = y + 1
  return("{}.{}".format(x,y))

def semver_minus(x,y):
  y = y - 1
  return("{}.{}".format(x,y))

# Start with an empty map
upgrade_map = {}
upgrade_map['dev'] = ''
upgrade_map['ga'] = ''
upgrade_map['gaminus'] = ''
upgrade_map['gaplus'] = ''

headers = {
    'Authorization': 'Bearer '+QUAY_TOKEN
}

page = 0
while True:
  page=page+1
  url = "https://quay.io/api/v1/repository/"+repository+"/acm-custom-registry/tag/?onlyActiveTags=true&limit=100&page={}".format(page)
  response = requests.get(url, headers=headers).json()
  my_list = response["tags"]
  for x in my_list:
    name = x.get('name')
    if (name.startswith("v{}".format(semver_plus(base_x,base_y)))):
      if (upgrade_map['gaplus'] == ''): 
        upgrade_map['gaplus'] = name
    if (name.startswith("v{}".format(semver_minus(base_x,base_y)))):
      if (upgrade_map['gaminus'] == ''): 
        upgrade_map['gaminus'] = name
    if (name.startswith("v{}".format(base_version))):
      if (upgrade_map['ga'] == ''): 
        upgrade_map['ga'] = name
    if (name.startswith(base_version)):
      if (upgrade_map['dev'] == ''): 
        upgrade_map['dev'] = name
  if (response["has_additional"] != True):
    break

json_data = json.dumps(upgrade_map)
print(json_data)
