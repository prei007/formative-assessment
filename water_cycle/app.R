# Install and Load Required Packages
# If you haven't already, you'll need to install and load the `gRain`, `gRbase`, `Rgraphviz`, `shiny`, and `openai` packages.

library(gRain)
library(gRbase)
# library(Rgraphviz)
library(shiny)
library(openai)
# library(igraph)
library(visNetwork)

##########################
# Network creation
##########################

# Define States for Each Node
# Each node (concept) in our Bayesian Network will have three possible states: "not understood", "partially understood", and "well understood".

states <- c("not_understood", "partially_understood", "well_understood")

# Defining the Root Nodes (Solar Energy and Atmospheric Circulation)
# Root nodes are independent of other nodes, so we define them with unconditional probability tables.

cpt_solar_energy <- cptable(~SolarEnergy, values = c(0.3, 0.4, 0.3), levels = states)
cpt_atmospheric_circulation <- cptable(~AtmosphericCirculation, values = c(0.2, 0.5, 0.3), levels = states)

# Defining Intermediate Nodes
# Intermediate nodes have dependencies. Here, Evaporation depends on Solar Energy.

cpt_evaporation <- cptable(~Evaporation | SolarEnergy, values = c(0.6, 0.3, 0.1, 0.2, 0.5, 0.3, 0.1, 0.4, 0.5), levels = states)

# Condensation depends on Evaporation and Atmospheric Circulation
cpt_condensation <- cptable(~Condensation | Evaporation:AtmosphericCirculation,
                            values = c(0.5, 0.3, 0.2,
                                       0.3, 0.4, 0.3,
                                       0.1, 0.4, 0.5,
                                       0.3, 0.4, 0.3,
                                       0.2, 0.5, 0.3,
                                       0.1, 0.3, 0.6,
                                       0.2, 0.5, 0.3,
                                       0.3, 0.3, 0.4,
                                       0.1, 0.3, 0.6),
                            levels = states)

# Precipitation depends on Condensation
cpt_precipitation <- cptable(~Precipitation | Condensation, values = c(0.2, 0.5, 0.3, 0.1, 0.4, 0.5, 0.1, 0.3, 0.6), levels = states)

# Convert CPTs into Probability Tables
plist <- compileCPT(list(cpt_solar_energy, cpt_atmospheric_circulation, cpt_evaporation, cpt_condensation, cpt_precipitation))

# Compile the Bayesian Network
bn <- grain(plist)

# show values in console
print("priors:")
print(querygrain(bn, nodes = c("SolarEnergy", "Evaporation")))


##########################
# Shiny
##########################

# strings for testing  the app

teacher_question1 <-"Explain the role of solar energy for the water cycle in about 100 words."
student_answer1 <- "Solar energy is super important for the water cycle because it heats up the water in oceans, lakes, and rivers, making it evaporate into the air. This forms water vapor, which rises and cools down to create clouds. Without the sun, there wouldn’t be enough energy to make the water move around. I think the sun also helps with condensation because it warms the clouds, but I’m not entirely sure. Also, solar energy might make the wind blow, which pushes clouds around. So, the sun kind of powers everything in the water cycle, from evaporation to moving water around in the air."
student_answer2 <- "Solar energy is the driving force of the water cycle. It provides the heat necessary for evaporation, where water from oceans, lakes, and other surfaces turns into water vapor. This vapor rises into the atmosphere, cools, and condenses into clouds, a process independent of direct solar heating. Solar energy also causes differential heating of the Earth’s surface, creating winds that help transport moisture. Once the clouds become saturated, precipitation occurs, returning water to the surface. In summary, solar energy powers evaporation, drives atmospheric circulation, and sustains the continuous movement of water through the cycle."

# Shiny App to Collect Teacher Question and Student Answer
ui <- fluidPage(
  titlePanel("Student Answer Evaluation"),
  sidebarLayout(
    sidebarPanel(
      textInput("teacher_question", "Teacher Question:", teacher_question1),
      textAreaInput("student_answer", "Student's Answer:", student_answer1, rows = 5),
      actionButton("evaluate", "Evaluate Answer")
    ),
    mainPanel(
      h4("Feedback:"),
      verbatimTextOutput("feedback"),
      h4("Score:"),
      verbatimTextOutput("score"),
      plotOutput("dag_graph")
    )
  )
)

server <- function(input, output) {
  observeEvent(input$evaluate, {
    # Using OpenAI API to evaluate the student's answer
    question <- input$teacher_question
    answer <- input$student_answer

    # Make a request to OpenAI API for evaluation
    openai_api_key <- Sys.getenv("OPENAI_API_KEY")

    msgText <- paste("Teacher Question:", question, "\nStudent Answer:", answer, "\nEvaluate the correctness of the student's answer. Provide a qualitative score as one of: not_understood, partially_understood, or fully_understood. Provide short text feedback aligned with the score.")


    response <- openai::create_chat_completion(
      model = "gpt-3.5-turbo",
      messages = list(list(role = "user", content = msgText))
    )

    # Extract feedback and score from response

    feedback_text <- as.character(response$choices[[5]])
    score <- ifelse(
      grepl("not_understood", feedback_text, ignore.case = TRUE),
      "not_understood",
      ifelse(
        grepl("partially_understood", feedback_text, ignore.case = TRUE),
        "partially_understood",
        "well_understood"
      )
    )

    # Mapping questions to nodes
    question_node_mapping <- list(
      "solar energy" = "SolarEnergy",
      "atmospheric circulation" = "AtmosphericCirculation",
      "evaporation" = "Evaporation",
      "condensation" = "Condensation",
      "precipitation" = "Precipitation"
      # Add more mappings as needed
    )

    # Determine which node to update
    matching_node <- NULL
    for (keyword in names(question_node_mapping)) {
      if (grepl(keyword, question, ignore.case = TRUE)) {
        matching_node <- question_node_mapping[[keyword]]
        break
      }
    }

    # Update Bayesian Network with the score
    if (!is.null(matching_node)) {
      bn <<- setEvidence(bn, nodes = matching_node, states = score)
    }

    # show values in console
    print("updated values:")
    print(querygrain(bn, nodes = c("SolarEnergy", "Evaporation")))

    # Display the feedback and score
    output$feedback <- renderText({ feedback_text })
    output$score <- renderText({ score })

    #Display the bn
    output$dag_graph <- renderPlot( { plot(bn$dag) } )
    })


}


# Run the Shiny App
shinyApp(ui = ui, server = server)
