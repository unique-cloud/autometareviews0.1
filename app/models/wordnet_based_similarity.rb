require 'vertex'
require 'constants'
require 'rwordnet'
require 'engtagger'

class WordnetBasedSimilarity
  attr_accessor :match, :count
  @@posTagger = EngTagger.new  
  def compare_strings(review_vertex, subm_vertex, speller)
    # must fix this to something that is local to the app
    # WordNet::WordNetDB.path = "/usr/local/WordNet-3.0"
    # WordNet::WordNetDB.path = "/usr/local/Cellar/wordNet/3.0"
    review = review_vertex.name
    submission = subm_vertex.name
    review_state = review_vertex.state
    subm_state = subm_vertex.state

    @match = 0
    @count = 0
    
    review_pos = ''
    subm_pos = ''
     
    # check for exact matches between the tokens
    if review.casecmp(submission) == 0 # and !is_frequent_word(review_vertex.name) - removing this condition else, it returns a NOMATCH although the frequent words are equal and this negatively impacts the total match value
      # puts("Review vertex types #{review_vertex.type} && #{subm_vertex.type}")
      if review_state.equal?(subm_state)
        @match = @match + EXACT
      elsif !review_state.equal?(subm_state)
        @match = @match + NEGEXACT
      end
      return @match
    end   
    
    stok_rev = review.split(' ')
    #stok_sub = submission.split(" ") #should've been inside when doing n * n comparison
    
    #iterating through review tokens
    stok_rev.each do |rev_token|
      #if either of the tokens is null
      if rev_token.nil?
        next #continue with the next token
      end
      rev_token = rev_token.downcase
      if review_pos.empty? # do not reset POS for every new token, it changes the POS of the vertex e.g. like has diff POS for vertices "like"(n) and "would like"(v)
        review_pos = determine_pos(review_vertex).strip
      end
      
      # puts("*** RevToken:: #{rev_token} ::Review POS:: #{review_pos} class #{review_pos.class}")
      if rev_token.equal?("n't")
        rev_token = 'not'
        # puts("replacing n't")
      end
      
      #if the review token is a frequent word, continue
      if is_frequent_word(rev_token)
        # puts("Skipping frequent review token .. #{rev_token}")
        next #equivalent of the "continue"
      end
      
      # fetching synonyms, hypernyms, hyponyms etc. for the review token
      rev_stem = find_stem_word(rev_token, speller)
      # fetching all the relations
      review_relations = get_relations_for_review_submission_tokens(rev_token, rev_stem, review_pos)
      # setting the values in specific array variables
      rev_gloss = review_relations[0]
      rev_syn = review_relations[1]
      rev_hyper = review_relations[2]
      rev_hypo = review_relations[3]
      rev_ant = review_relations[4]
      
      # puts "reviewStem:: #{rev_stem} .. #{rev_stem.class}"
      # puts "reviewGloss:: #{rev_gloss} .. #{rev_gloss.class}"
      # puts "reviewSynonyms:: #{rev_syn} .. #{rev_syn.class}"
      # puts "reviewHypernyms:: #{rev_hyper} .. #{rev_hyper.class}"
      # puts "reviewHyponyms:: #{rev_hypo} .. #{rev_hypo.class}"
      # puts "reviewAntonyms:: #{rev_ant} .. #{rev_ant.class}"
        
      stok_sub = submission.split(' ')
      # iterate through submission tokens
      stok_sub.each do |sub_token|
      
        if sub_token.nil?
          next
        end
        
        sub_token = sub_token.downcase
        if subm_pos.empty? #do not reset POS for every new token, it changes the POS of the vertex e.g. like has diff POS for vertices "like"(n) and "would like"(v)
          subm_pos = determine_pos(subm_vertex).strip
        end
        
        # puts("*** SubToken:: #{sub_token} ::Review POS:: #{subm_pos}")
        if sub_token.equal?("n't")
          sub_token = 'not'
          # puts("replacing n't")
        end
        
        #if the review token is a frequent word, continue
        if is_frequent_word(sub_token)
          # puts("Skipping frequent subtoken .. #{sub_token}")
          next #equivalent of the "continue"
        end
                    
        # fetching synonyms, hypernyms, hyponyms etc. for the submission token
        subm_stem = find_stem_word(sub_token, speller)
        subm_relations = get_relations_for_review_submission_tokens(sub_token, subm_stem, subm_pos)
        subm_gloss = subm_relations[0]
        subm_syn =subm_relations[1]
        subm_hyper = subm_relations[2]
        subm_hypo = subm_relations[3]
        subm_ant = subm_relations[4]
        # puts "subm_stem:: #{subm_stem}"
        # puts "subm_gloss:: #{subm_gloss}"
        # puts "submSynonyms:: #{subm_syn}"
        # puts "submHypernyms:: #{subm_hyper}"
        # puts "submHyponyms:: #{subm_hypo}"
        # puts "submAntonyms:: #{subm_ant}"
          
        #------------------------------------------
        #checks are ordered from BEST to LEAST degree of semantic relatedness
        #*****exact matches 
        # puts "@match #{@match} review_state #{review_state} subm_state #{subm_state} review_pos #{review_pos} subm_pos #{subm_pos}"
        # puts "review_state.equal?(subm_state) #{review_state.equal?(subm_state)}"
        # puts "review_pos.equal?(subm_pos) #{review_pos == subm_pos}"
        if sub_token.casecmp(rev_token) == 0 or subm_stem.casecmp(rev_stem) == 0 #EXACT MATCH (submission.toLowerCase().equals(review.toLowerCase()))
          # puts("exact match for #{rev_token} & #{sub_token} or #{subm_stem} and #{rev_stem}")
          if review_state.equal?(subm_state)
            @match = @match + EXACT
          elsif !review_state.equal?(subm_state)
            @match = @match + NEGEXACT
          end
          @count+=1
          next #skip all remaining checks
        end #end of if condition checking for exact matches
        #------------------------------------------
        #*****For Synonyms
        #if the method returns 'true' it indicates a synonym match of some kind was found and the remaining checks can be skipped
        if check_match(rev_token, sub_token, rev_syn, subm_syn, rev_stem, subm_stem, review_state, subm_state, SYNONYM, ANTONYM)
          next
        end
        #------------------------------------------
        #ANTONYMS
        if check_match(rev_token, sub_token, rev_ant, subm_ant, rev_stem, subm_stem, review_state, subm_state, ANTONYM, SYNONYM)
          next
        end
        #------------------------------------------
        #*****For Hypernyms
        if check_match(rev_token, sub_token, rev_hyper, subm_hyper, rev_stem, subm_stem, review_state, subm_state, HYPERNYM, NEGHYPERNYM)
          next
        end
        #------------------------------------------   
        #*****For Hyponyms
        if check_match(rev_token, sub_token, rev_hypo, subm_hypo, rev_stem, subm_stem, review_state, subm_state, HYPONYM, NEGHYPONYM)
          next
        end
         
        #overlap across definitions   
        # checking if overlaps exist across review and submission tokens' defintions or if either defintiions contains the review
        # or submission token or stem.
        # puts "#{extract_definition(rev_gloss)[0]} .. extract_definition(rev_gloss)[0] #{extract_definition(rev_gloss)[0][0].class}"
        # puts "!rev_gloss #{!rev_gloss} .. rev_gloss.class #{rev_gloss.class}.. rev_gloss[0].include?(sub_token) #{rev_gloss[0].include?(sub_token)}"
        # rev_def = extract_definition(rev_gloss)
        # sub_def = extract_definition(subm_gloss)
        #(!rev_gloss.nil? and !subm_gloss.nil? and overlap(rev_gloss, subm_gloss, speller) > 0) or
        if((!rev_gloss.nil? and !rev_gloss[0].nil? and !sub_token.nil? and !subm_stem.nil? and (rev_gloss[0].include?(sub_token) or rev_gloss[0].include?(subm_stem))) or
          (!subm_gloss.nil? and !subm_gloss[0].nil? and !rev_token.nil? and !rev_stem.nil? and (subm_gloss[0].include?(rev_token) or subm_gloss[0].include?(rev_stem))))
          if review_state == subm_state
            @match = @match + OVERLAPDEFIN
          elsif review_state != subm_state
            @match = @match + NEGOVERLAPDEFIN
          end
          @count+=1
          next
        end
        
        #no match found!
        # puts "No Match found!"
        @match = @match + NOMATCH
        @count+=1
      end #end of the for loop for submission tokens 
    end #end of the for loop for review tokens
    
    if @count > 0
