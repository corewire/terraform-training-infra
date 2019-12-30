#! /usr/bin/python3

import os
import json

def read_file():
    test = os.getcwd()
    with open(test + "/output.json") as json_file:
        text = json_file.read()
        json_data = json.loads(text)
    return json_data

def push_gits(json_data):
    """
    This is a dirty Fix until the Pull request for "gitlab terraform Provider" - "Add import_url" is throught.
    Use this to push your gits to the Gitlab instance.
    Dirty hard coded names and stuff, ugly 
    Hopefully python3 is your thing!
    """

    ### "Multi" Project, push it to multiple destinations
    for git in json_data["CHANGEME_MULTI_PROJECT_1"]["value"]:
        print(git)
        cmd = "cd " + os.getcwd() + "/handson-gits/CHANGEME_MULTI_PROJECT_1 && git remote add temp " + git + " && git push temp --all && git remote rm temp"
        print(cmd)
        os.system(cmd)
    
    ### "Single" Projects - only push them once - maybe to a group
    if json_data["git_01"]["value"]:
        git = json_data["git_01"]["value"]
        cmd = "cd " + os.getcwd() + "/handson-gits/git-01 && git remote add temp " + git + " && git push temp --all && git remote rm temp"
        os.system(cmd)

    if json_data["git_02"]["value"]:
        git = json_data["git_02"]["value"]
        cmd = "cd " + os.getcwd() + "/handson-gits/git-02 && git remote add temp " + git + " && git push temp --all && git remote rm temp"
        os.system(cmd)

if __name__ == "__main__":
    json_data = read_file()
    push_gits(json_data)
