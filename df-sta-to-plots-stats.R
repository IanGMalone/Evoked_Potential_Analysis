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
library(viridis)  

#### define functions
percent_change <- function(old_val, new_val) {
  #' Return percent change between new and old value
  ((new_val-old_val)/old_val)*100
}

st_er <- function(x) sd(x, na.rm=TRUE)/sqrt(length(x))




#### ---- data wrangling and analysis ---- ####

#### load STA data as dataframe
df <- data.frame(read.csv('C:/Users/iangm/Desktop/df_STA_2020_06_14_clean.csv'))
df[,'Animal'] = toupper(df[,'Animal'])
dt_STA = data.table(df)

#### make data table for day 1, 2, 3, 4
#### remove stim artifact (samples 0:50) <---- maybe remove less than 50 (50 samples = 2.5ms)
#### only keep left side EMG in data table
dt_STA = subset(dt_STA, Day %in% c(1, 2, 3, 4) & Sample %in% c(50:300) & Side %in% c('Left'))

#### calculate AUC, dropping the Sample and STA_Amplitude columns
dt_STA = dt_STA[, .(AUC = trapz(Sample, STA_Amplitude)), by = .(Animal, Day, Side, Stim_Amplitude)]

#### break Day column into columns for day 1 AUC and day 4 AUC
dt_STA = dcast(dt_STA, Animal + Side + Stim_Amplitude ~ Day, value.var = "AUC")

#### new dt made to use 100 uA as baseline (continued below after dt_STA_day1_baseline processing)
keeps <- c(100,200,300,370,400,500)
dt_STA_100_baseline = subset(dt_STA, Stim_Amplitude %in% keeps)

#### new dt made to use day 1 as baseline
dt_STA_day1_baseline = dt_STA

#### rename columns
names(dt_STA_day1_baseline)[names(dt_STA_day1_baseline) == "1"] = "AUC_1"
names(dt_STA_day1_baseline)[names(dt_STA_day1_baseline) == "2"] = "AUC_2"
names(dt_STA_day1_baseline)[names(dt_STA_day1_baseline) == "3"] = "AUC_3"
names(dt_STA_day1_baseline)[names(dt_STA_day1_baseline) == "4"] = "AUC_4"

#### calculate percent change from day 1 for each day, make new columns
dt_STA_day1_baseline[, PercentChange_1 := percent_change(AUC_1, AUC_1)]
dt_STA_day1_baseline[, PercentChange_2 := percent_change(AUC_1, AUC_2)]
dt_STA_day1_baseline[, PercentChange_3 := percent_change(AUC_1, AUC_3)]
dt_STA_day1_baseline[, PercentChange_4 := percent_change(AUC_1, AUC_4)]

#### define animal groups
injstim = c("N09", "N10", "N11", "N13")
injnostim = c("N14", "N15", "N16", "N21", "N22", "N23")
noinjstim = c("N01", "N04", "N05")
noinjnostim = c("N17", "N19", "N20", "N24", "N25", "N26")
# injcdrstim = c("CD01", "CD02")
# injtrkbstim = c("T01")
# injnoemgnostim = c("EZ01", "EZ02")
# noinjnoemgnostim = c("EZ03", "EZ04")

#### add animal group column
dt_STA_day1_baseline[Animal %in% injstim, Group := "Injury + Stimulation, n=4"]
dt_STA_day1_baseline[Animal %in% injnostim, Group := "Injury + No Stimulation, n=6"]
dt_STA_day1_baseline[Animal %in% noinjstim, Group := "No Injury + Stimulation, n=3"]
dt_STA_day1_baseline[Animal %in% noinjnostim, Group := "No Injury + No Stimulation, n=6"]
# dt_STA[Animal %in% injcdrstim, Group := "Injury + CDR + Stimulation"]
# dt_STA[Animal %in% injtrkbstim, Group := "Injury + siTrkB + Stimulation"]
# dt_STA[Animal %in% injnoemgnostim, Group := "Injury + No EMG + No Stimulation"]
# dt_STA[Animal %in% noinjnoemgnostim, Group := "No Injury + No EMG + No Stimulation"]

#### melt
dt_STA_day1_baseline = melt(dt_STA_day1_baseline, id = c("Animal", "Side", "Stim_Amplitude", "Group"))
dt_STA_day1_baseline[, c("Measure", "Day") := tstrsplit(variable, "_", fixed = TRUE)]
dt_STA_day1_baseline[,variable:=NULL]
dt_STA_day1_baseline = dcast(dt_STA_day1_baseline, Animal + Side + Stim_Amplitude + Group + Day ~ Measure, value.var = "value")
setnames(dt_STA_day1_baseline, "PercentChange", "Percent_Change")
setcolorder(dt_STA_day1_baseline, c("Animal", "Side", "Stim_Amplitude", "Day", "AUC", "Percent_Change", "Group"))

