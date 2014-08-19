# demonstrate how to create independent helper for sinatra app.
# 1) require this file from base app script.
# 2) call with () from sinatra block.

module TinyHelper
  ## This returns text which is then passed to template as a
  ## value in the locals object.  Variable evalution is done
  ## along the way so all the template does with this is 
  ## use it as a text string.
  def HelloWorld(a)
    return "Howdy World from TinyHelper. (I see you #{a}.)"
  end
end
