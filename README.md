linter-drupalcs
=========================
This linter plugin for [Linter](https://github.com/AtomLinter/Linter) provides
an interface to [phpcs](http://pear.php.net/package/PHP_CodeSniffer/). It is a
fork of the [linter-phpcs](https://github.com/AtomLinter/linter-phpcs) package
modified to work better for Drupal projects.

### drupalcs Installation
Before using this plugin, you must ensure that `phpcs` is installed on your
system together with the Drupal coding standards.

For more information about these procedures please check [this drupal article.](https://www.drupal.org/node/1419988)


### Package Installation
You can then install this package either from within Atom or by running the
following command:
```ShellSession
$ apm install linter-drupalcs
```
Note: If you do not already have the `linter` package installed it will be installed
for you to provide an interface for this package.

## Settings
You can configure linter-phpcs from the Atom package manager or by editing
~/.atom/config.cson (choose Open Your Config in Atom menu).

Here's an example configuration:
```cson
'linter-phpcs':
  executablePath: phpcs # phpcs path. run 'which phpcs' to find the path
  codeStandardOrConfigFile: 'Drupal' # Drupal coding standards file
  warningSeverity: 0 # phpcs warning-severity (0 to display only errors)
  ignore: '*.features.field_base.inc,*.features.field_instance.inc,*.features.inc' # ignore filename patterns
```

## Contributing
If you would like to contribute enhancements or fixes, please do the following:

0. Fork the plugin repository
0. Hack on a separate topic branch created from the latest `master`
0. Commit and push the topic branch
0. Make a pull request
0. Welcome to the club!

Please note that modifications should follow these coding guidelines:

- Indent is 2 spaces.
- Code should pass coffeelint linter.
- Vertical whitespace helps readability, don’t be afraid to use it.

Thank you for helping out.
