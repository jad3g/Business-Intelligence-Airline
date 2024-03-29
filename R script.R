library(dplyr)
library(readxl)
library(ggplot2)
library(broom)
library(skimr)
library(mice) #package for imputation for our missing values
library(gridExtra)

########################## DATA PREPARATION ####################################
#To set working directory
setwd("C:/Users/DEBBIE/Music/RSTUDIO/Business inteligence/group/New folder")
sats <- read_excel("airline_27.xlsx")

skim(sats)


#Renaming some values in Business, Connection, and Departure
sats <- sats %>% mutate(business = ifelse(business == "business" | business == "Business","business","leisure"))

#mutating the variable kids to a dummy variable
sats <- sats %>% mutate(kids = ifelse(kids > 0,1,0))

#Renaming/ Recoding some values in Connection and Departure
sats <- sats %>% mutate(connection = ifelse(connection == "connecting flight" | connection == "connection","connectingflight","notconnectingflight"))

sats <- sats %>% mutate(departure = ifelse(departure == "weather disruption","cancelled", departure))

sats <- sats %>% mutate(departure = ifelse(departure == "delay < 30min" | departure == "delay < 90min" | departure == "delay > 90min","delayed", departure))


#To remove all missing values and outliers in satisfaction
sats <- sats %>% mutate(satisfaction = na_if(satisfaction, -999)) 

#To rename the data to sats1
sats1 <- sats


##to create a Proportion graph of satisfaction
# Calculate proportion of observations in each category of satisfaction
prop_satisfaction <- prop.table(table(sats1$satisfaction))

# Create bar plot
barplot(prop_satisfaction, main="Figure 1: Proportion of Satisfaction", xlab="Satisfaction", ylab="Proportion", ylim=c(0,1))


############################ DESCRIPTIVE STATISTICS##################
summary(sats1)
skim(sats1)

table(sats1$kids)
table(sats1$business)
table(sats1$route)
table(sats1$day,sats1$satisfaction)
table(sats1$type)
table(sats1$departure,sats1$satisfaction)
table(sats1$gender)
table(sats1$kids)
table(sats1$gender)
table(sats1$connection)
table(sats1$satisfaction)


#################################### IMPUTATION ###############################
#### imputation : to Imputate the data to account for missing Values 

# Set the seed for reproducibility
set.seed(123)

# Define the variables to be imputed
vars_to_impute <- c("satisfaction", "route")

# Set the number of imputations to perform
num_imputations <- 5

# Create a copy of the original dataset
imputed_data <- sats1


# Impute the missing values using the mice package
imputed_data_mice <- mice(imputed_data, 
                          method = "norm", 
                          m = num_imputations, 
                          maxit = 5, 
                          seed = 123)

# Get the completed datasets
imputed_data_list <- complete(imputed_data_mice, "long", include = TRUE)

# Combine the imputed datasets into a single dataset
imputed_data_final <- do.call(rbind, imputed_data_list)

# Check the distribution of the imputed values for each variable
densityplot(imputed_data_mice)

# Impute missing values
imputed_data_final <- mice::complete(imputed_data_mice)

# Assign original column names
colnames(imputed_data_final) <- colnames(sats1)

# Compare the imputed data to the original data
par(mfrow=c(1,2))

plot(sats1$satisfaction, with(imputed_data_final, satisfaction), 
     xlab = "Original", ylab = "Imputed", main = "satisfaction")
abline(0, 1)

plot(sats1$route, with(imputed_data_final, route), xlab = "Original", ylab = "Imputed", main = "Route")
abline(0, 1)

# Round up values in satisfaction to integers

sats1 <- imputed_data_final

sats1$satisfaction <- ceiling(sats1$satisfaction)

# Limit values of satisfaction from 1 - 10

sats1$satisfaction <- pmax(pmin(sats1$satisfaction, 10), 1)

########################################## PREPARATION FOR REGRESSION #############################

