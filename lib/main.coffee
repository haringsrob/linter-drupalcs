{CompositeDisposable} = require 'atom'

path = require 'path'
fs = require('fs')
helpers = require 'atom-linter'
minimatch = require 'minimatch'
window.drupalcs_latest_data = 'drupalcs'

module.exports =
  config:
    executablePath:
      type: 'string'
      default: 'phpcs'
      description: 'Enter the path to your phpcs executable.'
      order: 1
    searchExecutablePath:
      type: 'boolean'
      default: false
      description: 'Search the local folder for an phpcs executable.'
      order: 3
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
    autoConfigSearch:
      title: 'Search for configuration files'
      type: 'boolean'
      default: true
      description: 'Automatically search for any `phpcs.xml`, `phpcs.ruleset.xml` or `phpcs-ruleset.xml` ' +
        'file to use as configuration. Overrides custom standards defined above.'
      order: 4
    ignore:
      type: 'string'
      default: ''
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
    @subscriptions.add atom.config.observe('linter-drupalcs.searchExecutablePath', (value) =>
      @searchExecutablePath = value
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


  # Status bar.
  consumeStatusBar: (statusBar) ->
    # Create our element.
    span = document.createElement('a')
    span.textContent = 'copy drupalcs errors'
    span.className = 'inline-block copy-drupalcs-errors'

    clickHandler = ->
      text = window.drupalcs_latest_data
      atom.clipboard.write(text)

    # Add onclick handler.
    span.addEventListener('click', clickHandler)

    @statusBarTile = statusBar.addLeftTile(item: span, priority: 0)

  deactivate: ->
    @subscriptions.dispose()
    @statusBar?.destroy()
    @statusBar = null


  provideLinter: ->
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
        original_command = @command

        # By default no phpcs exec.
        executable_phpcs = false

        ## Search for a local instance.
        if @searchExecutablePath
          for index, project_dir of atom.project.getPaths()
            checkfilepath = project_dir + '/bin/phpcs'
            if fs.existsSync(checkfilepath)
              executable_phpcs = checkfilepath

        ## If there is a relative one, we use this one.
        if executable_phpcs
          command = executable_phpcs

        # Get the config file.
        for index, filename of ['phpcs.ruleset.xml', 'phpcs-ruleset.xml', 'phpcs.xml']
          checkfilepath = project_dir + '/' + filename
          if fs.existsSync(checkfilepath)
            confFile = checkfilepath
            break

        # If we didnt fine a config file on path base, we can search deeper.
        if not confFile
          confFile = helpers.findFile(path.dirname(filePath), ['phpcs.ruleset.xml', 'phpcs-ruleset.xml', 'phpcs.xml'])

        # If a local executable is here, but no config file fall back to the
        # global config.
        if executable_phpcs and not confFile
          command = @command

        # Other configurations
        standard = if @autoConfigSearch and confFile then confFile else standard
        return [] if @disableWhenNoConfigFile and not confFile
        if standard
          parameters.push("--standard=#{standard}")

        # We'd like to receive 2 formats.
        parameters.push('--report=json')
        parameters.push('--report=full')
        text = 'phpcs_input_file: ' + filePath + eolChar + textEditor.getText()

        # Execute the request.
        return helpers.exec(command, parameters, {stdin: text}).then (result) ->
          # Convert the result to a string.
          resultstring = result.toString().split('FILE:')
          # First part is our json
          json_result = resultstring[0]
          # Rest is our full.
          full_result = 'FILE:' + resultstring[1]
          ## Complete regular results.
          try
            result = JSON.parse(json_result.trim())
          catch error
            atom.notifications.addError('Error parsing PHPCS response', {
              detail: 'Something went wrong attempting to parse the PHPCS output.',
              dismissable: true}
            )
            atom.notifications.addError('This is the error message', {
              detail: result,
              dismissable: true}
            )
            return []
          return [] unless result.files[filePath]
          return result.files[filePath].messages.map (message) ->
            ## Write the message to the global.
            if full_result
              window.drupalcs_latest_data = full_result
            ## Results for the project.
            startPoint = [message.line - 1, message.column - 1]
            endPoint = [message.line - 1, message.column]
            return {
              type: message.type
              text: message.message
              filePath,
              range: [startPoint, endPoint]
            }
