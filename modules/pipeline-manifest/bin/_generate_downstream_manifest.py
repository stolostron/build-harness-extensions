#!/usr/bin/enr python3

import os
import click
import json
import requests
import re
import urllib3
import signal
import sys
import time

from requests_kerberos import HTTPKerberosAuth
from subprocess import check_output

urllib3.disable_warnings()
new_manifest = []
image_alias = []
build_names = []
release_manifest = []

def get_upstream_sha(container, sha):
    # print('looking for container {} with sha {}'.format(container,sha))
    # Note: he system running this command must also have certs configured via:
    # https://source.redhat.com/groups/public/identity-access-management/identity__access_management_wiki/specification_recommended_system_level_pki_settings
    # Note: the following bash env variable must be set to configure the ca bundle
    #       that will be used by python.  
    # export REQUESTS_CA_BUNDLE=/etc/pki/tls/certs/ca-bundle.crt
    req_string = 'https://pkgs.devel.redhat.com/cgit/containers/{}/plain/container.yaml?id={}'.format(container,sha)
    # print (req_string)
    res = requests.get(
        req_string
    )
    try:
        result = re.search("ref: (.*)", res.text).group(1)
    except:
        result = None
    return result

def contains_key_val(key, val, return_key, image_alias):
    ret_val = None
    for image in image_alias:
        if (image[key] == val):
            try:
                ret_val = image[return_key]
            except:
                ret_val = None
            break
    # print('does key {} have value {} in image_alias?  Here it is: {}'.format(key, val, ret_val))
    return ret_val

def get_val(key, my_dict):
    # print('what value corresponds with key {} in dictionary?'.format(key))
    ret_val = None
    for element in my_dict:
        # print("element: {}".format(element))
        if element['image-downstream-name'] == key:
            ret_val = element
            break
    # print('what value corresponds with key {} in dictionary? {}'.format(key, ret_val))
    return ret_val

def get_key_downstream(key, my_dict):
    # print('what value corresponds with key {} in dictionary?'.format(key))
    ret_val = None
    for element in my_dict:
        # print("element: {}".format(element))
        if element['image-key'] == key:
            ret_val = element
            break
    # print('what value corresponds with key {} in dictionary? {}'.format(key, ret_val))
    return ret_val

def get_matching_entry(value, field, my_dict):
    # print('what entry corresponds with value {} in field {} in dictionary?'.format(value, field))
    ret_val = None
    for element in my_dict:
        # print("element: {}".format(element))
        if element[field] == value:
            ret_val = element
            break
    # print('what entry corresponds with value {} in field {} in dictionary? {}'.format(value, field, ret_val))
    return ret_val

