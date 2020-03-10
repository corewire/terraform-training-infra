# How to use this!

## 1. Start Up needed Instances
### Prepare Vars
Go to the `secret.auto.tfvars.dist` and set up the Variables as needed, then save it WITHOUT the `dist`

### Start machines
```
tf init
tf apply
---> check values, then accept with 'yes'
```
Go get a fast Coffee, this should not take more than 5 Minutes (most likely 2-3 Minutes depending on Machine Count)

From the Terraform Output save "Server DNS Name" and "Server IP"

now ssh one time to the "Main" Server so ssh is initialised with the host key Check things.

## 2. Start Main Server Containers
### Prepare Vars
From Step 1, get the Server IP and DNS Name.
Enter them to `secret.auto.tfvars` in `./containers` path.

Remember the Vars you need to login!
User is `root`

### Start Containers
```
tf init
tf apply
----> Check values as before, then yes to confim
```
Now get a Coffee gitlab will take it's time.

## 3. Setup Gitlab
### Read the README.md in Gitlab Folder