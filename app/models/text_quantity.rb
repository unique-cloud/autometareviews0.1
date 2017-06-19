require 'wordnet_based_similarity'
require 'text_preprocessing'

class TextQuantity
  def number_of_unique_tokens(text_array)
    # preString helps keep track of the text that has been checked for unique
    # tokens and text that has not
    pre_string = ""
    # counts the number of unique tokens
    count = 0
    instance = WordnetBasedSimilarity.new
    text_array.each{
      |text|
      tp = TextPreprocessing.new
      text = tp.contains_punct(text)
      all_tokens = text.split(" ")
      all_tokens.each{ 
        |token|
        # do not count this word if it is a frequent word
        if (!instance.is_frequent_word(token.downcase))
          # if the token was not already seen earlier i.e. not a part of the preString
          if (!pre_string.downcase.include?(token.downcase))
            count += 1
          end  
        end
        # adding token to the preString
        pre_string = pre_string + " " + token.downcase
      }
    }
    return count
  end
end