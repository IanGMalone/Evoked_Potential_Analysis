# 
# Created on April 12, 2020
# by Ian G. Malone
# 
# The purpose of this script is to load a csv file containing stimulus-triggered
# average data and output relevant visualizations and statistics.
# 
# This is a work in progress.
#




#### import libraries
library(ggplot2)
library(ggthemes)
library(data.table)
library(DescTools)
library(pracma) # trapz function



#### define functions
percent_change <- function(old_val, new_val) {
  #' Return percent change between new and old value
  ((new_val-old_val)/old_val)*100
}



#### load STA data as dataframe
df_STA <- data.frame(read.csv('C:/Users/iangm/Desktop/df_STA_2020_06_14_clean.csv'))
df_STA[,'Animal'] = toupper(df_STA[,'Animal'])
dt_STA <- data.table(df_STA)
# dt_STA <- dt_STA[,X:=NULL] # might not need <- here



#### define animal groups
injstim <- c("N09", "N10", "N11", "N13")
injnostim <- c("N08", "N12", "N14", "N15", "N16", "N21", "N22", "N23")
noinjstim <- c("N01", "N04", "N05")
noinjnostim <- c("N06", "N07", "N17", "N19", "N20", "N24", "N25", "N26")
injcdrstim <- c("CD01", "CD02")
injtrkbstim <- c("T01")
injnoemgnostim <- c("EZ01", "EZ02")
noinjnoemgnostim <- c("EZ03", "EZ04")



#### data table for day 1 and 4... subset only day 1 and day 4
#### remove stim artifact (samples 0:50), only left side
dt_STA_d1d4 <- subset(dt_STA, Day %in% c(1, 4) & Sample %in% c(50:300) & Side %in% c('Left'))
dt_STA_d1234 <- subset(dt_STA, Day %in% c(1, 2, 3, 4) & Sample %in% c(50:300) & Side %in% c('Left'))


#### calculate AUC, dropping the Sample and STA_Amplitude columns
dt_STA_d1d4_AUC <- dt_STA_d1d4[, 
                         .(
                           AUC = trapz(Sample, STA_Amplitude)
                         ),
                         by = .(Animal, Day, Side, Stim_Amplitude)]
dt_STA_d1234_AUC <- dt_STA_d1234[, 
                               .(
                                 AUC = trapz(Sample, STA_Amplitude)
                               ),
                               by = .(Animal, Day, Side, Stim_Amplitude)]



#### calculate % change, dropping the Day and AUC columns
#### break Day column into columns for day 1 AUC and day 4 AUC
dt_STA_d1d4_pchange <- dcast(dt_STA_d1d4_AUC, Animal + Side + Stim_Amplitude ~ Day, value.var = "AUC")
dt_STA_d1234_AUC <- dcast(dt_STA_d1234_AUC, Animal + Side + Stim_Amplitude ~ Day, value.var = "AUC")


#### rename columns
names(dt_STA_d1d4_pchange)[names(dt_STA_d1d4_pchange) == "1"] = "Day1_AUC"
names(dt_STA_d1d4_pchange)[names(dt_STA_d1d4_pchange) == "4"] = "Day4_AUC"


#### remove rows that have NA values 
dt_STA_d1d4_pchange <- na.omit(dt_STA_d1d4_pchange, cols=c("Day1_AUC", "Day4_AUC"))
dt_STA_d1234_AUC <- na.omit(dt_STA_d1234_AUC, cols=c("Day1_AUC", "Day2_AUC", "Day3_AUC", "Day4_AUC"))

#### normalize
dt_STA_d1234_AUC[,7] = dt_STA_d1234_AUC[,7] / dt_STA_d1234_AUC[,4] 
dt_STA_d1234_AUC[,6] = dt_STA_d1234_AUC[,6] / dt_STA_d1234_AUC[,4] 
dt_STA_d1234_AUC[,5] = dt_STA_d1234_AUC[,5] / dt_STA_d1234_AUC[,4] 
dt_STA_d1234_AUC[,4] = dt_STA_d1234_AUC[,4] / dt_STA_d1234_AUC[,4] 


#### melt
dt_STA_d1234_AUC = melt(dt_STA_d1234_AUC, id.vars = c("Animal", "Side", "Stim_Amplitude"),
            measure.vars = c("1", "2", "3", "4"))
