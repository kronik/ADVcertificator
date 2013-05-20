What is ADVcertificator
=======================

ADVcertificator is an iOS library and toolset making it easy to implement client certificate authentication and SSL server certificate pinning in iOS applications.


Content
=======

ADVCertificator: an iOS static library.

ADVcertificator-sample: a sample iPhone application demonstrating the use of the ADVcertificator library.

 
How to Build
============

Open the ADVcertificator workspace (ADVcertificator.xcworkspace) in Xcode and build the target ADVCertificator-sample. The sample can be run either in the simulator or on an actual device.


How to use the Sample
==========================

The sample demonstrates some of the capabilities of ADVcertificator:

* Import Client Certificate (AdvImportCertificateViewController): Import a PKCS#12 embedded in the bundle and store it in the keychain.

* View Client Certificates (ADVCertificateTableViewController): Displays client certificates, such as the certificate imported with "Import Client Certificate". You can also remove certificates.

* Test Web View with Client Certificate (AdvWebViewController): This is something not easy to do normally and ADVcertificator will help you a lot! By default, this web view connects to the URL https://advcertificator.advtools.info/client/ that is configure to request a client certificate (from our own private PKI). If the SSL connection is established, the page displays some details of the SSL client certificate. At the bottom, you can click on the arrow to get details about the server certificate.

* Test SSL Connection with Pinning (AdvTestSSLConnectionViewController): It uses a regular NSURLRequest to connect to our demo web site. Thanks to the code declared in AdvAppDelagate, the SSL server certificate is automatically validated following a list of rules ("pinning"). In this sample, the fingerprint and the subject of the certificate are verified.

* View Server Certificate Pinning Rules (ADVSSLPinningRulesViewController): Displays the rules used for SSL server certificate pinning.


ADVcertificator sample web site and certificates
================================================

In order to demonstrate ADVcertificator, we have generated a SSL client certificate (from a private PKI) and we have put in place an SSL web server, https://advcertificator.advtools.info. This SSL server uses an SSL certificate from RapidSSL and the URL https://advcertificator.advtools.info/client/ is configured to request an SSL client certificate from our private PKI. Such certificate is embedded in the sample application.

This web server is only for demonstration. In case of abuse, we will banish your IP address (and probably your company) and take any other appropriate measures.



Copyright and license
=====================

Written by Daniel Cerutti and Sebastien Andrivet

Copyright (c) 2013 - [ADVTOOLS SARL](http://www.advtools.com)
 
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

If you want to use ADVcertificator in commercial (closed-source) products, please visit [ADVTOOLS web site](http://www.advtools.com/Products/ADVcertificator.html)
