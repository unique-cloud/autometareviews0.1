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
class AutomatedMetareviewController < ApplicationController
  def AutomatedMetareview
    #class driver
    #run the code from here
    preprocess = TextPreprocessing.new
    review_array = preprocess.fetch_data("app/data/reviews.csv")
    submission_array = preprocess.fetch_data("app/data/submission.csv")
    rubricqns_array = preprocess.fetch_data("app/data/rubric.csv")
    #setting up the output file
    output_file = "app/data/output-sample.csv"
    csvWriter = CSV.open(output_file, "w")
    csvWriter << ["Review", "Submission", "Plagiarism", "Relevance", "Summative Content", "Problem Content",
                  "Advisory Content", "Coverage", "Positive Tone", "Negative Tone", "Neutral Tone", "Quantity"]

    for i in (0..review_array.length - 1)
      autometareview = Automated_Metareview.new
      review = Array.new
      submission = Array.new
      review << review_array[i]
      submission << submission_array[i]
      features = autometareview.calculate_metareview_metrics(review, submission, rubricqns_array)
      #write the features out to a file
      csvWriter << [review_array[i], submission_array[i], features["plagiarism"], features["relevance"], features["content_summative"],
                    features["content_problem"], features["content_advisory"], features["coverage"], features["tone_positive"],
                    features["tone_negative"], features["tone_neutral"], features["quantity"]]
      puts "finished"
    end
  end
end
