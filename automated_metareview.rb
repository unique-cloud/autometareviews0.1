require 'rubygems'
require 'wordnet'
require 'ffi/aspell'
require 'engtagger'
gem 'stanford-core-nlp', '=0.3.0'
require 'stanford-core-nlp'
gem 'rjb', "=1.4.3"
require 'rjb'
gem 'bind-it', "=0.2.0"
require 'bind-it'

require 'text_preprocessing'
require 'predict_class'
require 'degree_of_relevance'
require 'plagiarism_check'
require 'tone'
require 'text_quantity'
require 'constants'
require 'review_coverage'

class AutomatedMetareview
  #belongs_to :response, :class_name => 'Response', :foreign_key => 'response_id'
  #has_many :scores, :class_name => 'Score', :foreign_key => 'response_id', :dependent => :destroy
  attr_accessor :review_array
  #the code that drives the metareviewing
  def calculate_metareview_metrics(review, submission)
    
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
    puts "printing review_array"
    @review_array.each{
      |rev|
      puts rev
    }
    
    #checking for plagiarism by comparing with question and responses
    plag_instance = PlagiarismChecker.new
    #result_comparison = plag_instance.compare_reviews_with_questions_responses(self, map_id)
    # puts "review_array.length #{@review_array.length}"
    
#    if(result_comparison == ALL_RESPONSES_PLAGIARISED)
#      self.content_summative = 0
#      self.content_problem = 0 
#      self.content_advisory =  0
#      self.relevance = 0
#      self.quantity = 0
#      self.tone_positive = 0
#      self.tone_negative = 0
#      self.tone_neutral =  0
#      self.plagiarism = true
#      # puts "All responses are copied!!"
#      return
#    elsif(result_comparison == SOME_RESPONSES_PLAGIARISED)
#      self.plagiarism = true
#    end
    
    #checking plagiarism (by comparing responses with search results from google), we look for quoted text, exact copies i.e.
    google_plagiarised = plag_instance.google_search_response(self)
    if(google_plagiarised == true)
      self.plagiarism = true
    else
      self.plagiarism = false
    end
