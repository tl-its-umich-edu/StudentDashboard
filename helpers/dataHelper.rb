# Return course list information in required format.
# Can combine data from multiple sources and format it.
## want to return information in this format
# {
#       "title": "English 323",
#       "subtitle": "Austen and her contemporaries",
#       "location": "canvas",
#       "link": "https://some.canvas.url",
#       "instructor": "Jane Austen",
#       "instructor_email": "jausten@umich.edu"
#   }


module DataHelper
  def HelloWorld(a)
    return "Howdy World from DataHelper. (I see you #{a}.)"
  end
  
end
