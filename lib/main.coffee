{CompositeDisposable} = require 'atom'
module.exports =
  config:
    executablePath:
      type: 'string'
      default: 'phpcs'
      description: 'Enter the path to your phpcs executable.'
      order: 1
    codeStandardOrConfigFile:
      type: 'string'
      default: 'Drupal'
      description: 'If this is not working by default, you might need ' +
        'to point it to the file. Examples:<br />' +
        'os x: /users/**username**/.composer/vendor/drupal/coder/coder_sniffer/Drupal<br />' +
        'linux: /home/**username**/.composer/vendor/drupal/coder/coder_sniffer/Drupal<br />&nbsp;<br />' +
        'Please see <a href="https://www.drupal.org/node/1419988">this article</a> for more information.'
      order: 2
    disableWhenNoConfigFile:
      type: 'boolean'
      default: false
      description: 'Disable the linter when the default configuration file is not found.'
      order: 3
    ignore:
      type: 'string'
      default: '*.features.field_base.inc,*.features.field_instance.inc,*.features.inc'
      description: 'Enter filename patterns to ignore when running the linter.'
      order: 5
    warningSeverity:
      type: 'integer'
      default: 1
      description: 'Set the warning severity level. Enter 0 to display errors only.'
      order: 6
  activate: ->
    require('atom-package-deps').install('linter-drupalcs')
    @parameters = []
    @standard = ''
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe('linter-drupalcs.executablePath', (value) =>
      unless value
        value = 'phpcs' # Let os's $PATH handle the rest
      @command = value
    )
    @subscriptions.add atom.config.observe('linter-drupalcs.disableWhenNoConfigFile', (value) =>
      @disableWhenNoConfigFile = value
    )
    @subscriptions.add atom.config.observe('linter-drupalcs.codeStandardOrConfigFile', (value) =>
      @standard = value
    )
    @subscriptions.add atom.config.observe('linter-drupalcs.autoConfigSearch', (value) =>
      @autoConfigSearch = value
    )
    @subscriptions.add atom.config.observe('linter-drupalcs.ignore', (value) =>
      if value
        @ignore = value.split ','
    )
    @subscriptions.add atom.config.observe('linter-drupalcs.warningSeverity', (value) =>
      @parameters[2] = "--warning-severity=#{value}"
    )

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    path = require 'path'
    helpers = require 'atom-linter'
    minimatch = require 'minimatch'
    provider =
      name: 'DRUPALCS'
      grammarScopes: ['source.js', 'source.php']
      scope: 'file'
      lintOnFly: true
      lint: (textEditor) =>
        filePath = textEditor.getPath()

        # Check if file should be ignored
        baseName = path.basename filePath
        # Check if anything is being ignored.
        if @ignore
          return [] if @ignore.some (pattern) -> minimatch baseName, pattern

        eolChar = textEditor.getBuffer().lineEndingForRow(0)
        parameters = @parameters.filter (item) -> item
        standard = @standard
        command = @command
        confFile = helpers.findFile(path.dirname(filePath), ['phpcs.xml', 'phpcs.ruleset.xml'])
        standard = if @autoConfigSearch and confFile then confFile else standard
        return [] if @disableWhenNoConfigFile and not confFile
        if standard then parameters.push("--standard=#{standard}")
        parameters.push('--report=json')
        text = 'phpcs_input_file: ' + filePath + eolChar + textEditor.getText()
        return helpers.exec(command, parameters, {stdin: text}).then (result) ->
          try
            result = JSON.parse(result.toString().trim())
          catch error
            atom.notifications.addError('Error parsing PHPCS response', {
              detail: 'Something went wrong attempting to parse the PHPCS output.',
              dismissable: true}
            )
            console.log('PHPCS Response', result)
            return []
          return [] unless result.files[filePath]
          return result.files[filePath].messages.map (message) ->
            startPoint = [message.line - 1, message.column - 1]
            endPoint = [message.line - 1, message.column]
            return {
              type: message.type
              text: message.message
              filePath,
              range: [startPoint, endPoint]
            }
