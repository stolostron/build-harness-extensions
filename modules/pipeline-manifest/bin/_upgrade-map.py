import json
import sys
import os
import requests
import re

# Parameters:
#  sys.argv[1] - version number to calculate upgrade mapping for
#  sys.argv[2] - repository in quay (i.e. stolostron or acm-d)

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
upgrade_map['gaupstream'] = ''
upgrade_map['gaplusupstream'] = ''
upgrade_map['gaminusupstream'] = ''
gasha = ''
gaminussha = ''
gaplussha = ''

headers = {
    'Authorization': 'Bearer '+QUAY_TOKEN
}

page = 0
page_data=[]
while True:
  page=page+1
  url = "https://quay.io/api/v1/repository/"+repository+"/acm-custom-registry/tag/?onlyActiveTags=true&limit=100&page={}".format(page)
  response = requests.get(url, headers=headers, verify=False).json()
  # We need to have a consolidated list to search, so we do array extension of the pages
  page_data.extend(response["tags"])
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

# We need to scan the full list of pages for instances of the RC names, then match them via docker image shas in order to find snapshot names
if upgrade_map['ga'] != '':
  match = next(x for x in page_data if x['name'] == upgrade_map['ga'] )
  gasha=match['manifest_digest']
if upgrade_map['gaplus'] != '':
  matchplus = next(x for x in page_data if x['name'] == upgrade_map['gaplus'] )
  gaplussha=matchplus['manifest_digest']
if upgrade_map['gaminus'] != '':
  matchminus = next(x for x in page_data if x['name'] == upgrade_map['gaminus'] )
  gaminussha=matchminus['manifest_digest']
for x in page_data:
    if x['manifest_digest'] == gasha:
        if x['name'] != upgrade_map['ga']:
            newname = re.sub(r'DOWNSTREAM','SNAPSHOT',x['name'])
            upgrade_map['gaupstream'] = newname
    if x['manifest_digest'] == gaplussha:
        if x['name'] != upgrade_map['gaplus']:
            newname = re.sub(r'DOWNSTREAM','SNAPSHOT',x['name'])
            upgrade_map['gaplusupstream'] = newname
    if x['manifest_digest'] == gaminussha:
        if x['name'] != upgrade_map['gaminus']:
            newname = re.sub(r'DOWNSTREAM','SNAPSHOT',x['name'])
            upgrade_map['gaminusupstream'] = newname
json_data = json.dumps(upgrade_map)
print(json_data)
