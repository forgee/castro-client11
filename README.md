# Client 11 login service for Castro AAC

[![license](https://img.shields.io/packagist/l/doctrine/orm.svg)](https://github.com/forgee/castro-client11/blob/master/LICENSE.md)
[![release](https://img.shields.io/github/release/forgee/castro-client11.svg)](https://github.com/forgee/castro-client11/releases)

Be aware that this extension is in an experimental stage and may not always work as expected. *Please report any bugs you may encounter!*

Add support for Client 11 login to [Castro AAC](https://github.com/raggaer/castro). Fully supports [OTX](https://github.com/mattyx14/otxserver) cast system and should work with [TFS](https://github.com/otland/forgottenserver/pull/2230) if you have Client 11 support on your server (untested).

**Installation**
```cd castro install dir
git clone https://github.com/forgee/castro-client11.git
```
Or copy this repository to (path)/castro/extensions. Make sure that you get a folder named castro-client11 inside the extensions folder.

Then log in with your admin account and go to domain.name/subtopic/admin/extensions/install. Find *Client 11 login service* and click install.

**Connecting**

Use IP domain.name/nocsrf/play

A thank you to [Znote](https://otland.net/members/znote.5993/) for the response structure and [Slavidodo](https://otland.net/members/slavi-dodo.214342/) for the error codes.