names(dt_STA_d1234_AUC)[names(dt_STA_d1234_AUC) == "variable"] = "Day"
names(dt_STA_d1234_AUC)[names(dt_STA_d1234_AUC) == "value"] = "Normalized_AUC"




#### calculate percent change from day 1 to day 4, dropping Day1_AUC and Day14_AUC columns
dt_STA_d1d4_pchange <- dt_STA_d1d4_pchange[, 
                               .(
                                 Percent_Change_AUC = percent_change(Day1_AUC, Day4_AUC)
                               ),
                               by = .(Animal, Side, Stim_Amplitude)]



#### calculate mean % change and replace the % change column
dt_STA_d1d4_mpchange <- dt_STA_d1d4_pchange[, 
                                           .(
                                             Mean_Percent_Change_AUC = mean(Percent_Change_AUC)
                                           ),
                                           by = .(Animal, Side)]



#### add animal group column (do this at the end to make analysis easier)
dt_STA_d1d4_pchange[Animal %in% injstim, Group := "Injury + Stimulation, n=4"]
dt_STA_d1d4_pchange[Animal %in% injnostim, Group := "Injury + No Stimulation, n=6"]
dt_STA_d1d4_pchange[Animal %in% noinjstim, Group := "No Injury + Stimulation, n=3"]
dt_STA_d1d4_pchange[Animal %in% noinjnostim, Group := "No Injury + No Stimulation, n=6"]
dt_STA_d1d4_pchange[Animal %in% injcdrstim, Group := "Injury + CDR + Stimulation"]
dt_STA_d1d4_pchange[Animal %in% injtrkbstim, Group := "Injury + siTrkB + Stimulation"]
dt_STA_d1d4_pchange[Animal %in% injnoemgnostim, Group := "Injury + No EMG + No Stimulation"]
dt_STA_d1d4_pchange[Animal %in% noinjnoemgnostim, Group := "No Injury + No EMG + No Stimulation"]

dt_STA_d1234_AUC[Animal %in% injstim, Group := "Injury + Stimulation, n=4"]
dt_STA_d1234_AUC[Animal %in% injnostim, Group := "Injury + No Stimulation, n=6"]
dt_STA_d1234_AUC[Animal %in% noinjstim, Group := "No Injury + Stimulation, n=3"]
dt_STA_d1234_AUC[Animal %in% noinjnostim, Group := "No Injury + No Stimulation, n=6"]
dt_STA_d1234_AUC[Animal %in% injcdrstim, Group := "Injury + CDR + Stimulation"]
dt_STA_d1234_AUC[Animal %in% injtrkbstim, Group := "Injury + siTrkB + Stimulation"]
dt_STA_d1234_AUC[Animal %in% injnoemgnostim, Group := "Injury + No EMG + No Stimulation"]
dt_STA_d1234_AUC[Animal %in% noinjnoemgnostim, Group := "No Injury + No EMG + No Stimulation"]


#write.csv(dt_STA_d1d4_pchange, 'C:\\Users\\iangm\\Google Drive\\UF\\Lab\\Data & Figures\\Mw0rgan.csv')







#### plot

## in progress plots
#WHERE IS N11 ?????????
dots <- ggplot(subset(dt_STA_d1d4_pchange, Animal %in% c('N09', 'N10', 'N13')), aes(x=Stim_Amplitude, y=Percent_Change_AUC, color=Animal)) +
  geom_point(alpha=0.7)
dots

Day.labs <- c("Day 1", "Day 2", "Day 3", "Day 4")
names(Day.labs) <- c("1", "2", "3", "4")


  


## final plots
gpcd14 <- ggplot(dt_STA_d1d4_pchange, aes(x=Stim_Amplitude, y=Percent_Change_AUC, color=Group)) +
  geom_smooth(span=0.25) +
  geom_point(alpha=0.4) +
  labs(x="Stimulation Amplitude (µA)", 
       y="Percent Change AUC \n Day 1 to Day 4") +
  xlim(100,500) +
  theme_classic() +
  theme(text = element_text(size=20))
gpcd14


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
# remove samples <50 to get rid of stim artifact
# the number of samples removed should actually be based on sampling frequency
# multiplier for recordings (different gains for different days??)