def main():
    image_alias_filename = 'pipeline/image-alias.json'
    build_name_filename = 'ashdod/source-list.json'
    release_manifest_filename = 'acm-operator-bundle-manifest.json'
    datestamp = os.getenv('DATESTAMP')
    snapshot_name = os.getenv('PIPELINE_MANFIEST_INDEX_IMAGE_TAG')
    z_release_version = os.getenv('Z_RELEASE_VERSION')

    # Prepare the manifest filename based on the snapshot (i.e. 2.3.0-DOWNSTREAM-2021-02-13-19-51-30 -> manifest-2021-02-13-19-51-30-2.3.0.json) 
    manifest_filename = 'pipeline/snapshots/manifest-'+datestamp+'-'+z_release_version+'.json'

    # Grab the list of images as they exist in the upstream snapshot from the pipeline
    # Gives us: the main structure to iterate through, forms the basis of downstream manifest
    try:
        with open(manifest_filename) as json_file:
            manifest = json.load(json_file)
    except:
        print('ERROR: no {} file found.'.format(manifest_filename))
        manifest = []

    # Grab the list of images particular to this downstream build, obtained as a side-effect from ashdod 
    # Gives us: 
    #    Most of the downstream info about an image
    #    The matching upstream commit from github
    try:
        with open(build_name_filename) as json_file:
            build_names = json.load(json_file)
    except:
        print('ERROR: no {} file found.'.format(build_name_filename))
        build_names = []

    # Grab the image-alias.json from the pipeline
    # Gives us: the mapping from upstream to downstream container names (most of the time)
    try:
        with open(image_alias_filename) as json_file:
            image_alias = json.load(json_file)
    except:
        print('ERROR: no {} file found.'.format(image_alias_filename))
        image_alias = []

    # Grab the list of images as extracted from the acm-operator-bundle image
    # Uniquely gives us:
    #     endpoint-monitoring-operator
    #     grafana
    #     hive
    #     multicluster-operators-subscription
    #     multiclusterhub-operator
    #     origin-oauth-proxy
    try:
        with open(release_manifest_filename) as json_file:
            release_manifest = json.load(json_file)
    except:
        print('ERROR: no {} file found.'.format(release_manifest_filename))
        release_manifest = []

    print('Number of images in upstream manifest, {}: {}'.format(manifest_filename,len(manifest)))
    print('Number of ashdod build images, {}: {}'.format(build_name_filename,len(build_names)))
    print('Number of aliases in image_alias, {}: {}'.format(image_alias_filename,len(image_alias)))
    print('Number of images in acm-operator-bundle, {}: {}'.format(release_manifest_filename,len(release_manifest)))

    for image in manifest:
        downstream_image = contains_key_val('image-name',image['image-name'],'image-downstream',image_alias)
        downstream_key = contains_key_val('image-name',image['image-name'],'image-key',image_alias)
        if downstream_image:
            # print('working on downstream_image {}, key {}'.format(downstream_image,downstream_key))
            container_name = downstream_image
            downstream_image_decorated = downstream_image
            if downstream_image_decorated.endswith('search-operator'):
                downstream_image_decorated = "search-rhel8"
            else:
                if downstream_image_decorated.endswith('-operator'):
                    # Replace the last occurrence of '-operator' with '-rhel8-operator' because brew, that's why
                    downstream_image_decorated = '-rhel8-operator'.join(downstream_image.rsplit('-operator',1))
                else:
                    downstream_image_decorated=downstream_image+'-rhel8'
            # Need to find the upstream git sha of the resultant downstream build
            downstream_image_element = get_val(downstream_image_decorated,build_names)
            if not downstream_image_element:
                downstream_image_decorated = downstream_image
                if downstream_image_decorated.endswith('-operator'):
                    # Replace the last occurrence of '-operator' with '-rhel7-operator' because brew, that's why
                    downstream_image_decorated = '-rhel7-operator'.join(downstream_image.rsplit('-operator',1))
                else:
                    downstream_image_decorated=downstream_image+'-rhel7'
                downstream_image_element = get_val(downstream_image_decorated,build_names)
            if not downstream_image_element:
                # Maybe the operator bit isn't swapped?
                downstream_image_decorated = downstream_image+'-rhel8'
                downstream_image_element = get_val(downstream_image_decorated,build_names)
            if not downstream_image_element:
                # Ok, maybe it doesn't have a suffix at all (looking at you, grafana)?
                downstream_image_element = get_val(downstream_image,build_names)
            if downstream_image_element:
                upstream_git_sha = get_upstream_sha(container_name,downstream_image_element['midstream-git-sha256'])
                image['image-downstream-name'] = downstream_image_element['image-downstream-name']
                image['image-downstream-version'] = downstream_image_element['image-downstream-version']
                image['image-downstream-remote'] = 'quay.io/acm-d'
                image['image-downstream-digest'] = downstream_image_element['image-downstream-digest']
                if upstream_git_sha == None:
                    print('WARNING: container {} does not have a midstream repo to identify upstream sha.'.format(downstream_image_element['image-downstream-name']))
                else:
                    image['git-sha256-taken-downstream'] = upstream_git_sha
            else:
                print('can\'t find image {} association in the downstream build.'.format(downstream_image))
                downstream_image_element = get_key_downstream(downstream_key,release_manifest)
                if (downstream_image_element):
                    image['image-downstream-name'] = downstream_image_element['image-name']
                    image['image-downstream-version'] = downstream_image_element['image-tag']
                    image['image-downstream-remote'] = 'quay.io/acm-d'
                    image['image-downstream-digest'] = downstream_image_element['image-digest']
                else:
                    # print('oh fark, image {} doesn\'t have any entry.'.format(image['image-name']))
                    pass
        else:
            # print('manifest image {} doesn\'t have an image alias.'.format(image['image-name']))
            pass
        new_manifest.append(image)
        # print(json.dumps(image,indent=4))
    # Now we need to pick up the bundle images
    for build in build_names:
        if build['image-downstream-name'].endswith('-operator-bundle'):
            build['image-downstream-remote'] = 'quay.io/acm-d'
            new_manifest.append(build)
    newFileName = 'downstream-'+datestamp+'-'+z_release_version+'.json'
    # print('newFileName: {}'.format(newFileName))
    with open(newFileName, 'w') as outfile:
        outfile.write(json.dumps(new_manifest, indent=4))

if __name__ == '__main__':
    main()
