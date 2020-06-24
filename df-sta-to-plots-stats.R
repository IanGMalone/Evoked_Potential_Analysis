# 
# Created on April 12, 2020
#
# by Ian G. Malone
# https://github.com/IanGMalone
# 
# The purpose of this script is to load a csv file containing stimulus-triggered
# average data and output relevant visualizations and statistics.
# 
#


#!!! June 23, 2020 - df_STA will not be rectified now (change this script to rectify for AUC)



#### ---- importing libraries and defining functions ---- ####


#### import libraries
library(ggplot2)
library(ggthemes)
library(data.table)
library(pracma) # trapz function


#### define functions
percent_change <- function(old_val, new_val) {
  #' Return percent change between new and old value
  ((new_val-old_val)/old_val)*100
}



#### ---- data wrangling and analysis ---- ####


#### load STA data as dataframe
df <- data.frame(read.csv('C:/Users/iangm/Desktop/df_STA_2020_06_14_clean.csv'))
df[,'Animal'] = toupper(df[,'Animal'])
dt_STA <- data.table(df)


#### make data table for day 1, 2, 3, 4
#### remove stim artifact (samples 0:50) <---- maybe remove less than 50 (50 samples = 2.5ms)
#### only keep left side EMG in data table
dt_STA <- subset(dt_STA, Day %in% c(1, 2, 3, 4) & Sample %in% c(50:300) & Side %in% c('Left'))


#### calculate AUC, dropping the Sample and STA_Amplitude columns
dt_STA <- dt_STA[, 
                               .(
                                 AUC = trapz(Sample, STA_Amplitude)
                               ),
                               by = .(Animal, Day, Side, Stim_Amplitude)]


#### break Day column into columns for day 1 AUC and day 4 AUC
dt_STA <- dcast(dt_STA, Animal + Side + Stim_Amplitude ~ Day, value.var = "AUC")


#### rename columns
names(dt_STA)[names(dt_STA) == "1"] = "Day1_AUC"
names(dt_STA)[names(dt_STA) == "2"] = "Day2_AUC"
names(dt_STA)[names(dt_STA) == "3"] = "Day3_AUC"
names(dt_STA)[names(dt_STA) == "4"] = "Day4_AUC"


#### calculate percent change from day 1 for each day, make new columns
dt_STA[, Day1_PercentChange := percent_change(Day1_AUC, Day1_AUC)]
dt_STA[, Day2_PercentChange := percent_change(Day1_AUC, Day2_AUC)]
dt_STA[, Day3_PercentChange := percent_change(Day1_AUC, Day3_AUC)]
dt_STA[, Day4_PercentChange := percent_change(Day1_AUC, Day4_AUC)]


#### define animal groups
injstim <- c("N09", "N10", "N11", "N13")
injnostim <- c("N14", "N15", "N16", "N21", "N22", "N23")
noinjstim <- c("N01", "N04", "N05")
noinjnostim <- c("N17", "N19", "N20", "N24", "N25", "N26")
# injcdrstim <- c("CD01", "CD02")
# injtrkbstim <- c("T01")
# injnoemgnostim <- c("EZ01", "EZ02")
# noinjnoemgnostim <- c("EZ03", "EZ04")


#### add animal group column
dt_STA[Animal %in% injstim, Group := "Injury + Stimulation, n=4"]
dt_STA[Animal %in% injnostim, Group := "Injury + No Stimulation, n=6"]
dt_STA[Animal %in% noinjstim, Group := "No Injury + Stimulation, n=3"]
dt_STA[Animal %in% noinjnostim, Group := "No Injury + No Stimulation, n=6"]
# dt_STA[Animal %in% injcdrstim, Group := "Injury + CDR + Stimulation"]
# dt_STA[Animal %in% injtrkbstim, Group := "Injury + siTrkB + Stimulation"]
# dt_STA[Animal %in% injnoemgnostim, Group := "Injury + No EMG + No Stimulation"]
# dt_STA[Animal %in% noinjnoemgnostim, Group := "No Injury + No EMG + No Stimulation"]


#--------------------------------- make new dt, dt_STA_long with columns Day, AUC, Percent_Change


#### melt
dt_STA_testt = melt(dt_STA, id = c("Animal", "Side", "Stim_Amplitude", "Group"))
dt_STA_testt[, c("Day", "Measure") := tstrsplit(variable, "_", fixed = TRUE)]
dt_STA_testt[,variable:=NULL]
dt_STA_testt <- dcast(dt_STA_testt, Animal + Side + Stim_Amplitude + Group + Day ~ Measure, value.var = "value")
setnames(dt_STA_testt, "PercentChange", "Percent_Change")
setcolorder(dt_STA_testt, c("Animal", "Side", "Stim_Amplitude", "Day", "AUC", "Percent_Change", "Group"))


#### save dt to a .csv
#write.csv(dt_STA, 'C:\\Users\\iangm\\desktop\\dt_STA.csv')



#### ---- plotting ---- ####

#### in progress plots
#WHERE IS N11 ?????????
dots <- ggplot(subset(dt_STA_d1d4_pchange, Animal %in% c('N09', 'N10', 'N11', 'N13')), aes(x=Stim_Amplitude, y=Percent_Change_AUC, color=Animal)) +
  geom_point(alpha=0.7)
dots


animals = c('N26')
ggplot(subset(dt_STA_d1d4, Animal %in% animals & Day %in% c(1,4) & Stim_Amplitude %in% c(100, 400)),
                  aes(x=Sample, y=STA_Amplitude, color=factor(Stim_Amplitude))) +
  geom_point(alpha=0.4) +
  facet_wrap(~Day)


plot_data_column = function (data, column) {
  ggplot(data, aes_string(x = column)) +
    geom_histogram(fill = "lightgreen") +
    xlab(column)
}

myplots <- lapply(colnames(data2), plot_data_column, data = data2)


  


#### final plots
gpcd14 <- ggplot(dt_STA_d1d4_pchange, aes(x=Stim_Amplitude, y=Percent_Change_AUC, color=Group)) +
  geom_smooth(span=0.25) +
  geom_point(alpha=0.4) +
  labs(x="Stimulation Amplitude (µA)", 
       y="Percent Change AUC \n Day 1 to Day 4") +
  xlim(100,500) +
  theme_classic() +
  theme(text = element_text(size=20))
gpcd14


Day.labs <- c("Day 1", "Day 2", "Day 3", "Day 4")
names(Day.labs) <- c("1", "2", "3", "4")
AUC_d1234 <- ggplot(dt_STA_d1234_AUC, aes(x=Stim_Amplitude, y=Normalized_AUC, color=Group)) +
  geom_point(alpha=0.8) +
  facet_grid(rows = vars(Day), labeller = labeller(Day = Day.labs)) +
  labs(x="Stimulation Amplitude (µA)", 
       y="Normalized AUC") +
  xlim(0,600) +
  theme_classic() +
  theme(text = element_text(size=20))
AUC_d1234





#### to do?
# multiplier for recordings (different gains for different days??)




