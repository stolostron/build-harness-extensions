import json, os, time
import openshift as oc
from subprocess import check_output


def env_set(env_var, default):
    if env_var in os.environ:
        return os.environ[env_var]
    elif os.path.exists(env_var) and os.path.getsize(env_var) > 0:
        with open(env_var, 'r') as env_file:
            var = env_file.read().strip()
            env_file.close()
        return var
    else:
        return default


def main():
    org = env_set('PIPELINE_MANIFEST_MIRROR_ORG', 'acm-d')
    mirror_tag = env_set('PIPELINE_MANIFEST_MIRROR_TAG', 'multicluster-engine-1.0-rhel-8-container-candidate')

    max_retries = 5
    results = list_tags(mirror_tag)
    results = results.decode('utf8').replace("'", '"')
    images = json.loads(results)
    for index, image_data in enumerate(images):
        image_done =  False
        retries = 0
        while image_done == False:
            try:
                if (retries == 0):
                    retry_phrase = ""
                else:
                    retry_phrase = "(retry {} of {})".format(retries, max_retries)
                nvr = image_data['nvr']
                results2 = brew_build_info(nvr).decode('utf8').replace("'", '"')
                build = json.loads(results2)
                pullspec = build['extra']['image']['index']['pull'][0]
                nicespec = build['extra']['image']['index']['pull'][1].replace(
                        'registry-proxy.engineering.redhat.com/rh-osbs/multicluster-engine-', ''
                        )
                print('Initiating mirror of {} to {}, image {} of {} {}'.format(pullspec,nicespec,index+1,len(images),retry_phrase))
                oc.invoke(
                    'image',
                    cmd_args=[
                        'mirror',
                        '--keep-manifest-list=true',
                        '--filter-by-os=.*',
                        '{0}'.format(pullspec),
                        'quay.io/{0}/{1}'.format(org, nicespec)
                    ]
                )
                image_done = True
            except oc.OpenShiftPythonException as error:
                print('Unable to mirror image {}'.format(nicespec))
                try:
                    # Try to pluck out just the exact thing that went wrong
                    error_info = json.loads(str(error).strip("[Non-zero return code from invoke action]"))
                    print('{}'.format(error_info['actions'][0]['err']))
                except:
                    # If things go really awry, just print out the whole thing
                    print('error: {}'.format(str(error)))
                retries += 1
                if (retries < max_retries):
                    delay = 10 * retries
                    print("Sleeping for {} seconds before retrying...".format(delay))
                    time.sleep(delay)
                else:
                    print('Maximum retries reached for image; continuing')
                    image_done = True


def list_tags(tag):
    return check_output(
        [
            "brew",
            "call",
            "listTagged",
            tag,
            "--json-output",
            "None",
            "True",
            "None",
            "True"
        ]
    )


def brew_build_info(nvr):
    return check_output(
        [
            'brew',
            'call',
            'getBuild',
            nvr,
            '--json-output'
        ]
    )


if __name__ == '__main__':
    main()
