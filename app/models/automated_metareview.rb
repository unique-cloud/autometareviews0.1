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

class Automated_Metareview
  #belongs_to :response, :class_name => 'Response', :foreign_key => 'response_id'
  #has_many :scores, :class_name => 'Score', :foreign_key => 'response_id', :dependent => :destroy
  attr_accessor :review_array
  #the code that drives the metareviewing
  def calculate_metareview_metrics(review, submission, rubricqns_array)
    
    feature_values = Hash.new #contains the values for each of the metareview features calculated
    # puts "inside perform_metareviews!!"    
    preprocess = TextPreprocessing.new
    # puts "map_id #{map_id}"
    #fetch the review data as an array 
    @review_array = review 
    
    # puts "self.responses #{self.responses}"
    speller = FFI::Aspell::Speller.new('en_US')
    # speller.suggestion_mode = Aspell::NORMAL
    @review_array = preprocess.check_correct_spellings(@review_array, speller)
#    puts "printing review_array"
#    @review_array.each{
#      |rev|
#      puts rev
#    }
    
    #checking for plagiarism by comparing with question and responses
    plag_instance = PlagiarismChecker.new
    result_comparison = plag_instance.compare_reviews_with_questions_responses(@review_array, rubricqns_array)
    # puts "review_array.length #{@review_array.length}"
    
    if(result_comparison == ALL_RESPONSES_PLAGIARISED)
      content_summative = 0
      content_problem = 0 
      content_advisory =  0
      relevance = 0
      quantity = 0
      tone_positive = 0
      tone_negative = 0
      tone_neutral =  0
      plagiarism = true
      # puts "All responses are copied!!"
      feature_valuee["plagiarism"] = plagiarism
      feature_valuee["relevance"] = relevance
      feature_valuee["content_summative"] = content_summative
      feature_valuee["content_problem"] = content_problem
      feature_valuee["content_advisory"] = content_advisory
      feature_valuee["coverage"] = coverage
      feature_valuee["tone_positive"] = tone_positive
      feature_valuee["tone_negative"] = tone_negative
      feature_valuee["tone_neutral"] = tone_neutral
      feature_valuee["quantity"] = quantity
      return feature_valuee
      
      return
    elsif(result_comparison == SOME_RESPONSES_PLAGIARISED)
      plagiarism = true
    end
    
    #checking plagiarism (by comparing responses with search results from google), we look for quoted text, exact copies i.e.
    google_plagiarised = plag_instance.google_search_response(self)
    if(google_plagiarised == true)
      plagiarism = true
    else
      plagiarism = false
  end
  #puts "No plagiarism"
 
    # puts "length of review array after google check - #{@review_array.length}"
    if(@review_array.length > 0)
      #formatting the review responses, segmenting them at punctuations
      review_text = preprocess.segment_text(0, @review_array)
      #removing quoted text from reviews
      review_text = preprocess.remove_text_within_quotes(review_text) #review_text is an array
      puts "review_text #{review_text}"
      #fetching submission data as an array and segmenting them at punctuations    
      submissions = submission
      subm_text = preprocess.check_correct_spellings(submissions, speller)
      subm_text = preprocess.segment_text(0, subm_text)
      subm_text = preprocess.remove_text_within_quotes(subm_text)
      puts "subm_text #{subm_text}"
      # #initializing the pos tagger and nlp tagger/semantic parser  
      pos_tagger = EngTagger.new
      core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
      
      #---------    
      #relevance
      beginning_time = Time.now
      relev = DegreeOfRelevance.new
      relevance = relev.get_relevance(review_text, subm_text, 1, pos_tagger, core_NLP_tagger, speller) #1 indicates the number of reviews
      #assigninging the graph generated for the review to the class variable, in order to reuse it for content classification
      review_graph = relev.review
      #calculating end time
      end_time = Time.now
      relevance_time = end_time - beginning_time
#      puts "************* relevance - #{relevance}" 
#      puts "************* relevance_time - #{relevance_time}"      
      #---------    
      # checking for plagiarism
      if(plagiarism != true) #if plagiarism hasn't already been set
        beginning_time = Time.now
        result = plag_instance.check_for_plagiarism(review_text, subm_text)
        if(result == true)
          plagiarism = "TRUE"
        else
          plagiarism = "FALSE"
        end
        end_time = Time.now
        plagiarism_time = end_time - beginning_time
        puts "************* plagiarism time taken - #{plagiarism_time}"
      end
      #---------      
      #content
      beginning_time = Time.now
      content_instance = PredictClass.new
      pattern_files_array = ["data/patterns-assess.csv",
        "data/patterns-prob-detect.csv",
        "data/patterns-suggest.csv"]
      #predcting class - last parameter is the number of classes
      content_probs = content_instance.predict_classes(pos_tagger, core_NLP_tagger, review_text, review_graph, pattern_files_array, pattern_files_array.length)
      content = "SUMMATIVE - #{(content_probs[0] * 10000).round.to_f/10000}, PROBLEM - #{(content_probs[1] * 10000).round.to_f/10000}, SUGGESTION - #{(content_probs[2] * 10000).round.to_f/10000}"
      end_time = Time.now
      content_time = end_time - beginning_time
      content_summative = content_probs[0]# * 10000).round.to_f/10000
      content_problem = content_probs[1] #* 10000).round.to_f/10000
      content_advisory = content_probs[2] #* 10000).round.to_f/10000
      puts "************* content time taken - #{content_time}"
#      puts "*************"
      #---------    
      #coverage
      cover = ReviewCoverage.new
      coverage = cover.calculate_coverage(subm_text, review_text, pos_tagger, core_NLP_tagger, speller)
#      puts "************* coverage - #{coverage}"
#      puts "*************"
      #---------    
      # tone
      beginning_time = Time.now
      ton = Tone.new
      tone_array = Array.new
      tone_array = ton.identify_tone(pos_tagger, speller, core_NLP_tagger, review_text, review_graph)
      tone_positive = tone_array[0]#* 10000).round.to_f/10000
      tone_negative = tone_array[1]#* 10000).round.to_f/10000
      tone_neutral = tone_array[2]#* 10000).round.to_f/10000
      #tone = "POSITIVE - #{(tone_array[0]* 10000).round.to_f/10000}, NEGATIVE - #{(tone_array[1]* 10000).round.to_f/10000}, NEUTRAL - #{(tone_array[2]* 10000).round.to_f/10000}"
      end_time = Time.now
      tone_time = end_time - beginning_time
      puts "************* tone time taken - #{tone_time}"
#      puts "*************"
      # #---------
      # quantity
      beginning_time = Time.now
      quant = TextQuantity.new
      quantity = quant.number_of_unique_tokens(review_text)
      end_time = Time.now
      quantity_time = end_time - beginning_time     
      puts "************* quantity time taken - #{quantity_time}"
      
      feature_values["plagiarism"] = plagiarism
      feature_values["relevance"] = relevance
      feature_values["content_summative"] = content_summative
      feature_values["content_problem"] = content_problem
      feature_values["content_advisory"] = content_advisory
      feature_values["coverage"] = coverage
      feature_values["tone_positive"] = tone_positive
      feature_values["tone_negative"] = tone_negative
      feature_values["tone_neutral"] = tone_neutral
      feature_values["quantity"] = quantity
      return feature_values
    end
  end #end of calculate_metareview_metrics method
end #end of class



