# formative-assessment
Demonstrator of formative assessment using AI and Bayesian Networks

## Main idea

1. Student provides a long answer/short essay to a teacher question. 
2. The answer gets scored by chatGPT along with a verbal feedback aligned with the score. 
3. The score gets used to update a Learner Model, formally a Bayesian Network. 
4. The score, the comment, and the Learner Model go to the teacher.

## Early demonstrator

### The learner model

Using the water cycle domain for illustration, a simple model involving just five concepts looks like so:

<img src="media/water_cycle_dag.png" alt="Sample Image" width="400"/>

### Teacher UI

<img src="media/shiny-ui-1.png" alt="Sample Image" width="600"/>
