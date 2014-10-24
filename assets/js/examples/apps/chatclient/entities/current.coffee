ExamplesApp.module "ChatClientApp.Entities", (Entities) ->
  wrap =
    user: undefined

  ExamplesApp.ChatClientApp.reqres.setHandler "current:user", ->
    wrap.user

  ExamplesApp.ChatClientApp.commands.setHandler "set:current:user", (user)->
    wrap.user = user