=begin    
    # puts "length of review array after google check - #{@review_array.length}"
    if(@review_array.length > 0)
      #formatting the review responses, segmenting them at punctuations
      review_text = preprocess.segment_text(0, @review_array)
      
      #removing quoted text from reviews
      review_text = preprocess.remove_text_within_quotes(review_text) #review_text is an array
      
      #fetching submission data as an array and segmenting them at punctuations    
      submissions = submission
      subm_text = preprocess.segment_text(0, submissions)
      # puts "subm_text #{subm_text}"
      # #initializing the pos tagger and nlp tagger/semantic parser  
      pos_tagger = EngTagger.new
      core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
      
      #---------    
      #relevance
      beginning_time = Time.now
      relev = DegreeOfRelevance.new
      self.relevance = relev.get_relevance(review_text, subm_text, 1, pos_tagger, core_NLP_tagger, speller) #1 indicates the number of reviews
      #assigninging the graph generated for the review to the class variable, in order to reuse it for content classification
      review_graph = relev.review
      #calculating end time
      end_time = Time.now
      relevance_time = end_time - beginning_time
      # puts "************* relevance_time - #{relevance_time}"      
      
      #---------    
      # checking for plagiarism
      if(self.plagiarism != true) #if plagiarism hasn't already been set
        beginning_time = Time.now
        result = plag_instance.check_for_plagiarism(review_text, subm_text)
        if(result == true)
          self.plagiarism = "TRUE"
        else
          self.plagiarism = "FALSE"
        end
        end_time = Time.now
        plagiarism_time = end_time - beginning_time
        # puts "************* plagiarism_time - #{plagiarism_time}"
      end

      #---------      
      #content
      beginning_time = Time.now
      content_instance = PredictClass.new
      pattern_files_array = ["app/models/automated_metareview/patterns-assess.csv",
        "app/models/automated_metareview/patterns-prob-detect.csv",
        "app/models/automated_metareview/patterns-suggest.csv"]
      #predcting class - last parameter is the number of classes
      content_probs = content_instance.predict_classes(pos_tagger, core_NLP_tagger, review_text, review_graph, pattern_files_array, pattern_files_array.length)
      #self.content = "SUMMATIVE - #{(content_probs[0] * 10000).round.to_f/10000}, PROBLEM - #{(content_probs[1] * 10000).round.to_f/10000}, SUGGESTION - #{(content_probs[2] * 10000).round.to_f/10000}"
      end_time = Time.now
      content_time = end_time - beginning_time
      self.content_summative = content_probs[0]# * 10000).round.to_f/10000
      self.content_problem = content_probs[1] #* 10000).round.to_f/10000
      self.content_advisory = content_probs[2] #* 10000).round.to_f/10000
      # puts "************* content_time - #{content_time}"

      #---------    
      #coverage
      cover = ReviewCoverage.new
      self.coverage = cover.calculate_coverage(subm_text, review_text, pos_tagger, core_NLP_tagger, speller)
      puts "************* coverage - #{self.coverage}"

      #---------    
      # tone
      beginning_time = Time.now
      ton = Tone.new
      tone_array = Array.new
      tone_array = ton.identify_tone(pos_tagger, core_NLP_tagger, review_text, review_graph)
      self.tone_positive = tone_array[0]#* 10000).round.to_f/10000
      self.tone_negative = tone_array[1]#* 10000).round.to_f/10000
      self.tone_neutral = tone_array[2]#* 10000).round.to_f/10000
      #self.tone = "POSITIVE - #{(tone_array[0]* 10000).round.to_f/10000}, NEGATIVE - #{(tone_array[1]* 10000).round.to_f/10000}, NEUTRAL - #{(tone_array[2]* 10000).round.to_f/10000}"
      end_time = Time.now
      tone_time = end_time - beginning_time
      # puts "************* tone_time - #{tone_time}"
      # #---------
      # quantity
      beginning_time = Time.now
      quant = TextQuantity.new
      self.quantity = quant.number_of_unique_tokens(review_text)
      end_time = Time.now
      quantity_time = end_time - beginning_time     
      
      feature_valuee["plagiarism"] = self.plagiarism
      feature_valuee["relevance"] = self.relevance
      feature_valuee["content_summative"] = self.content_summative
      feature_valuee["content_problem"] = self.content_problem
      feature_valuee["content_advisory"] = self.content_advisory
      feature_valuee["coverage"] = self.coverage
      feature_valuee["tone_positive"] = self.tone_positive
      feature_valuee["tone_negative"] = self.tone_negative
      feature_valuee["tone_neutral"] = self.tone_neutral
      feature_valuee["quantity"] = self.quantity
      return feature_valuee
    end
=end
  end #end of calculate_metareview_metrics method
end #end of class

#class driver
#run the code from here
preprocess = TextPreprocessing.new
review_array = preprocess.fetch_data("data/reviews.csv")
submission_array = preprocess.fetch_data("data/submission.csv")
#setting up the output file
#output_file = "/Users/lakshmi/Documents/Thesis/MSRParaphraseCorpus/Graph-based-representation/output-sample.csv"
#csvWriter = FasterCSV.open(output_file, "w")
#csvWriter << ["review_text", "subm_text", "relev.vert_match", "relev.edge_match", "relev.double_edge_match", "case1",
 #                   "case2", "case3", "case4", "case5", "case6"]
                    
for i in (0..review_array.length - 1)
  autometareview = AutomatedMetareview.new
  review = Array.new
  submission = Array.new
  review << review_array[i]
  submission << submission_array[i] 
  features = autometareview.calculate_metareview_metrics(review, submission)
  #write the features out to a file
end

