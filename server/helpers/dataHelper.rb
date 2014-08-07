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
  # demonstrate returing text data with parameter.
  def HelloWorld(a)
    return "Howdy World from DataHelper. (I see you #{a}.)"
  end

  def CourseData(a)
    classJson = 
     [
      { :title => "English 323",
        :subtitle => "Austen and her contemporaries and #{a}",
        :location => "canvas",
        :link => "google.com",
        :instructor => "me: #{a}",
        :instructor_email => "howdy ho"
      },
      { :title => "German 323",
        :subtitle => "Beeoven and her contemporaries and #{a}",
        :location => "ctools",
        :link => "google.com",
        :instructor => "you: Mozarty",
        :instructor_email => "howdy haw"
      }
    ]
    
    return classJson;
  end
  
end