sats1$route <- as.factor(sats1$route)
sats1$day <- as.factor(sats1$day)
sats1$type <- as.factor(sats1$type)
sats1$departure <- as.factor(sats1$departure)
sats1$gender <- as.factor(sats1$gender)
sats1$kids <- as.numeric(sats1$kids)
sats1$business <- as.factor(sats1$business)
sats1$connection <- as.factor(sats1$connection)
sats1$satisfaction <- as.integer(sats1$satisfaction)

#To select variables to be used for analysis
sats1 <- sats1 %>% select(business, kids, departure, connection, type, satisfaction)


                    ##############################  REGRESSION #############
# Regression 1
reg1 <- lm(formula = satisfaction ~ departure, data = sats1)
summary(reg1)

## Regression 2 
reg2 <- lm(formula = satisfaction ~ departure + business, data = sats1)
summary(reg2)

### REGRESSION 3

reg3 <- lm(formula = satisfaction ~ departure + business + type, data = sats1)
summary(reg3)

### REGRESSION 4
reg4 <- lm(formula = satisfaction ~ departure + business + type + connection, data = sats1)
summary(reg4)

### REGRESSION 5
reg5 <- lm(formula = satisfaction ~ departure + business + type +  connection + kids, data = sats1)
summary(reg5)

                          ######## VISUALISATION #########
### FIGURE 2 shows the Relationship between Departure and Satisfaction
Figure2 <- ggplot(sats1, aes(x = departure, y = satisfaction, fill = departure)) + geom_bar(stat = "identity") + labs(x = "Departure", y = "Satisfaction", title = "Figure 2: Relationship between Departure and Satisfaction") + scale_fill_manual(values=c("brown","steelblue","violet")) + theme_classic()

#FIGURE 3
#Create a summary table with the counts and percentages by departure and business
sats_summary <- sats1 %>%
  group_by(departure, business) %>%
  summarize(count = n()) %>%
  mutate(percentage = count / sum(count) * 100)

##### FIGURE 3  shows the Relationship between Satisfaction, Departure and Business
Figure3 <- ggplot(sats_summary, aes(x = departure, y = count, fill = business)) +
  geom_col(position = "dodge") + geom_text(aes(label = paste0(count, " (", round(percentage), "%)")), 
            position = position_dodge(width = 1), vjust = -0.5) + labs(title = "Figure 3: Relationship between Satisfaction, Departure and Business", x = "Departure Time", y = "Count") + scale_fill_manual(values=c("brown","steelblue","violet")) + theme_classic()



# FIGURE 4 shows the Relationship between Satisfaction, business and Type
Figure4 <- ggplot(sats1, aes(x = business, y = satisfaction, fill = type)) + geom_bar(stat = "identity") + stat_smooth(method = "lm", se = FALSE) + labs(title = "Figure 4: Relationship between Satisfaction, business and Type", x = "Business", y = "Satisfaction") + scale_fill_manual(values=c("brown","steelblue","violet")) + theme_classic()


### FIGURE 5 shows the Relationship between Satisfaction, Business and Connection
Figure5 <- ggplot(sats1, aes(x = business, y = satisfaction, fill = connection)) + geom_bar(stat = "identity") + stat_smooth(method = "lm", se = FALSE) + labs(title = "Figure 5: Relationship between Satisfaction, Business and Connection", x = "Business", y = "Satisfaction") + scale_fill_manual(values=c("brown","steelblue","violet")) + theme_classic()

### FIGURE 6 shows the Relationship between Satisfaction, Business and KIDS
Figure6 <- ggplot(sats1, aes(x = business, y = satisfaction, fill = factor(kids))) + geom_bar(stat = "identity") + stat_smooth(method = "lm", se = FALSE) + labs(title = "Figure 6: Relationship between Satisfaction, Business and KIDS", x = "Business", y = "Satisfaction") + scale_fill_manual(values=c("brown","steelblue")) + theme_classic()


grid.arrange(Figure2,Figure3,Figure4,Figure5,Figure6)

