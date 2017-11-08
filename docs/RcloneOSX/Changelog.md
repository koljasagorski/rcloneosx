# Changelog

I have commenced a new project adapting RsyncOSX to RcloneOSX. RcloneOSX is, when it is released in version 1.0.0, utlizing the [rclone](https://rclone.org) command line tool for backup/copy files to various number of cloud storage services as Dropbox. I am still learning the `rclone` utility and I dont know when the first alfa of RcloneOSX will be relased.

## Version 0.0.1

By a couple of hours work with RcloneOSX I managed to do a `rclone copy` of a local directory to remote directory at Dropbox and Microsoft Onedrive. The Numbers part does not work yet because the output from `rclone` is quite different compared to `rsync`. Below are some screenshots from testing.

Adding cloud services is done by using the command line interface `rclone config`.

### Test for Dropbox

Adding a configuration...
![](Screenshots/rclone1.png)
![](Screenshots/rclone2.png)
Executing a `--dry-run`
![](Screenshots/rclone3.png)
Executing the real run. Some files are not copied.
![](Screenshots/rclone4.png)
The progress bar is working.
![](Screenshots/rclone5.png)
Logging the run in main view.
![](Screenshots/rclone6.png)
Logging the run, the numbers not yet working.
![](Screenshots/rclone7.png)
The transferred files at Dropbox.
![](Screenshots/rclone8.png)
And batch work is working "out of the box"
![](Screenshots/rclone9.png)
![](Screenshots/rclone10.png)

### Test for Onedrive

Adding a configuration...
![](Screenshots/onedrive1.png)
Execute task...
![](Screenshots/onedrive2.png)
Files are transferred to Onedrive...
![](Screenshots/onedrive3.png)