#### save dt to a .csv
#write.csv(dt_STA, 'C:\\Users\\iangm\\desktop\\dt_STA.csv')

#### continue with processing other dt for 100 uA baseline
dt_STA_100_baseline = melt(dt_STA_100_baseline, id = c("Animal", "Side", "Stim_Amplitude"))
dt_STA_100_baseline = dcast(dt_STA_100_baseline, Animal + Side + variable ~ Stim_Amplitude, value.var = "value")

#### rename columns
setnames(dt_STA_100_baseline, as.character(keeps), paste0('s', keeps))
setnames(dt_STA_100_baseline, c('variable'), c('Day'))

#### calculate percent change from 100 uA to other stim amps
dt_STA_100_baseline[, pc100 := percent_change(s100, s100)]
dt_STA_100_baseline[, pc200 := percent_change(s100, s200)]
dt_STA_100_baseline[, pc300 := percent_change(s100, s300)]
dt_STA_100_baseline[, pc370 := percent_change(s100, s370)]
dt_STA_100_baseline[, pc400 := percent_change(s100, s400)]
dt_STA_100_baseline[, pc500 := percent_change(s100, s500)]

#### drop old columns
dt_STA_100_baseline[, paste0('s', keeps):=NULL]  # remove two columns

#### add animal group column
dt_STA_100_baseline[Animal %in% injstim, Group := "Injury + Stimulation, n=4"]
dt_STA_100_baseline[Animal %in% injnostim, Group := "Injury + No Stimulation, n=6"]
dt_STA_100_baseline[Animal %in% noinjstim, Group := "No Injury + Stimulation, n=3"]
dt_STA_100_baseline[Animal %in% noinjnostim, Group := "No Injury + No Stimulation, n=6"]

####  dt for mean and se for stim amp of interest
dt_mean_se = dt_STA_100_baseline[, 
                .(
                  pc400_mean = mean(pc400, na.rm=TRUE),
                  pc400_se = st_er(pc400)
                ),
                by = .(Day, Group)]

dt_points = dt_STA_100_baseline[, c('pc100','pc200','pc300','pc370','pc500'):=NULL]




#### ---- plotting ----#### ---- 
ordered = c("Injury + Stimulation, n=4",
            "Injury + No Stimulation, n=6",
            "No Injury + Stimulation, n=3",
            "No Injury + No Stimulation, n=6")
colors = c('#9A1F3F','#D9455F','#45D9BE','#1F9878' )


#### % change 100 to 400 vs. groups by day
bar_and_points <- ggplot(dt_mean_se, aes(x=factor(Group, levels=ordered), y=pc400_mean, fill=Day)) + 
  geom_bar(position=position_dodge(), stat="identity", colour='black') +
  geom_errorbar(aes(ymin=pc400_mean-pc400_se, ymax=pc400_mean+pc400_se), width=.2,position=position_dodge(.9)) +
  geom_point(data=dt_points, aes(x=factor(Group, levels=ordered), y=pc400, Fill=Day), 
             position = position_jitterdodge(jitter.width = 0.1, dodge.width = 0.9,), 
             shape=21, alpha=0.5) +
  labs(x="Group", 
       y="Percent Change AUC (100 µA to 400 µA)") +
  theme_classic() +
  theme(text = element_text(size=17)) +
  scale_fill_manual(values = colors) +
  theme(legend.position=c(0.05,0.91)) +
  scale_y_continuous(expand=c(0.01,0), trans='log10')
bar_and_points


#### % change d1 to d4 vs. stim amp by group
smooth_and_points <- ggplot(subset(dt_STA_day1_baseline, Day %in% c(4)), 
                            aes(x=Stim_Amplitude, y=Percent_Change, 
                                color=factor(Group, levels=ordered))) +
  geom_smooth(span=0.25, size=1.5) +
  geom_point(alpha=0.5) +
  labs(x="Stimulation Amplitude (µA)", 
       y="Percent Change AUC \n Day 1 to Day 4") +
  xlim(100,500) +
  theme_classic() +
  theme(text = element_text(size=17)) +
  scale_color_manual(values = colors) +
  theme(legend.position=c(0.18,0.9), legend.title.align = 0.3) +
  labs(color = "Group")
smooth_and_points



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