#      puts ("Match: #{@match} Count:: #{@count}")
      result = (@match.to_f/@count.to_f).round
#      puts("@@@@@@@@@ Returning Value: #{result}")
      result #an average of the matches found
    end
#    puts("@@@@@@@@@ Returning NOMATCH")
    NOMATCH
    
  end #end of compareStrings method
  
#------------------------------------------------------------------------------
=begin
 This method fetches the synonyms, hypernyms, hyponyms and other relations for the 'token' and its stem 'stem'.
 This is done for both review and submission tokens/stems.
 It returns a double dimensional array, where each element is an array of synonyms, hypernyms etc. 
=end

def get_relations_for_review_submission_tokens(token, stem, pos)
  # puts "@@@@ Inside get_relations_for_review_submission_tokens"
  relations = Array.new
  lemmas = WordNet::Lemma.find_all(token)

  #lemmas = WordNet::WordNetDB.find(token)
  if lemmas.nil?
    # lemmas=wordNet.lookup_synsets(stem)
    lemmas = WordNet::Lemma.find_all(stem)
  end

  # select the lemma corresponding to the token's POS
  lemma = ''
  lemmas.each do |l|
    # puts "lemma's POS :: #{l.pos} and POS :: #{pos}"
    if l.pos == pos
      lemma = l
      break
    end  
  end
      
  def_arr = Array.new
  syn_arr = Array.new
  hyper_arr = Array.new
  hypo_arr = Array.new
  anto_arr = Array.new
        
  #if selected reviewLemma is not nil or empty
  if !lemma.nil? and lemma != '' and !lemma.synsets.nil?
    #creating arrays of all the values for synonyms, hyponyms etc. for the review token
    (0..lemma.synsets.length - 1).each do |g|
      #fetching the first review synset
      lemma_synset = lemma.synsets[g]
      
      #definitions
      if !lemma_synset.gloss.nil?
        #puts "lemma_synset.gloss.class #{lemma_synset.gloss.class}"
        if def_arr[0].nil?
          def_arr << extract_definition(lemma_synset.gloss)
        else
          def_arr[0] = def_arr[0] + ' ' + extract_definition(lemma_synset.gloss)
        end
      else
        def_arr << nil
      end
      
      #looking for all relations synonym, hypernym, hyponym etc. from among this synset
      #synonyms
      begin #error handling for lemmas's without synsets that throw errors! (likely due to the dictionary file we are using)
        lemma_syns = lemma_synset.get_relation('&')
        if !lemma_syns.nil? and lemma_syns.length != 0
          # puts "lemmaSyns.length #{lemmaSyns.length}"
          #for each synset get the values and add them to the array
          (0..lemma_syns.length - 1).each do |h|
            # puts "lemmaSyns[h].words.class #{lemmaSyns[h].words.class}"
            syn_arr = syn_arr + lemma_syns[h].words
            # puts "**** syn_arr #{syn_arr}"
          end
        else
          syn_arr << nil #setting nil when no synset match is found for a particular type of relation
        end
      rescue
        syn_arr << nil
      end
      
      #hypernyms
      begin
        lemma_hypers = lemma_synset.get_relation('@')#hypernym.words
        if !lemma_hypers.nil? and lemma_hypers.length != 0
          #for each synset get the values and add them to the array
          (0..lemma_hypers.length - 1).each do |h|
            #puts "lemmaHypers[h].words.class #{lemmaHypers[h].words.class}"
            hyper_arr = hyper_arr + lemma_hypers[h].words
          end
        else
          hyper_arr << nil
        end
      rescue
        hyper_arr << nil
      end
      
      #hyponyms
      begin
        lemma_hypos = lemma_synset.get_relation('~')#hyponym
        if !lemma_hypos.nil? and lemma_hypos.length != 0
          #for each synset get the values and add them to the array
          (0..lemma_hypos.length - 1).each do |h|
            hypo_arr = hypo_arr + lemma_hypos[h].words
          end
        else
          hypo_arr << nil
        end
      rescue
        hypo_arr << nil
      end
      
      #antonyms
      begin
        lemma_ants = lemma_synset.get_relation('!')
        if !lemma_ants.nil? and lemma_ants.length != 0
          #for each synset get the values and add them to the array
          (0..lemma_ants.length - 1).each do |h|
            anto_arr = anto_arr + lemma_ants[h].words
          end
        else
          anto_arr << nil
        end
      rescue
        anto_arr << nil
      end         
    end #end of the for loop for g  
  end #end of checking if the lemma is nil or empty

  #setting the array elements before returning the array
  relations << def_arr
  relations << syn_arr
  relations << hyper_arr
  relations << hypo_arr
  relations << anto_arr
  relations
