require 'rubygems'
require 'wordnet'
require 'ffi/aspell'
require 'engtagger'
gem 'stanford-core-nlp', '=0.5.1'
require 'stanford-core-nlp'
gem 'rjb', "=1.4.3"
require 'rjb'
gem 'bind-it', "=0.2.7"
require 'bind-it'

require 'text_preprocessing'
require 'predict_class'
require 'degree_of_relevance'
require 'plagiarism_check'
require 'tone'
require 'text_quantity'
require 'constants'
require 'review_coverage'
class MetareviewgeneratorController < ApplicationController
  skip_before_filter  :verify_authenticity_token
  respond_to :json
  def create
    review_array=Array.new
    submission_array=Array.new
    rubricqns_array=Array.new
    review_array[0] = params[:reviews]
    submission_array[0] = params[:submission]
    rubricqns_array[0] = params[:rubric]

    puts review_array
    puts submission_array
    puts rubricqns_array
    preprocess = TextPreprocessing.new
    #setting up the output file

    for i in (0..review_array.length - 1)
      autometareview = Automated_Metareview.new
      review = Array.new
      submission = Array.new
      review << review_array[i]
      submission << submission_array[i]
      features = autometareview.calculate_metareview_metrics(review, submission, rubricqns_array)
      #write the features out to a file
      render json: features.to_json
    end
  end
  def index

  end
end