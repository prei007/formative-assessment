# Load bnlearn package
library(bnlearn)

# Define the network structure
dag <- model2network("[SolarEnergy][AtmosphericCirculation][Evaporation|SolarEnergy][Condensation|Evaporation:AtmosphericCirculation][Precipitation|Condensation]")

# Define CPTs (Conditional Probability Tables)
cpt_solar_energy <- matrix(c(0.3, 0.4, 0.3), ncol = 3, dimnames = list(NULL, c("not understood", "partially understood", "well understood")))

cpt_atmospheric_circulation <- matrix(c(0.2, 0.5, 0.3), ncol = 3, dimnames = list(NULL, c("not understood", "partially understood", "well understood")))

cpt_evaporation <- array(c(0.6, 0.3, 0.1,
                           0.2, 0.5, 0.3,
                           0.1, 0.4, 0.5),
                         dim = c(3, 3),
                         dimnames = list(SolarEnergy = c("not understood", "partially understood", "well understood"),
                                         Evaporation = c("not understood", "partially understood", "well understood")))

cpt_condensation <- array(c(0.5, 0.3, 0.2,
                            0.3, 0.4, 0.3,
                            0.1, 0.4, 0.5,
                            0.3, 0.4, 0.3,
                            0.2, 0.5, 0.3,
                            0.1, 0.3, 0.6,
                            0.2, 0.5, 0.3,
                            0.3, 0.3, 0.4,
                            0.1, 0.3, 0.6),
                          dim = c(3, 3, 3),
                          dimnames = list(Evaporation = c("not understood", "partially understood", "well understood"),
                                          AtmosphericCirculation = c("not understood", "partially understood", "well understood"),
                                          Condensation = c("not understood", "partially understood", "well understood")))

cpt_precipitation <- array(c(0.2, 0.5, 0.3,
                             0.1, 0.4, 0.5,
                             0.1, 0.3, 0.6),
                           dim = c(3, 3),
                           dimnames = list(Condensation = c("not understood", "partially understood", "well understood"),
                                           Precipitation = c("not understood", "partially understood", "well understood")))

# Fit the Bayesian network with custom CPTs
fitted_bn <- custom.fit(dag, dist = list(SolarEnergy = cpt_solar_energy,
                                         AtmosphericCirculation = cpt_atmospheric_circulation,
                                         Evaporation = cpt_evaporation,
                                         Condensation = cpt_condensation,
                                         Precipitation = cpt_precipitation))

# Querying the Network
# Set evidence: Let's assume Solar Energy is 'well understood'
evidence <- list(SolarEnergy = "well understood")
result <- cpquery(fitted_bn, event = (Evaporation == "partially understood"), evidence = evidence)
print(result)

# Visualize the Network
graphviz.plot(fitted_bn)

# Save the Bayesian Network
saveRDS(fitted_bn, file = "water_cycle_bnlearn.rds")
