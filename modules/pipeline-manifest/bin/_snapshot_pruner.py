# Prunes a snapshot directory to only keep the last snapshot for the day,
# but don't remove any snapshots that are less than 2 days old

# Parameters:
#  sys.argv[1] - snapshot directory to prune
#  sys.argv[2] - actually delete files? must be text literal 'True' if so

import os
import re
import sys
from datetime import date, timedelta, datetime

def main():
    dry_run = True

    if ((len(sys.argv) == 2) or (len(sys.argv) == 3)):
        snapshot_dir = sys.argv[1]
        if (len(sys.argv) == 3):
            for_reals = sys.argv[2]
            if (for_reals == "True"):
                dry_run = False;
                print('Second argument is "True"; actual changes will be made')
        else:
            for_reals = "False"
        if (dry_run == True):
            print('Second argument is not "True"; only rehearsing changes')
    else:
        print("Syntax: python3 _snapshot_pruner.py <directory> [True]")
        exit(1)

    files = os.listdir(snapshot_dir)
    files.sort()

    stop = date.today() - timedelta(days=2)

    prev_file = None

    found_one = False
    for one_file in files:
        # print(one_file)
        day_prev_file = day(prev_file)
        day_one_file = day(one_file)
        if ((day_prev_file != None) and (day_one_file != None)):
            found_one = True
            if ((day_prev_file == day_one_file) and (stop > day_one_file)):
                print('delete {}'.format(prev_file))
                if (dry_run == False):
                    fq_filename = "{}/{}".format(snapshot_dir,prev_file)
                    os.remove(fq_filename)
            else:
                print('keep {}'.format(prev_file))
            #if (stop <= day_one_file):
            #    print('keep {} because it is too new; cutoff date is {}.'.format(prev_file,stop))
        prev_file = one_file
    if (found_one == False):
        print('Did not find any manifests to process.  Quitting.')
        exit (1)

def day(file_name):
    # print('day entry; file_name: {}'.format(file_name))
    # i.e. manifest-2021-07-21-17-30-49-1.0.0.json
    try:
        # Coerce a file name into a datetime object, return just the date portion
        full_datetime_string = re.search('manifest-([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2})-[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}\.json', file_name).group(1)
        datetime_object = datetime.strptime(full_datetime_string, '%Y-%m-%d-%H-%M-%S')
        found = datetime_object.date()
    except AttributeError:
        # Not found
        found = None
    except TypeError:
        # Not found
        found = None
    return found

if __name__ == '__main__':
    main()
