{ SymbolSuggestion, PrimitiveValueSuggestion, DeclarationSuggestion, ControlLogicSuggestion } = require './suggester/suggestion'
{ Replacement } = require "./edit/replacement"
{ Declaration } = require "./edit/declaration"


module.exports.Fixer = class Fixer

  apply: (model, suggestion) ->

    # TODO: eventually this should add the smallest range that defines
    # the symbol, but right now it adds lines
    if suggestion instanceof SymbolSuggestion
      codeBuffer = model.getCodeBuffer()
      symbolRange = suggestion.getSymbol().getRange()
      startRowRange = codeBuffer.rangeForRow symbolRange.start.row
      endRowRange = codeBuffer.rangeForRow symbolRange.end.row
      rangeUnion = startRowRange.union endRowRange
      model.getRangeSet().getActiveRanges().push rangeUnion

    else if suggestion instanceof PrimitiveValueSuggestion

      # First, update the example by making a replacement
      edit = new Replacement suggestion.getSymbol(), suggestion.getValueString()
      model.getEdits().push edit

      # Next, make sure that the symbol is no longer marked
      # as a "use" in the model (avert future definition errors)
      uses = model.getSymbols().getUses()
      useIndex = 0
      for use in uses
        if use.equals suggestion.getSymbol()
          uses.splice useIndex, 1
          break
        useIndex += 1

    else if suggestion instanceof DeclarationSuggestion
      symbol = suggestion.getSymbol()
      declaration = new Declaration symbol.getName(), symbol.getType()
      model.getAuxiliaryDeclarations().push declaration

    else if suggestion instanceof ControlLogicSuggestion
      model.getRangeSet().getActiveRanges().push suggestion.getRange()