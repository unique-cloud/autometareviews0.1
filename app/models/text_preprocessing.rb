require 'constants'
require 'edge'
require 'vertex'
require 'csv'

class TextPreprocessing

  # Fetching review data from the tables based on the response_map id
  def fetch_data(filename)
    data_array = Array.new
    CSV.foreach(filename) do |row|
      data_array << row[0]
    end
    return data_array
  end

  # pre-processes the review text and sends it in for graph formation
  # and further analysis
  def segment_text(train_or_test_reviews, text_array)
    if (train_or_test_reviews == 0)
      reviews = Array.new(1){Array.new}
    else
      # 50 is the number of different reviews/submissions
      reviews = Array.new(50){Array.new}
    end

    i = 0
    j = 0

    for k in (0..text_array.length-1)
      text = text_array[k]
      # reset i (the sentence counter) to 0 for test reviews
      if (train_or_test_reviews == 1)
        # initializing the array for sentences in a test review
        reviews[j] = Array.new
        i = 0
      end

      # ******* Pre-processing the review/submission text **********
      # replacing commas in large numbers, makes parsing sentences with commas confusing!
      # replacing quotation marks
      # replacing gsub with delete(as stated by RUBOCOP)
      text.delete!("\"")
      text.delete!("(")
      text.delete!(")")
      if (text.include?("http://"))
        text = remove_urls(text)
      end
      # break the text into multiple sentences
      beginn = 0
      # replaced multiple logical ors with any
      # new clause or sentence
      if ([".","?","!",",",";"].any? { |ch| (text).include?(ch)})
        # the text contains more than 1 sentence
        while ([".","?","!",",",";"].any? { |ch| (text).include?(ch)}) do
          endd = 0
          # these 'if' conditions have to be independent, cause the value of
          # 'endd' could change for the different types of punctuations
          if (text.include?("."))
            endd = text.index(".")
          end
          # removed duplicate code by exytracting a method find_occurance
          # if a ? occurs before a .
          if (find_occurance(text,"?"))
            endd = text.index("?");
          end
          # if an ! occurs before a . or a ?
          if (find_occurance(text,"!"))
            endd = text.index("!");
          end
          # if an , occurs before a . or a ? or !
          if (find_occurance(text,","))
            endd = text.index(",")
          end
          # if an ; occurs before a . or a ? or ! or ,
          if (find_occurance(text,";"))
            endd = text.index(";")
          end

          # check if the string between two commas or punctuations is there to buy time e.g. ", say," ",however," ", for instance, "...
          if (train_or_test_reviews == 0) # training
            reviews[0][i] = text[beginn..endd].strip
          else # testing
            reviews[j][i] = text[beginn..endd].strip
          end
          i += 1 # incrementing the sentence counter
          text = text[(endd+1)..text.length] # from end+1 to the end of the string variable
        end
      else
        if (train_or_test_reviews == 0) # training
          reviews[0][i] = text.strip
          i += 1
        else
          reviews[j][i] = text.strip
        end
      end

      if (train_or_test_reviews == 1) # incrementing reviews counter only for test reviews
        j += 1
      end
    end

    if (flag == 0)
      return reviews[0]
    end
  end

  # Extract method: function to replace multiple ifs. to remove code duplication
  def find_occurance(text, char)
    if ((text.include?(char) and endd != 0 and endd > text.index(char)) or (text.include?(char) and endd == 0))
      true
    end
    false
  end

  # Reads the patterns from the csv file containing them.
  # maxValue is the maximum value of the patterns found
  def read_patterns(filename, pos)
    num = 1000 # some large number
    patterns = Array.new
    state = POSITIVE
    i = 0 # keeps track of the number of edges

    # setting the state for problem detection and suggestive patterns
    if (filename.include?("prob"))
      state = NEGATED
    elsif (filename.include?("suggest"))
      state = SUGGESTIVE
    end

    CSV.foreach(filename) do |text|
      in_vertex = text[0][0..text[0].index("=")-1].strip
      out_vertex = text[0][text[0].index("=")+2..text[0].length].strip

      # getting the first token in vertex to determine POS
      first_string_in_vertex = pos.get_readable(in_vertex.split(" ")[0])
      # getting the first token in vertex to determine POS
      first_string_out_vertex = pos.get_readable(out_vertex.split(" ")[0])

      patterns[i] = Edge.new("noun", NOUN)
      # setting the invertex
      if (first_string_in_vertex.include?("/NN") or first_string_in_vertex.include?("/PRP") or first_string_in_vertex.include?("/IN") or first_string_in_vertex.include?("/EX") or first_string_in_vertex.include?("/WP"))
        patterns[i].in_vertex = Vertex.new(in_vertex, NOUN, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
      elsif (first_string_in_vertex.include?("/VB") or first_string_in_vertex.include?("MD"))
        patterns[i].in_vertex = Vertex.new(in_vertex, VERB, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
      elsif (first_string_in_vertex.include?("JJ"))
        patterns[i].in_vertex = Vertex.new(in_vertex, ADJ, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
      elsif (first_string_in_vertex.include?("/RB"))
        patterns[i].in_vertex = Vertex.new(in_vertex, ADV, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
      else # default to noun
        patterns[i].in_vertex = Vertex.new(in_vertex, NOUN, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
      end

      # setting outvertex
      if(first_string_out_vertex.include?("/NN") or first_string_out_vertex.include?("/PRP") or first_string_out_vertex.include?("/IN") or first_string_out_vertex.include?("/EX") or first_string_out_vertex.include?("/WP"))
        patterns[i].out_vertex = Vertex.new(out_vertex, NOUN, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])
      elsif(first_string_out_vertex.include?("/VB") or first_string_out_vertex.include?("MD"))
        patterns[i].out_vertex = Vertex.new(out_vertex, VERB, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])
      elsif(first_string_out_vertex.include?("JJ"))
        patterns[i].out_vertex = Vertex.new(out_vertex, ADJ, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length-1]);
      elsif(first_string_out_vertex.include?("/RB"))
        patterns[i].out_vertex = Vertex.new(out_vertex, ADV, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])
      else # default is noun
        patterns[i].out_vertex = Vertex.new(out_vertex, NOUN, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])
      end
      i += 1
    end
    num_patterns = i
    return patterns
  end

  # Removes any urls in the text and returns the remaining text as it is
  def remove_urls(text)
    final_text = String.new
    if (text.include?("http://"))
      tokens = text.split(" ")
      tokens.each{
          |token|
        if (!token.include?("http://"))
          final_text = final_text + " " + token
        end
      }
    else
      return text
    end
    return final_text
  end

  # Check for plagiarism after removing text within quotes for reviews
  def remove_text_within_quotes(review_text)
    # puts "Inside removeTextWithinQuotes:: "
    reviews = Array.new
    review_text.each{ |row|
      text = row
      # the read text is tagged with two sets of quotes!
      if (text.include?("\""))
        while (text.include?("\"")) do
          replace_text = text.scan(/"([^"]*)"/)
          # fetching the start index of the quoted text, in order to replace the complete segment
          # -1 in order to start from the quote
          start_index = text.index(replace_text[0].to_s) - 1
          text.gsub!(text[start_index..start_index + replace_text[0].to_s.length+1], "")
        end
      end
      reviews << text # set the text after all quoted segments have been removed.
    }
    return reviews # return only the first array element - a string!
  end

  # Looks for spelling mistakes in the text and fixes them using the raspell library available for ruby
  def check_correct_spellings(review_text_array, speller)
    review_text_array_temp = Array.new
    # iterating through each response
    review_text_array.each{
        |review_text|
      review_tokens = review_text.split(" ")
      review_text_temp = ""
      # iterating through tokens from each response
      review_tokens.each{
          |review_tok|
        # checkiing the stem word's spelling for correctness
        if (!speller.correct?(review_tok))
          if (!speller.suggestions(review_tok).first.nil?)
            review_tok = speller.suggestions(review_tok).first
          end
        end
        review_text_temp = review_text_temp +" " + review_tok.downcase
      }
      review_text_array_temp << review_text_temp
    }
    return review_text_array_temp
  end

  # Checking if "str" is a punctuation mark like ".", ",", "?" etc.
  # The method was throwing a "NoMethodError: private method" error when called
  # from a different class. Hence the "public" keyword.
  public
  def contains_punct(str)
    str.delete!(".,?!;:()[]")
    return str
  end

  def contains_punct_bool(str)
    if (str.include?("\\n") or str.include?("}") or str.include?("{"))
      return true
    else
      return false
    end
  end

  # Checking if "str" is a punctuation mark like ".", ",", "?" etc.
  def is_punct(str)
    if (str == "." or str == "," or str == "?" or str == "!" or str == ";" or str == ":")
      return true
    else
      return false
    end
  end

end
