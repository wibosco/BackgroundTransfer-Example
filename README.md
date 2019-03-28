[![Build Status](https://travis-ci.org/wibosco/DownloadStack-Example.svg)](https://travis-ci.org/wibosco/BackgroundTransfer-Example)
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat" alt="Swift" /></a>

# BackgroundTransfer-Example
An example project looking at how to implement background transfers on iOS as shown in this article - https://williamboles.me/keeping-things-going-when-the-user-leaves-with-urlsession-and-background-transfers/

In order to run this project, you will need to register with [Imgur](https://api.imgur.com/oauth2/addclient) to get a `client-id` token to access Imgur's API (which the project uses to get its example content). Once you have your `client-id`, add it to the project as the value of the `clientID` property in the `RequestConfig` class and the project should now run. If you have any trouble getting the project to run, please create an issue or get in touch with me on Twitter at [wibosco](https://twitter.com/wibosco).