end

#------------------------------------------------------------------------------
=begin
 This method compares the submission and reviews' synonyms and antonyms with each others' tokens and stem values.
 The instance variables 'match' and 'count' are updated accordingly. 
=end
def check_match(rev_token, subm_token, rev_arr, subm_arr, rev_stem, subm_stem, rev_state, subm_state, match_type, non_match_type)
  flag = 0 #indicates if a match was found
  # puts("check_match between: #{rev_token} & #{subm_token} match_type #{match_type} and non_match_type #{non_match_type}")
  # puts "rev_arr #{rev_arr}"
  # puts "subm_arr #{subm_arr}"
  if (!rev_arr.nil? and (rev_arr.include?(subm_token) or rev_arr.include?(subm_stem))) or (!subm_arr.nil? and (subm_arr.include?(rev_token) or subm_arr.include?(rev_stem)))
    # puts("Match found between: #{rev_token} & #{subm_token}")
    flag = 1 #setting the flag to indicate that a match was found
    if rev_state == subm_state
      @match = @match + match_type
    elsif rev_state != subm_state
      @match = @match+ non_match_type
    end
    @count+=1
  end
  (flag == 1) ? true : false
end

#------------------------------------------------------------------------------

=begin
 determine_pos - method helps identify the POS tag (for the wordnet lexicon) for a certain word
