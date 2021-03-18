library(lme4)
library(psycho)
library(tidyverse)
library(lmerTest)
library(car)
library(emmeans)
library(multcomp)

df_p2p_scaled <- read.csv(file = 'D:\\df_p2p_scaled.csv')
#rescale all numerical variables to be in same range
#wald x^2 should be acceptable bc in type 3 format
#depending on anova packge you might be type 1 2 3
#point and click software is almost always type 3
#if you dont know what you're doing, use type 3
#type 3 drops terms and compares to models that have everything
#type 1 order matters... added this first, then the next... so you look at sequential differences
#you typically do not want type 1 in biology
#satterthwaite's method... but wald x^2 should work.. it is acceptable.. shouldnt vary too much

#for pairwise do comparison of least squared means
#in lmertools package.. may be newer version


#anything that comes in as a factor, recategorize as a factor... 


df_p2p_scaled <- df_p2p_scaled %>%
  mutate(Day_Stim = as_factor(Day_Stim))


#Data_TactileSensitivity <- Data_TactileSensitivity %>%
#  mutate(Week = as_factor(Week)) %>%
#  mutate(Group = as_factor(Group)) %>%
#  mutate(Rat_ID = as_factor(`Rat ID`)) %>%
#  rename(Left_PWT = `50% WT...7`) %>%
#  rename(Right_PWT = `50% WT...11`)

#factor will be anything that will be treated as a nominal variable rather than number
#animal, group, day(??)




fit <- lmer(p2p_amplitude_scaled ~ Stim_Amplitude*Day_Stim*Group + (1|Animal), data=df_p2p_scaled)
#does each animal need it's own slope...yes
# dont overlook main effects... look at those smaller ones.. main effects can be important.. could be eating up some of pairwise comparisons at specific time points
# interaction can get diluted 

# if drug effected on day 1 and wears off, get significant effects at day 1 but not others
# when drug always effective... timepoints wont show effect because main effect says drug is always effective regardless
# main effect can capture all of it
# pairwise comp of main effect is saying 



summary(fit)
Anova(fit, type='III')


lsmeans(fit, pairwise ~ Stim_Amplitude:Day_Stim:Group, adjust = "tukey", pbkrtest.limit = 4000)



#stimulation has a huge effect
#stim amp interacts with group... different groups have diff relationship w stim
# group changes with day
# stim realtionship response w group also changes w day
#***always read anova tables from top down (esp in paper)
#*main effects down
#* maybe no main effects but yes interactions.. think about what is going on
#* 


## linear fit?
# most likely good given the spread of our data
# look up resid plot
# expect sign on resid to be random on linear fit if it works well
# non random dist on resid indicates bad fit
# look up basic goodness of fit techniques (check if assumptions are ok... resid are pretty scattered, good enough)


#keep group variable as it is... more complexity will make model too difficult to interpret


# emmeans(fit, "Day", pbkrtest.limit = 4000)

# summary(glht(fit, linfct = mcp(Group = "Tukey")), test = adjusted("holm"))


# emmeans(model, list(pairwise ~ Group), adjust = "tukey")


# emtrends(fit, pairwise ~ treatment, var = "dose")



# ls_means(fit, which = "Day_Stim", pairwise = TRUE, adjust = "tukey")

# ls_slopes


# ls_means(Model_TactileSensitity, which = "Group:Week", pairwise = TRUE, adjust = "tukey")

############# Significance betwe

# import libraries
library(tidyverse)
library(ggpubr)
library(rstatix)

#load data
df_avg_p2p <- read.csv(file = 'D:\\df_d1d4_pchange.csv')

# remove unnecessary columns
#keeps <- c("Group", "Day_Stim", "p2p_amplitude_scaled", 'Animal')
#df_avg_p2p <- df_avg_p2p[keeps]

# convert factor variables to factors
df_avg_p2p <- df_avg_p2p %>%
  convert_as_factor(Group,  Animal)

# check summary statistics
df_avg_p2p %>%
  group_by(Group) %>%
  get_summary_stats(d1d4_pchange, type = "mean_sd")

# plot boxplot
ggboxplot(df_avg_p2p, "Group", "d1d4_pchange",
          palette = c("#00AFBB", "#E7B800"))

# check for extreme outliers
df_avg_p2p %>%
  group_by(Group) %>%
  identify_outliers(d1d4_pchange)

# check normality
df_avg_p2p %>%
  group_by(Group) %>%
  shapiro_test(d1d4_pchange) # shapiro wilks

ggqqplot(df_avg_p2p, "d1d4_pchange", ggtheme = theme_bw()) +
  facet_grid(Group, labeller = "label_both") # QQ plot

# computation 2 way rm anova
res.aov <- anova_test(
  data = df_avg_p2p, dv = d1d4_pchange, wid = Animal,
  between=c(Group)
)
get_anova_table(res.aov)




#load data
df_avg_p2p <- read.csv(file = 'D:\\df_d1d4_pchange.csv')

# remove unnecessary columns
#keeps <- c("Group", "Day_Stim", "p2p_amplitude_scaled", 'Animal')
#df_avg_p2p <- df_avg_p2p[keeps]

# convert factor variables to factors
df_avg_p2p <- df_avg_p2p %>%
  convert_as_factor(Group,  Animal)

# computation 2 way rm anova
res.aov <- anova_test(
  data = df_avg_p2p, dv = d1d4_pchange, wid = Animal,
  between=c(Group)
)
get_anova_table(res.aov)
