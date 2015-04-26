require 'test_helper'

class MetareviewgeneratorControllerTest < ActionController::TestCase
  def test_create
    json = {reviews: "They do were necessary  but some of the points don't really lend themselves to being two sided.  Is phishing bad?",
            submission:"They do were necessary  but some of the points don't really lend themselves to being two sided.  Is phishing bad?", rubric: "describe the organization of the page."}.to_json
    post :create, json
    assert_response :found
  end


end
