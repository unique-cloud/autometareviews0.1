require 'negations'
require 'constants'

# noinspection ALL
class SentenceState
  attr_accessor :broken_sentences

  def break_at_coordinating_conjunctions(tagged_tokens)
    @broken_sentences = []
    sentence = ''

    tagged_tokens.each do |token|
      if !token.include?('/CC')
        sentence += ' '
        sentence += token
      else
        @broken_sentences << sentence
        sentence = token
      end
    end

    @broken_sentences << sentence
  end

  def identify_sentence_state(tagged_tokens)
    # break the sentence at the co-ordinating conjunction
    break_at_coordinating_conjunctions(tagged_tokens)
    
    states_array = []
    # identify states for each of the sentence segments
    @broken_sentences.each do |sentence|
      states_array << sentence_state(sentence)
    end

    states_array
  end

  # Check if the token is a negative token
  def sentence_state(sentence)
    interim_noun_verb  = false # 0 indicates no interim nouns or verbs
    prev_negative_word = ''
    state = POSITIVE

    # iterate through the tokens to determine state
    tokens = sentence.split(' ')
    tokens.each_with_index do |tagged_token, i|
      token = tagged_token.split('/').first

      # check type of the word
      type = if is_negative_word?(token)
               NEGATIVE_WORD               # if negative word
             elsif is_negative_descriptor?(token)
               NEGATIVE_DESCRIPTOR         # if negative descriptor (indirect indicators of negation)
             elsif i+1 < tokens.length && is_negative_phrase?(token + ' ' + tokens[i+1])
               NEGATIVE_PHRASE             # 2-gram phrases of negative phrases
             elsif is_suggestive_word?(token)
               SUGGESTIVE                  # if suggestion word
             elsif i+1 < tokens.length && is_suggestive_phrase?(token + ' ' + tokens[i+1])
               SUGGESTIVE                  # 2-gram phrases suggestion phrases
             else
               POSITIVE                    # else set to positive
             end
      
      #----------------------------------------------------------------------
      # compare 'type' with the existing STATE of the sentence clause
      # after type is identified, check its state and compare it to the existing state
      # if present state is negative and an interim non-negative or non-suggestive word was found, set the flag to true
      if type == POSITIVE && [NEGATIVE_WORD, NEGATIVE_DESCRIPTOR, NEGATIVE_PHRASE].include?(state)
        if %w(NN PR VB MD).any? { |str| tagged_token.include?(str) }
          interim_noun_verb = true
        end
      end 

      case state
        when POSITIVE
          state = type

        when NEGATIVE_WORD
          case type
            when NEGATIVE_WORD
              # these words embellish the negation, so only if the previous word was not one of them you make it positive
              if %w(NO NEVER NONE).any? { |word| prev_negative_word.casecmp(word) != 0 }
                state = POSITIVE  # e.g: "not had no work..", "doesn't have no work..", "its not that it doesn't bother me..."
              else
                state = NEGATIVE_WORD   # e.g: "no it doesn't help", "no there is no use for ..."
              end
              interim_noun_verb = false   # reset

            when NEGATIVE_DESCRIPTOR, NEGATIVE_PHRASE
              state = POSITIVE    # e.g.: "not bad", "not taken from", "I don't want nothing", "no code duplication"// ["It couldn't be more confusing.."- anomaly we dont handle this for now!]
              interim_noun_verb = false   # reset

            when SUGGESTIVE
              # e.g. "it is not too useful as people could...", what about this one?
              if interim_noun_verb   # there are some words in between
                state = NEGATIVE_WORD
              else
                state = SUGGESTIVE # e.g.:"I do not(-) suggest(S) ..."
              end
              interim_noun_verb = false # reset
          end

        when NEGATIVE_DESCRIPTOR
          case type
            when NEGATIVE_WORD
              if interim_noun_verb  # there are some words in between
                state = NEGATIVE_WORD   # e.g: "hard(-) to understand none(-) of the comments"
              else
                state = POSITIVE  # e.g."He hardly not...."
              end
              interim_noun_verb = false # reset

            when NEGATIVE_DESCRIPTOR
              if interim_noun_verb  # there are some words in between
                state = NEGATIVE_DESCRIPTOR # e.g:"there is barely any code duplication"
              else
                state = POSITIVE # e.g."It is hardly confusing..", but what about "it is a little confusing.."
              end
              interim_noun_verb = false # reset

            when NEGATIVE_PHRASE
              if interim_noun_verb  # there are some words in between
                state = NEGATIVE_PHRASE # e.g:"there is barely any code duplication"
              else
                state = POSITIVE # e.g.:"it is hard and appears to be taken from"
              end
              interim_noun_verb = false # reset

            when SUGGESTIVE
              state = SUGGESTIVE # e.g.:"I hardly(-) suggested(S) ..."
              interim_noun_verb = false # reset
          end

        # when state is a negative phrase
        when NEGATIVE_PHRASE
          case type
            when NEGATIVE_WORD
              if interim_noun_verb == true # there are some words in between
                state = NEGATIVE_WORD # e.g."It is too short the text and doesn't"
              else
                state = POSITIVE # e.g."It is too short not to contain.."
              end
              interim_noun_verb = false # reset

            when NEGATIVE_DESCRIPTOR
              state = NEGATIVE_DESCRIPTOR # e.g."It is too short barely covering..."
              interim_noun_verb = false # reset

            when NEGATIVE_PHRASE
              state = NEGATIVE_PHRASE # e.g.:"it is too short, taken from ..."
              interim_noun_verb = false # resetting

            when SUGGESTIVE
              state = SUGGESTIVE # e.g.:"I too short and I suggest ..."
              interim_noun_verb = false # resetting
          end

        # when state is suggestive
        when SUGGESTIVE # e.g.:"I might(S) not(-) suggest(S) ..."
          case type
            when NEGATIVE_DESCRIPTOR
              state = NEGATIVE_DESCRIPTOR

            when NEGATIVE_PHRASE
              state = NEGATIVE_PHRASE
          end
          # e.g.:"I suggest you don't.." -> suggestive
          interim_noun_verb = false # reset
        end

      # set the prevNegativeWord
      if %w(NO NEVER NONE).any? { |word| token.casecmp(word) == 0 }
        prev_negative_word = token
      end
    end
    
    if [NEGATIVE_DESCRIPTOR, NEGATIVE_WORD, NEGATIVE_PHRASE].include?(state)
      state = NEGATED
    end
    
    state
  end

  def is_in?(array, word)
    downcase_set = Set.new(array.map(&:downcase))
    downcase_set.include?(word.downcase)
  end

  def is_negative_word?(word)
    is_in?(NEGATED_WORDS, word)
  end

  def is_negative_descriptor?(word)
    is_in?(NEGATIVE_DESCRIPTORS, word)
  end

  def is_negative_phrase?(phrase)
    is_in?(NEGATIVE_PHRASES, phrase)
  end

  def is_suggestive_word?(word)
    is_in?(SUGGESTIVE_WORDS, word)
  end

  def is_suggestive_phrase?(phrase)
    is_in?(SUGGESTIVE_PHRASES, phrase)
  end
end

