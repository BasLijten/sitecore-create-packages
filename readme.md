# How to use the script

This script allows to make changes to existing web deploy packages by specifying new parameters. Read more about this approach on this [blog](http://blog.baslijten.com/how-to-update-the-default-hashing-algorithm-for-sitecore-9-to-sha512-using-msdeploy/):


## Output
 This script currently executes the following tasks:

* Create two packages: provision and deploy

### provision

Adds parameters to change the hashing algorithm to SHA512. By adding a parameter to the package with a default value, existing ARM templates will not break. It will change the SHA1 algorithm to SHA2_512 in the SetAdministratorPassword.sql within the archive _and_ it will enlarge the size of @hashedpassword. Initially this is just 20 bytes long (thanks [Marshall Sorenson](https://blogs.perficient.com/sitecore/2018/06/20/upgrading-the-password-hashing-algorithm-for-sitecore-9-installs/)!!!), which isn't long enough for a SHA512-hashed password

### deploy

Adds the SHA512 parameter to the parameters.xml, adds the IIS Web Application Name, which will make the generated package ready to use with the App Service deploy task in VSTS (as described in this [blog](http://blog.baslijten.com/how-to-deploy-sitecore-web-deploy-packages-using-the-vsts-azure-app-service-task/)) and removes the databases from the package.
the "*.declareparam.xml" parameterfiles are used to specify the _new_ parameters that are used for deploying to an existing sitecore environment.

## How to run

* copy your Sitecore XP Single package to the resources directory. 
* if your packagename is "sitecore.scwdp.zip", then rename the provided xml to sitecore.declareparam.xml
* the match is done based on the "basename" of the package.
* run the script with the path to the package you want to change. It's output is in the same directory  