=end
def determine_pos(vert)
  str_pos = vert.pos_tag
  # puts("Inside determine_pos POS Tag:: #{str_pos}")
  if %w(CD NN PR IN EX WP).any? { |str| str_pos.include?(str) }
    pos = 'n' # WordNet::Noun
  elsif str_pos.include?('JJ')
    pos = 'a' # WordNet::Adjective
  elsif %w(TO VB MD).any? { |str| str_pos.include?(str) }
    pos = 'v' # WordNet::Verb
  elsif str_pos.include?('RB')
    pos = 'r' # WordNet::Adverb
  else
    pos = 'n' # WordNet::Noun
  end
  pos
end

#------------------------------------------------------------------------------     
=begin
  is_frequent_word - method checks to see if the given word is a frequent word
=end
def is_frequent_word(word)
  word.delete!('(') #delete removes all occurrences of "(" 
  word.delete!(')') #if the character doesn't exist, the function returns nil, which does not affect the existing variable
  word.delete!('[')
  word.delete!(']')
  word.delete!('\"')

  if FREQUENT_WORDS.include?(word)
    return true
  end

  if CLOSED_CLASS_WORDS.include?(word)
    return true
  end  
  
  false
end
#------------------------------------------------------------------------------
=begin
  find_stem_word - stems the word and checks if the word is correctly spelt, else it will return a correctly spelled word as suggested by spellcheck
  It generated the nearest stem, since no context information is involved, the quality of the stems may not be great!
=end
def find_stem_word(word, speller)
  stem = word.stem
  correct = stem # initializing correct to the stem word
  # checking the stem word's spelling for correctness
  until speller.correct?(correct) do
    if speller.suggestions(correct).first
      correct = speller.suggestions(correct).first
    else
      #break out of the loop, else it will continue infinitely
      break #break out of the loop if the first correction was nil
    end
  end
  correct
end #end of is_frequent_word method

#------------------------------------------------------------------------------

=begin
 This method is used to extract definitions for the words (since glossed contain definitions and examples!)
 glosses - string containing the gloss of the synset 
=end
def extract_definition(glosses)
  definitions = ''#[]
  #extracting examples from definitions
  temp = glosses
  temp_list = temp.split(';')
  (0..temp_list.length - 1).each do |i|
    if !temp_list[i].include?('"')
      if definitions.empty?
        definitions = temp_list[i]
      else
        definitions = definitions +' '+ temp_list[i]
      end
    end
  end
  #puts definitions
  definitions
end
#------------------------------------------------------------------------------

def overlap(def1, def2, speller)
  instance = WordnetBasedSimilarity.new
  num_overlap = 0
  #only overlaps across the ALL definitions
  # puts "def1 #{def1}"
  # puts "def2 #{def2}"
  
  #iterating through def1's definitions
  (0..def1.length-1).each do |i|
    if def1[i]
      #puts "def1[#{i}] #{def1[i]}"
      if def1[i].include?("\"")
        def1[i].gsub!("\"", ' ')
      end
      if def1[i].include?(';')
        def1[i] = def1[i][0..def1[i].index(';')]
      end
      #iterating through def2's definitions
      (0..def2.length - 1).each do |j|
        if !def2[j].nil?
          if def2[j].include?(';')
            def2[j] = def2[j][0..def2[j].index(';')]
          end
          #puts "def2[#{j}] #{def2[j]}"
          s1 = def1[i].split(' ')
          s1.each do |tok1|
            tok1stem = find_stem_word(tok1, speller)
            s2 = def2[j].split(' ')
            s2.each do |tok2|
              tok2stem = find_stem_word(tok2, speller)
              # puts "tok1 #{tok1} and tok2 #{tok2}"
              # puts "tok1stem #{tok1stem} and tok2stem #{tok2stem}"
              if (tok1.downcase == tok2.downcase or tok1stem.downcase == tok2stem.downcase) and !instance.is_frequent_word(tok1) and !instance.is_frequent_word(tok1stem)
                # puts("**Overlap def/ex:: #{tok1} or #{tok1stem}")
                num_overlap += 1
              end
            end #end of s2 loop
          end #end of s1 loop
        end #end of def2[j][0] being null
      end #end of for loop for def2 - j
    end #end of if def1[i][0] being null
  end #end of for loop for def1 - i
  num_overlap
end
#------------------------------------------------------------------------------
end #end of WordnetBasedSimilarity class
