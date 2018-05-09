require 'rubygems'
require 'rwordnet'
require 'ffi/aspell'
require 'engtagger'
require 'stanford-core-nlp'
require 'rjb'
require 'bind-it'

require 'text_preprocessing'
require 'predict_class'
require 'degree_of_relevance'
require 'plagiarism_check'
require 'tone'
require 'text_quantity'
require 'constants'
require 'review_coverage'

class MetareviewsController < ApplicationController
  skip_before_filter  :verify_authenticity_token
  before_filter :config_stanford_nlp
  respond_to :json

  def config_stanford_nlp
    StanfordCoreNLP.use :english
    StanfordCoreNLP.model_files = {}
    StanfordCoreNLP.default_jars = [
        'joda-time.jar',
        'xom.jar',
        'stanford-corenlp-3.5.0.jar',
        'stanford-corenlp-3.5.0-models.jar',
        'jollyday.jar',
        'bridge.jar'
    ]
  end

  def create
    review = params[:review]
    submission = params[:submission]
    rubric = params[:rubric]
    type = params[:type]

    auto_meta_review = Metareview.new
    features = auto_meta_review.send("calculate_#{type}",review, submission, rubric)
    render json: features.to_json
  end
end
