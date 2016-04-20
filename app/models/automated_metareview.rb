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
  attr_accessor :review_array

  #quantity metric generator
  def calculate_metareview_metric_quantity(review)
    preprocess = TextPreprocessing.new

    #formatting the review responses, segmenting them at punctuations
    review_text = preprocess.segment_text(0, review)
    #removing quoted text from reviews
    review_text = preprocess.remove_text_within_quotes(review_text) #review_text is an array
    quant = TextQuantity.new
    quantity = quant.number_of_unique_tokens(review_text)

    feature_values=Hash.new
    feature_values["volume"]=quantity
    return feature_values
  end
  #tone metric generator
  def calculate_metareview_metric_tone(review)
    feature_values = Hash.new

    pos_tagger = EngTagger.new
    core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    speller = FFI::Aspell::Speller.new('en_US')

    preprocess = TextPreprocessing.new
    # speller.suggestion_mode = Aspell::NORMAL
    review = preprocess.check_correct_spellings(review, speller)
    tone = Tone.new
    #formatting the review responses, segmenting them at punctuations
    review = preprocess.segment_text(0, review)
    #removing quoted text from reviews
    review = preprocess.remove_text_within_quotes(review) #review_text is an array


    degree_relevance = DegreeOfRelevance.new
    tone_array = Array.new
    tone_array = tone.identify_tone_no_review_graph(pos_tagger, speller, core_NLP_tagger, review)
    feature_values["tone_positive"] = tone_array[0]#* 10000).round.to_f/10000
    feature_values["tone_negative"] = tone_array[1]#* 10000).round.to_f/10000
    feature_values["tone_neutral"] = tone_array[2]#* 10000).round.to_f/10000
    return feature_values
  end
  #content metric generator
  def calculate_metareview_metric_content(review)
    preprocess = TextPreprocessing.new
    pos_tagger = EngTagger.new
    core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    g = GraphGenerator.new

    feature_values=Hash.new
    speller = FFI::Aspell::Speller.new('en_US')
    @review_array = review
    if(@review_array.length > 0)
      #formatting the review responses, segmenting them at punctuations
      review_text = preprocess.segment_text(0, @review_array)
      #removing quoted text from reviews
      review_text = preprocess.remove_text_within_quotes(review_text) #review_text is an array

      #generating review's graph
      g.generate_graph(review_text, pos_tagger, core_NLP_tagger, true, false)
      review_graph = g.clone
      
      content_instance = PredictClass.new
      pattern_files_array = ["app/data/patterns-assess.csv","app/data/patterns-prob-detect.csv","app/data/patterns-suggest.csv"]
      #predcting class - last parameter is the number of classes
      content_probs = content_instance.predict_classes(pos_tagger, core_NLP_tagger, review_text, review_graph, pattern_files_array, pattern_files_array.length)
      content = "SUMMATIVE - #{(content_probs[0] * 10000).round.to_f/10000}, PROBLEM - #{(content_probs[1] * 10000).round.to_f/10000}, SUGGESTION - #{(content_probs[2] * 10000).round.to_f/10000}"
      content_summative = content_probs[0]# * 10000).round.to_f/10000
      content_problem = content_probs[1] #* 10000).round.to_f/10000
      content_advisory = content_probs[2] #* 10000).round.to_f/10000
      feature_values["content_summative"] = content_summative
      feature_values["content_problem"] = content_problem
      feature_values["content_advisory"] = content_advisory
    end
    return feature_values
  end
  #plagiarism metric generator
  def calculate_metareview_metric_plagiarism(review, submission,rubricqns_array)

    feature_values=Hash.new
    @review_array = review
    if(@review_array.length>0)
      plag_instance = PlagiarismChecker.new
      result_comparison = plag_instance.compare_reviews_with_questions_responses(@review_array, rubricqns_array)
      if(result_comparison == ALL_RESPONSES_PLAGIARISED || result_comparison=SOME_RESPONSES_PLAGIARISED)
        plagiarism = true
      end

      google_plagiarised = plag_instance.google_search_response(self)
      if(google_plagiarised == true)
        plagiarism = true
      else
        plagiarism = false
      end
      feature_values["plagiarism"]=plagiarism
    end
    return feature_values
  end
  #coverage metric generator
  def calculate_metareview_metric_coverage(review, submission)
    preprocess = TextPreprocessing.new
    feature_values=Hash.new
    @review_array = review
    if(@review_array.length > 0)
      #formatting the review responses, segmenting them at punctuations
      review_text = preprocess.segment_text(0, @review_array)
      #removing quoted text from reviews
      review_text = preprocess.remove_text_within_quotes(review_text) #review_text is an array

      speller = FFI::Aspell::Speller.new('en_US')
      submissions = submission
      subm_text = preprocess.check_correct_spellings(submissions, speller)
      subm_text = preprocess.segment_text(0, subm_text)
      subm_text = preprocess.remove_text_within_quotes(subm_text)


      pos_tagger = EngTagger.new
      core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
      cover = ReviewCoverage.new
      coverage = cover.calculate_coverage(subm_text, review_text, pos_tagger, core_NLP_tagger, speller)
      feature_values["coverage"]=coverage
    end
    return feature_values
  end
  #relevance metric generator
  def calculate_metareview_metric_relevance(review, submission)
    preprocess = TextPreprocessing.new
    feature_values=Hash.new
    @review_array = review
    speller = FFI::Aspell::Speller.new('en_US')
    if(@review_array.length>0)
      @review_array = preprocess.check_correct_spellings(@review_array, speller)
      #formatting the review responses, segmenting them at punctuations
      review_text = preprocess.segment_text(0, @review_array)
      #removing quoted text from reviews
      review_text = preprocess.remove_text_within_quotes(review_text) #review_text is an array
      submissions = submission
      subm_text = preprocess.check_correct_spellings(submissions, speller)
      subm_text = preprocess.segment_text(0, subm_text)
      subm_text = preprocess.remove_text_within_quotes(subm_text)

      pos_tagger = EngTagger.new
      core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
      relev = DegreeOfRelevance.new
      relevance = relev.get_relevance(review_text, subm_text, 1, pos_tagger, core_NLP_tagger, speller) #1 indicates the number of reviews
      feature_values["relevance"]=relevance
    end
    return feature_values
  end


  #the code that drives the metareviewing
  def calculate_metareview_metrics(review, submission, rubricqns_array)
    preprocess = TextPreprocessing.new
    feature_values = Hash.new #contains the values for each of the metareview features calculated
    preprocess = TextPreprocessing.new

    #fetch the review data as an array 
    @review_array = review 
    
    # puts "self.responses #{self.responses}"
    speller = FFI::Aspell::Speller.new('en_US')
    # speller.suggestion_mode = Aspell::NORMAL
    @review_array = preprocess.check_correct_spellings(@review_array, speller)

    #checking for plagiarism by comparing with question and responses
    plag_instance = PlagiarismChecker.new
    result_comparison = plag_instance.compare_reviews_with_questions_responses(@review_array, rubricqns_array)

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
      feature_values["plagiarism"] = plagiarism
      feature_values["relevance"] = relevance
      feature_values["content_summative"] = content_summative
      feature_values["content_problem"] = content_problem
      feature_values["content_advisory"] = content_advisory
      feature_values["coverage"] = coverage
      feature_values["tone_positive"] = tone_positive
      feature_values["tone_negative"] = tone_negative
      feature_values["tone_neutral"] = tone_neutral
      feature_values["volume"] = quantity
      #Even if a review is plagiarised, we are still required to find other metrics for experiment.
      #return feature_values
    elsif(result_comparison == SOME_RESPONSES_PLAGIARISED)
      plagiarism = true
    end

    #checking plagiarism (by comparing responses with search results from google), we look for quoted text, exact copies i.e.

    #enable this check later-to_do
    #
    #google_plagiarised = plag_instance.google_search_response(self)

    #if(google_plagiarised == true)
    #  plagiarism = true
    #else
    #  plagiarism = false
    #end

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
      pattern_files_array = ["app/data/patterns-assess.csv","app/data/patterns-prob-detect.csv","app/data/patterns-suggest.csv"]
      #predcting class - last parameter is the number of classes
      content_probs = content_instance.predict_classes(pos_tagger, core_NLP_tagger, review_text, review_graph, pattern_files_array, pattern_files_array.length)
      content = "SUMMATIVE - #{(content_probs[0] * 10000).round.to_f/10000}, PROBLEM - #{(content_probs[1] * 10000).round.to_f/10000}, SUGGESTION - #{(content_probs[2] * 10000).round.to_f/10000}"
      end_time = Time.now
      content_time = end_time - beginning_time
      content_summative = content_probs[0]# * 10000).round.to_f/10000
      content_problem = content_probs[1] #* 10000).round.to_f/10000
      content_advisory = content_probs[2] #* 10000).round.to_f/10000
      feature_values["content_summative"] = content_summative
      feature_values["content_problem"] = content_problem
      feature_values["content_advisory"] = content_advisory
      return feature_values
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
      feature_values["volume"] = quantity
      return feature_values
    end
  end #end of calculate_metareview_metrics method
end #end of class



