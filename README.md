SQSMetricFormatter
==================

SQSMetricFormatter is an NSNumberFormatter subclass that is capable of parsing and
displaying numbers in units (of the user's choice) that can include standard SI/metric
prefixes.  In addition to the subclass (and supporting code such as categories), the repo
includes unit tests and a trivial OS X demo application.

Requirements
------------

The SQSMetricFormatter code aims to be cross-platform (i.e. OS X and iOS), linking against
Foundation.framework.  Only the "modern" (10.4+) NSNumberFormatter behavior is supported.
While the code has no inherent dependency on a particular development environment, the
Xcode project encapsulating the code expects Xcode 4 or newer.

License
-------

SQSMetricFormatter and accompanying code is Copyright (C) 2011-2012 by Synthetiq Solutions
LLC and is made available under the standard 3-clause BSD license.  Please see the license
text at the top of any header file for full details.

If you wish to use this code but are unable to comply with the BSD license requirements
(including but not limited to attribution), proprietary licenses with or without technical
support are available.  Please contact [support@synthetiqsolutions.com][mailto] for more
information.

Usage
-----


Contributing
------------

If you would like to contribute, please fork the repository, commit your changes, and
submit a pull request.  Your pull request will get quicker attention if:

 * Each commit is limited in scoped and logged with appropriate comments.
 * Your pull request itself is well documented.
 
If you add a feature please also add one or more supporting unit tests.  Also please run
the unit test suite before submitting a pull requests; **pull requests that fail unit
testing will be rejected**.

Finally, and this goes without saying, please make sure that, if applicable, you have
permission from your employer or client to contribute work you have done for hire.

[mailto]: mailto:support@synthetiqsolutions.com?subject=SQSMetricFormatter%20license