linter-drupalcs
=========================
This linter plugin for [Linter](https://github.com/AtomLinter/Linter) provides
an interface to [phpcs](http://pear.php.net/package/PHP_CodeSniffer/). It is a
fork of the [linter-phpcs](https://github.com/AtomLinter/linter-phpcs) package
modified to work better for Drupal projects.

### drupalcs Installation
Before using this plugin, you must ensure that `phpcs` is installed on your
system together with the Drupal coding standards.

To do this, follow the next steps:
```ShellSession
composer global require drupal/coder
sudo ln -s ~/.composer/vendor/bin/phpcs /usr/local/bin
phpcs --config-set installed_paths ~/.composer/vendor/drupal/coder/coder_sniffer
```
After you have completed the steps above, no additional configuration is required.

For more information about these procedures please check [this drupal article.](https://www.drupal.org/node/1419988)

### Features
Except for the regular inline coding standards issues, this package also add a
button to the status bar.

**copy drupalcs errors** can be used to get the errors to the clipboard so that
you can easily report them.

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

Here's is the example config:
```cson
'linter-drupalcs':
  executablePath: phpcs # phpcs path. run 'which phpcs' to find the path
  codeStandardOrConfigFile: 'Drupal' # Drupal coding standards file
  warningSeverity: 0 # phpcs warning-severity (0 to display only errors)
  ignore: '*.features.field_base.inc,*.features.field_instance.inc,*.features.inc' # ignore filename patterns
```
