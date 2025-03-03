[![Build](https://github.com/wibosco/BackgroundTransfer-Example/actions/workflows/swift.yml/badge.svg)](https://github.com/wibosco/BackgroundTransfer-Example/actions/workflows/swift.yml)
<a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5-orange.svg?style=flat" alt="Swift" /></a>
[![License](http://img.shields.io/badge/License-MIT-green.svg?style=flat)](https://github.com/wibosco/BackgroundTransfer-Example/blob/main/LICENSE)

# BackgroundTransfer-Example
An example project looking at how to implement background transfers on iOS as shown in this article - https://williamboles.com/keeping-things-going-when-the-user-leaves-with-urlsession-and-background-transfers/

In order to run this project, you will need to register with [Imgur](https://api.imgur.com/oauth2/addclient) to get a `client-id` token to access Imgur's API (which the project uses to get its example content). Once you have your `client-id`, add it to the project as the value of the `clientID` property in the `RequestConfig` class and the project should now run. If you have any trouble getting the project to run, please create an issue.
