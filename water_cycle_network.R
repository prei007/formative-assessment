# Install and Load Required Packages
# If you haven't already, you'll need to install and load the `gRain` and `gRbase` packages.


library(gRain)
library(gRbase)

# Define States for Each Node
# Each node (concept) in our Bayesian Network will have three possible states: "not understood", "partially understood", and "well understood".

states <- c("not understood", "partially understood", "well understood")

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

# Querying the Network
# Set evidence: Let's assume Solar Energy is 'well understood'
bn <- setEvidence(bn, nodes = "SolarEnergy", states = "well understood")

# Query the conditional probability of Evaporation
querygrain(bn, nodes = "Evaporation")

# Visualize the Network
plot(bn)

# Save the Bayesian Network to a File
# Save the network in a format that can be read by the bnlearn package
saveRDS(bn, file = "water_cycle.rds")



