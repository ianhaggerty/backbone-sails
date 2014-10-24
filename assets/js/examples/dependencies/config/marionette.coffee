Backbone.Marionette.Renderer.render = (template, data) ->
  # this is here so that check's for undefined are possible
  # from the template. e.g. <%= locals.firstName || "" %>
  data.locals = data
  JST["assets/templates/" + template + ".ejs"] data