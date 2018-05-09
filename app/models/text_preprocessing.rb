require 'constants'
require 'edge'
require 'vertex'
require 'csv'

class TextPreprocessor

  # Fetching review data from the tables based on the response_map id
  def fetch_data(filename)
    data_array = Array.new
    CSV.foreach(filename) do |row|
      data_array << row[0]
    end
    return data_array
  end

  # pre-process the review text and send it in for graph formation and further analysis
  def segment_text(review)
    # ******* Pre-processing the review/submission text **********
    # replace commas in large numbers, makes parsing sentences with commas confusing!
    # replace quotation marks
    review = remove_urls(review)
    review.delete!("\"()")

    # break the text into multiple sentences
    segmented_review = review.split(/[.?!,;]/).map(&:strip)
    segmented_review
  end

  # Reads the patterns from the csv file containing them.
  # maxValue is the maximum value of the patterns found
  def read_patterns(filename, pos)
    patterns = []
    state = POSITIVE

    # setting the state for problem detection and suggestive patterns
    if filename.include?("prob")
      state = NEGATED
    elsif filename.include?("suggest")
      state = SUGGESTIVE
    end

    CSV.foreach(filename) do |text|
      str_a = text[0].split("=")
      in_str = str_a[0].strip
      out_str = str_a[1].strip

      # get the first token in vertex to determine POS
      first_str_in_vtx = pos.get_readable(in_str.split(" ")[0])
      # get the first token in vertex to determine POS
      first_str_out_vtx = pos.get_readable(out_str.split(" ")[0])

      in_tag = first_str_in_vtx.split("/")[1]
      out_tag = first_str_out_vtx.split("/")[1]

      edge = Edge.new("noun", NOUN)
      edge.in_vertex = generate_vtx(in_str, state, in_tag)
      edge.out_vertex = generate_vtx(out_str, state, out_tag)

      patterns << edge
    end

    patterns
  end

  def generate_vtx (str, state, tag)
    type = case tag
             when 'NN' 'PRP' 'IN' 'EX' 'WP'
               NOUN
             when 'VB'  'MD'
               VERB
             when 'JJ'
               ADJ
             when 'RB'
               ADV
             else # default to noun
               NOUN
           end

    Vertex.new(str, type, state, nil, nil, tag)
  end

  # Remove any urls in the text and returns the remaining text as it is
  def remove_urls(text)
    text.gsub!(/#{URI::regexp}/, '')
    text
  end

  # Check for plagiarism after removing text within quotes for reviews
  def remove_text_within_quotes(review)
      # the read text is tagged with two sets of quotes!
      review.gsub!(/"([^"]*)"/, "")
      review
  end

  # Looks for spelling mistakes in the text and fixes them using the raspell library available for ruby
  def check_correct_spellings(review_text_array)
    speller = FFI::Aspell::Speller.new('en_US')
    # speller.suggestion_mode = Aspell::NORMAL

    review_text_array_temp = []

    # iterate through each response
    review_text_array.each do |review_text|
      review_tokens = review_text.split(" ")
      review_text_temp = ""

      # iterate through tokens from each response
      review_tokens.each do |review_tok|
        # check the stem word's spelling for correctness
        unless speller.correct?(review_tok)
          review_tok = speller.suggestions(review_tok).first unless speller.suggestions(review_tok).first
        end

        review_text_temp += " "
        review_text_temp += review_tok.downcase
      end

      review_text_array_temp << review_text_temp
    end

    return review_text_array_temp
  end

  # Checking if "str" is a punctuation mark like ".", ",", "?" etc.
  # The method was throwing a "NoMethodError: private method" error when called
  # from a different class. Hence the "public" keyword.
  public

  def remove_punctuation(str)
    str.delete!(".,?!;:()[]")
    return str
  end

  def contains_punctuation?(str)
    %W(\\n { }).any? {|p| str.include?(p)}
  end
  
  # Checking if "str" is a punctuation mark like ".", ",", "?" etc.
  def is_punctuation?(str)
    %w(. , ? ! ; :).include?(str)
  end

end
