autometareviews0.1
==================
Automated metareview tool
=========================

About the tool:
---------------
The automated metareview tool identifies the quality of a review using natural language processing and machine learning techniques (completely automated). Feedback is provided to reviewers on the following metrics:
1. Review relevance: This metric tells the reviewer how relevant the review is to the content of the author's submission. Numeric feeback in the scale of 0--1 is provided to indicate a review's relevance.
2. Review Content Type: This metric identifies whether the review contains 'summative content' -- positive feedback, 'problem detection content' -- problems identified by reviewers in the author's work or 'advisory content' -- content indicating suggestions or advice provided by reviewers. A numeric feedback on the scale of 0--1 is provided for each content type to indicate whether the review contains that type of content.
3. Review Coverage: This metric indicates the extent to which a review covers the main points of a submission. Numeric value in the range of 0--1 indicates the coverage of a review.
4. Plagiarism: Indicates the presence of plagiarism in the review text.
5. Tone: The metric indicates whether a review has a positive, negative or neutral tone.
6. Quantity: Indicates the nummber of unique words used by the reviewer in the review.

Notes:
------
* automated_metareivew.rb is the driver file.
* The tool takes in (1) a file with reviews (one review per line) (e.g. reviews.csv), (2) a file with submissions (one submission per line) (e.g. submission.csv). Every submission should correspond to the review on the same line in the reviews file. For instance submission on line 1 should be the submission for which review on line 1 was written. (3) a rubric file, containing the questions used to evoke the reviews (e.g. rubric.csv).
* These files are placed in the data/ folder.
* Run ruby on automated_metareview.rb
* The output gets saved in data/output-sample.csv (You can change the name or location of the file by updating automated_metareivew.rb). Each line of the output file contains metric values for each revew (with its corresponding submission).

