# Harbor Scan Resource

Scans an image in harbor , returns the results, and will fail a build if CVE threshold is crossed.

## Source Configuration

* `username` -  username to log into harbor with
* `password` - password for harbor
* `harbor_host` - Required. The DNS host name or IP address that will be used to connect to your Harbor instance. 

## Check

this resource does not implement `check`

## In

this resource does not implement `in`

## Out Params

*  `repository` -  The registry path including [project]/[image_name] in Harbor.
*  `tag` - the image tag
*  `harbor_scan_thresholds` - json array of acceptable thresholds. Array must contain at least 1 threshold. The format must be severity (CVE Sev Level 1-5) & count (integer) for each desired threshold element in the array. severity 1 means there are vulnerabilities .


## Usage

see the examples directory for usage. The docker image can be found at `warroyo90/harbor-scan-resource`



