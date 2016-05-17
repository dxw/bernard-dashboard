class Dashing.Meter extends Dashing.Widget

  @accessor 'current', Dashing.AnimatedValue

  constructor: ->
    super
    @observe 'current', (current) ->
      $(@node).find(".meter").val(current).trigger('change')

  ready: ->
    meter = $(@node).find(".meter")
    meter.attr("data-bgcolor", meter.css("background-color"))
    meter.attr("data-fgcolor", meter.css("color"))
    meter.knob()
