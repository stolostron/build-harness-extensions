import json
import sys
import os
import requests
import re

#
# snapshot-cleaner.py 
#
# Cleans up snapshot tags as they used to be applied to repos that look like the following:
#   vV.R.M-2022-02-11-20-38-34
# The repos to be cleaned are communicated via snapshot manifest file as the first parameter.

# Parameter:
#   sys.argv[1] - filename of a manifest to follow

# Dependencies:
#   GITHUB_TOKEN

old_org = "open-cluster-management"
new_org = "stolostron"

GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')

headers = {
    'Authorization': 'token '+GITHUB_TOKEN,
    'Accept': 'application/vnd.github.v3+json'
}

if len(sys.argv) < 2:
    print("Requires one argument: the filename of the manifest to follow")
    exit(1)

data = json.load(open(sys.argv[1]))
for v in data:
    # Use second-generation keys in manfiest
    repo_components = v["git-repository"].split('/')
    if len(repo_components) == 2:
        if repo_components[0] == new_org or repo_components[0] == old_org:
            repo=repo_components[1]
            print("Processing {}".format(repo))
            page = 0
            page_data=[]
            while True:
                page=page+1
                url = "https://api.github.com/repos/"+new_org+"/"+repo+"/tags?per_page=100&page={}".format(page)
                response_raw = requests.get(url, headers=headers)
                response = response_raw.json()
                if (len(response) == 0):
                    break
                if response_raw.ok:
                    page_data.extend(response)
                    # print("  Page {}, num={}".format(page,len(response)))
                else:
                    print("Response: {}".format(response))
                    exit(1)

            print("  Tags: {}".format(len(page_data)))
            for x in page_data:
                try:
                    tag = x.get("name")
                    if re.match("^[\\d]+\\.[\\d]+\\.[\\d]+-SNAPSHOT-\\d{4}(-\\d\\d){5}$",tag) or \
                            re.match("^[\\d]+\\.[\\d]+\\.[\\d]+-\\d{4}(-\\d\\d){5}$",tag) or \
                            re.match("^v[\\d]+\\.[\\d]+\\.[\\d]+-\\d{4}(-\\d\\d){5}$",tag) or \
                            re.match("^v[\\d]+\\.[\\d]+\\.[\\d]+-\\d{4}(-\\d\\d){5}a$",tag) or \
                            re.match("^v[\\d]+\\.[\\d]+\\.[\\d]+-\\d{4}(-\\d\\d){5}b$",tag):
                        url = "https://api.github.com/repos/"+new_org+"/"+repo+"/git/refs/tags/{}".format(tag)
                        try:
                            response = requests.delete(url, headers=headers)
                            if not response.ok:
                                response = requests.delete(url, headers=headers)
                            print("    "+tag+": {}".format(response.status_code))
                        except KeyboardInterrupt:
                            print("Interrupting...")
                            exit(1)
                        except BaseException as err:
                            print("Unexpected error type={}".format(err,type(err)))
                    else:
                        print("    Non-matching tag: {}".format(tag))
                except KeyboardInterrupt as err:
                    print("Interrupting...")
                    exit(1)
                except AttributeError as err:
                    message = response.get("message")
                    print("Message: {}".format(message))
                    exit(1)
                except SystemExit:
                    exit(1)
                except BaseException as err:
                    print("Unexpected error, type={}".format(type(err)))
                    print("Was working on response: {}".format(x))
        else:
            print("Skipping {}".format(repo_components[1]))

