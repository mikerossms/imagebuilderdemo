# Core Image

The CORE Image build is a Canary build designed to test the build process and code base.  It requires some software to be uploaded into the Repo storage account before it will run successfully.  This will then test access to that storage account and ensure the image building process can acquire the software.

## Uploading the files

The easiest way to upload the files is to use Azure Storage Explorer, but the Azure Portal can also be used at a pinch.

First, in the storage account, all software used by the images is found in the "software" container.  This should already exist as it is created when the software account is created.  Into this "software" container create the following folders:

- Common
- Image-Specific-Core
- MMRHostInstaller

Into **Common** folder copy the following file:

*"/images/Common - FilesForSoftwareRepo/Common/ChocoCommonPackages.config"*

Into **MMRHostInstaller** copy the following file:

*"/images/Common - FilesForSoftwareRepo/MMRHostInstaller/MsMMRHostInstaller_x64.msi"*

(also worth checking to see if there is an [update](https://learn.microsoft.com/en-us/azure/virtual-desktop/multimedia-redirection) - note always ensure it is renamed to MsMMRHostInstaller_x64.msi)

Into **Image-Specific-Core** copy the following files:

*"/images/Core/FilesForSoftwareRepo/ChocoDevelopment.config"*

Now run the following pipelines:

*AVD-IB-Image-Core*
