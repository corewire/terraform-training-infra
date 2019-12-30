# Gitlab Setup
### Get Access Key
- on the Gitlab instance Login with `root` and `***pass***` Setup in Container Part
- Navigate to Right Top Corner and go to the User Settings
- Then Navigate to `Access Tokens`
- Create a Token with full scopes setup
- copy token so the `secrets.auto.tfvars` file

### Apply Gitlab things
```
tf init
tf apply
----> check outcome, apply if wanted
```
### Save output to JSON
needed until `import_from` flag is being supported
```
tf output -json > output.json
```
IMPORTANT: filename has to be output.json, or you need to change the filename in `push-gits.py`

### Clone your gits to Gitlab
Clone your gits to the Folder: `handson-gits`.
View the `push-gits.py` File, change the Names of your Gits to the wanted values.

The script will change the origin and push them to the "new" ones.
run with:
```
python3 ./push-gits.py
```