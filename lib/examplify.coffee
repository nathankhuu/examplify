{ CompositeDisposable } = require 'atom'
{ CodeView } = require './code-view'
{ ExampleModel, ExampleView } = require './example-view'
{ ExampleController } = require './example-controller'
{ DefUseAnalysis } = require './def-use'
{ ValueAnalysis } = require './value-analysis'
{ RangeSet } = require './model/range-set'
{ SymbolSet } = require './model/symbol-set'
$ = require 'jquery'


EXAMPLE_FILE_NAME = "SmallScoop.java"


module.exports = plugin =

  subscriptions: null
  # controller: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable()
    @subscriptions.add (atom.commands.add 'atom-workspace',
      'examplify:make-example-code': =>
        @codeEditor = atom.workspace.getActiveTextEditor()
        (atom.workspace.open EXAMPLE_FILE_NAME, { split: 'right' }).then \
          (exampleEditor) =>
            @controller = new MainController @codeEditor, exampleEditor
      'examplify:add-selection-to-example': =>
        selectedRange = @codeEditor.getSelectedBufferRange()
        rangeSet = @controller.getModel().getRangeSet()
        rangeSet.getActiveRanges().push selectedRange
    )

  deactivate: () ->
    this.subscriptions.dispose()

  serialize: () ->
    return {}


module.exports.MainController = class MainController

  constructor: (codeEditor, exampleEditor) ->

    selectedRange = codeEditor.getSelectedBufferRange()
    activeRanges = [ selectedRange ]

    # Prepare models (data)
    @rangeSet = new RangeSet activeRanges
    @symbols = new SymbolSet()
    @exampleModel = new ExampleModel codeEditor.getBuffer(), @rangeSet, @symbols

    # Prepare views
    @codeView = new CodeView codeEditor, @rangeSet
    @exampleView = new ExampleView @exampleModel, exampleEditor

    # Prepare controllers
    @defUseAnalysis = new DefUseAnalysis codeEditor.getPath(), codeEditor.getTitle()
    @valueAnalysis = new ValueAnalysis codeEditor.getPath(), codeEditor.getTitle()
    @exampleController = new ExampleController @exampleModel, @defUseAnalysis, @valueAnalysis

  # These accessors are here to let us test the controller
  getRangeSet: ->
    @rangeSet

  getModel: ->
    @exampleModel
