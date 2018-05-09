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

class Metareview
  attr_accessor :review_array

  # quantity metric generator
  def calculate_volume(*p)
    review = p[0]
    preprocess = TextPreprocessor.new

    # formatting the review responses, segmenting them at punctuations
    review_text = preprocess.segment_text(0, review)
    # removing quoted text from reviews
    review_text = preprocess.remove_text_within_quotes(review_text) # review_text is an array

    quantity = TextQuantity.new
    volume = quantity.number_of_unique_tokens(review_text)

    feature_values = {}
    feature_values["volume"] = volume
    feature_values
  end

  # tone metric generator
  def calculate_tone(*p)
    review = p[0]

    feature_values = {}
    pos_tagger = EngTagger.new
    core_NLP_tagger = StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    speller = FFI::Aspell::Speller.new('en_US')

    preprocess = TextPreprocessor.new
    review = preprocess.check_correct_spellings(review)

    tone = Tone.new
    # formatting the review responses, segmenting them at punctuations
    review = preprocess.segment_text(0, review)
    # removing quoted text from reviews
    review = preprocess.remove_text_within_quotes(review) # review is an array

    tone_array = tone.identify_tone_no_review_graph(pos_tagger, speller, core_NLP_tagger, review)
    feature_values["tone_positive"] = tone_array[0]#* 10000).round.to_f/10000
    feature_values["tone_negative"] = tone_array[1]#* 10000).round.to_f/10000
    feature_values["tone_neutral"] = tone_array[2]#* 10000).round.to_f/10000

    feature_values
  end

  # content metric generator
  def calculate_content(*p)
    review = p[0]
    feature_values = {}

    unless review.blank?
      # preprocess = TextPreprocessor.new
      core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
      graph = WordOrderGraph.new

      # formatting the review responses, segmenting them at punctuations
      # preprocess.segment_text(review)
      # removing quoted text from reviews
      # preprocess.remove_text_within_quotes(review)
      graph.generate_graph(review, core_NLP_tagger)

      content_instance = PredictClass.new
      pattern_files_array = ["app/data/patterns-assess.csv", "app/data/patterns-prob-detect.csv", "app/data/patterns-suggest.csv"]

      # predict class - last parameter is the number of classes
      pos_tagger = EngTagger.new
      content_probs = content_instance.predict_classes(pos_tagger, core_NLP_tagger, graph, pattern_files_array)
      content_summative = content_probs[0] # * 10000).round.to_f/10000
      content_problem = content_probs[1] #* 10000).round.to_f/10000
      content_advisory = content_probs[2] #* 10000).round.to_f/10000
      feature_values["content_summative"] = content_summative
      feature_values["content_problem"] = content_problem
      feature_values["content_advisory"] = content_advisory
    end

    feature_values
  end

  # plagiarism metric generator
  def calculate_plagiarism(*p)
    reviews = p[0]
    rubrics = p[2]

    feature_values = {}

    unless reviews.empty?
      checker = PlagiarismChecker.new
      result = checker.compare_reviews_with_questions_responses(reviews, rubrics)

      plagiarism = (result == ALL_RESPONSES_PLAGIARISED || result == SOME_RESPONSES_PLAGIARISED)

      feature_values["plagiarism"] = plagiarism
    end

    feature_values
  end

  # coverage metric generator
  def calculate_coverage(*p)
    review = p[0]
    submission = p[1]

    preprocess = TextPreprocessor.new
    feature_values = Hash.new
    @review_array = review

    if @review_array.length > 0
      # formatting the review responses, segmenting them at punctuations
      review_text = preprocess.segment_text(0, @review_array)
      # removing quoted text from reviews
      review_text = preprocess.remove_text_within_quotes(review_text)   # review_text is an array

      speller = FFI::Aspell::Speller.new('en_US')
      submissions = submission
      subm_text = preprocess.check_correct_spellings(submissions)
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

  # relevance metric generator
  def calculate_relevance(*p)
    review = p[0]
    submission = p[1]

    preprocess = TextPreprocessor.new
    feature_values = Hash.new
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

  # the code that drives the metareviewing
  def calculate_metareview_metrics(*p)
    reviews = p[0]
    submission = p[1]
    rubricqns_array = p[2]

    feature_values = {}   # contains the values for each of the metareview features calculated
    @review_array = reviews

    preprocessor = TextPreprocessor.new
    @review_array = preprocessor.check_correct_spellings(@review_array)

    # checking for plagiarism by comparing with question and responses
    p_checker = PlagiarismChecker.new
    result = p_checker.compare_reviews_with_questions_responses(@review_array, rubricqns_array)

    if result == ALL_RESPONSES_PLAGIARISED
      # puts "All responses are copied!!"
      feature_values["plagiarism"] = true
      feature_values["relevance"] = 0
      feature_values["content_summative"] = 0
      feature_values["content_problem"] = 0
      feature_values["content_advisory"] = 0
      feature_values["coverage"] = 0
      feature_values["tone_positive"] = 0
      feature_values["tone_negative"] = 0
      feature_values["tone_neutral"] = 0
      feature_values["volume"] = 0

      # Even if a review is plagiarised, we are still required to find other metrics for experiment.
      # return feature_values
    elsif result == SOME_RESPONSES_PLAGIARISED
      plagiarism = true
    end

    return feature_values if @review_array.empty?

    # format the review responses, segment them at punctuations
    review_text = preprocessor.segment_text(0, @review_array)
    # removing quoted text from reviews
    review_text = preprocessor.remove_text_within_quotes(review_text) # review_text is an array

    # fetch submission data as an array and segment them at punctuations
    submissions = submission
    subm_text = preprocessor.check_correct_spellings(submissions, speller)
    subm_text = preprocessor.segment_text(0, subm_text)
    subm_text = preprocessor.remove_text_within_quotes(subm_text)

    # initializing the pos tagger and nlp tagger/semantic parser
    pos_tagger = EngTagger.new
    core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)

    # ---------
    # relevance
    beginning_time = Time.now
    relev = DegreeOfRelevance.new
    relevance = relev.get_relevance(review_text, subm_text, 1, pos_tagger, core_NLP_tagger, speller) # 1 indicates the number of reviews
    # assign the graph generated for the review to the class variable, in order to reuse it for content classification
    review_graph = relev.review
    # calculating end time
    end_time = Time.now
    relevance_time = end_time - beginning_time
    # ---------
    # checking for plagiarism
    unless plagiarism # if plagiarism hasn't already been set
      beginning_time = Time.now
      result = plag_instance.check_for_plagiarism(review_text, subm_text)
      if (result == true)
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
#     puts "*************"
    #---------
    #coverage
    cover = ReviewCoverage.new
    coverage = cover.calculate_coverage(subm_text, review_text, pos_tagger, core_NLP_tagger, speller)
#     puts "************* coverage - #{coverage}"
#     puts "*************"
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
#     puts "*************"
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

    feature_values
  end
end
